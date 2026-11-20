import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:compro_builder/core/utils/format.dart';
import 'package:compro_builder/data/datasources/plan_remote_datasource.dart';
import 'package:compro_builder/data/model/response/plan_info_model.dart';
import 'package:compro_builder/presentation/bloc/plan/plan_bloc.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/pages/billing/billing_page.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Paket aktif satu situs. Tombol Upgrade/Perpanjang membuka layar Billing
/// (bayar di aplikasi); setelah kembali, paket dan daftar situs dimuat ulang.
class PlanPage extends StatelessWidget {
  final String slug;
  const PlanPage({super.key, required this.slug});

  static Future<void> open(BuildContext context, {required String slug}) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => PlanPage(slug: slug)));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PlanBloc(PlanRemoteDatasource(), slug: slug)
            ..add(const PlanEvent.load()),
      child: const _PlanView(),
    );
  }
}

class _PlanView extends StatelessWidget {
  const _PlanView();

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  /// Buka layar Billing lalu muat ulang paket ini dan daftar situs (paket dan
  /// masa berlaku berubah bila pembayaran lunas).
  Future<void> _upgrade(BuildContext context) async {
    final plan = context.read<PlanBloc>();
    final sites = context.read<SitesBloc>();
    await BillingPage.open(context, slug: plan.slug);
    if (!plan.isClosed) plan.add(const PlanEvent.refresh());
    if (!sites.isClosed) sites.add(const SitesEvent.refresh());
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<PlanBloc>();
    final next = bloc.stream.first;
    bloc.add(const PlanEvent.refresh());
    await next.timeout(
      const Duration(seconds: 30),
      onTimeout: () => bloc.state,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<PlanBloc, PlanState>(
      listenWhen: (_, current) =>
          current.whenOrNull(
            loaded: (d) => d.refreshFailure != null || d.refreshed,
          ) ??
          false,
      listener: (context, state) {
        final data = state.whenOrNull(loaded: (d) => d);
        if (data == null) return;
        if (data.refreshFailure != null) {
          _snack(data.refreshFailure!.message, kind: ToastKind.error);
        } else if (data.refreshed) {
          _snack(l.planRefreshed, kind: ToastKind.success);
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(l.planTitle)),
        body: state.when(
          initial: () => const LoadingView(),
          loading: () => const LoadingView(),
          error: (failure) => ErrorView(
            message: failure.message,
            onRetry: () => context.read<PlanBloc>().add(const PlanEvent.load()),
          ),
          loaded: (data) => RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _CurrentCard(plan: data.plan),
                const SizedBox(height: 16),
                _LimitsCard(limits: data.plan.limitRows),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _upgrade(context),
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: Text(l.planUpgrade),
                ),
                const SizedBox(height: 8),
                Text(
                  l.planUpgradeHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentCard extends StatelessWidget {
  final PlanInfoModel plan;
  const _CurrentCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final days = plan.daysLeft(DateTime.now());
    final expires = plan.expiresAt;
    final validity = expires == null
        ? l.planNoExpiry
        : [
            l.planExpiresOn(formatDateId(expires)),
            if (days != null)
              days < 0
                  ? l.planExpired
                  : days == 0
                  ? l.planExpiresToday
                  : l.planDaysLeft(days),
          ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusTile),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.planCurrent, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              plan.name,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (plan.priceLabel != null) ...[
              const SizedBox(height: 12),
              _KV(label: l.planPrice, value: plan.priceLabel!),
            ],
            const SizedBox(height: 8),
            _KV(
              label: l.planValidity,
              value: validity,
              emphasize: days != null && days < 0,
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitsCard extends StatelessWidget {
  final List<PlanLimit> limits;
  const _LimitsCard({required this.limits});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final divider = Theme.of(context).colorScheme.outlineVariant;
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l.planLimits,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (limits.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(l.planLimitsEmpty),
            )
          else
            for (var i = 0; i < limits.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : Border(top: BorderSide(color: divider)),
                ),
                child: _KV(
                  label: limits[i].label,
                  value: limits[i].value ?? l.limitUnlimited,
                ),
              ),
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  const _KV({required this.label, required this.value, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: Text(label)),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: emphasize ? scheme.error : null,
            ),
          ),
        ),
      ],
    );
  }
}
