import 'package:compro_builder/presentation/widgets/gradient_card.dart';
import 'package:compro_builder/core/helper/link_opener.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/utils/format.dart';
import 'package:compro_builder/core/utils/url.dart';
import 'package:compro_builder/data/datasources/billing_remote_datasource.dart';
import 'package:compro_builder/data/model/response/billing_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/presentation/bloc/billing/billing_bloc.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/pages/billing/billing_history_page.dart';
import 'package:compro_builder/presentation/pages/billing/billing_pay_page.dart';
import 'package:compro_builder/presentation/widgets/resend_verification_button.dart';
import 'package:compro_builder/presentation/widgets/site_card.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Daftar paket + harga, order yang menunggu bayar, dan pembuatan order.
/// Pembayaran dilanjutkan di [BillingPayPage]; riwayat di [BillingHistoryPage].
/// Bila server tidak menyediakan pembayaran di aplikasi (`in_app_payment`
/// false), pembayaran memakai tautan web order lalu data dimuat ulang saat
/// pengguna kembali ke aplikasi.
class BillingPage extends StatelessWidget {
  final String slug;
  const BillingPage({super.key, required this.slug});

  static Future<void> open(BuildContext context, {required String slug}) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BillingPage(slug: slug)),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BillingBloc(BillingRemoteDatasource(), slug: slug)
            ..add(const BillingEvent.load()),
      child: _BillingView(slug: slug),
    );
  }
}

class _BillingView extends StatefulWidget {
  final String slug;
  const _BillingView({required this.slug});

  @override
  State<_BillingView> createState() => _BillingViewState();
}

class _BillingViewState extends State<_BillingView>
    with WidgetsBindingObserver {
  /// Lama langganan yang dipilih; null = periode pertama dari server.
  int? _months;
  bool _awaitingReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Kembali dari browser (tagihan web) -> muat ulang paket dan data situs.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final bloc = context.read<BillingBloc>();
    // Pengguna mungkin baru memverifikasi email lewat aplikasi surel/web:
    // muat ulang supaya banner "email belum diverifikasi" hilang sendiri.
    final emailPending =
        bloc.state.whenOrNull(loaded: (d) => !d.overview.emailVerified) ??
            false;
    if (_awaitingReturn) {
      _awaitingReturn = false;
      bloc.add(const BillingEvent.refresh());
      context.read<SitesBloc>().add(const SitesEvent.refresh());
    } else if (emailPending) {
      bloc.add(const BillingEvent.refresh());
    }
  }

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<BillingBloc>();
    final next = bloc.stream.first;
    bloc.add(const BillingEvent.refresh());
    await next.timeout(
      const Duration(seconds: 30),
      onTimeout: () => bloc.state,
    );
  }

  /// Buka layar bayar untuk [order], lalu muat ulang paket dan situs: paket
  /// bisa berubah karena pembayaran lunas.
  Future<void> _openPay(
    BuildContext context,
    BillingOrderModel order,
    BillingOverviewModel overview,
  ) async {
    final bloc = context.read<BillingBloc>();
    final sites = context.read<SitesBloc>();
    await BillingPayPage.open(
      context,
      slug: widget.slug,
      order: order,
      methods: overview.methods,
      inAppPayment: overview.inAppPayment,
    );
    if (!bloc.isClosed) bloc.add(const BillingEvent.refresh());
    if (!sites.isClosed) sites.add(const SitesEvent.refresh());
  }

  Future<void> _openHistory(
    BuildContext context,
    BillingOverviewModel overview,
  ) async {
    final bloc = context.read<BillingBloc>();
    final sites = context.read<SitesBloc>();
    await BillingHistoryPage.open(
      context,
      slug: widget.slug,
      methods: overview.methods,
      inAppPayment: overview.inAppPayment,
    );
    if (!bloc.isClosed) bloc.add(const BillingEvent.refresh());
    if (!sites.isClosed) sites.add(const SitesEvent.refresh());
  }

  Future<void> _openWeb(String rawUrl) async {
    final l = context.l10n;
    final uri = Uri.tryParse(resolveUrl(rawUrl));
    // Hanya http/https: tautan dari server tidak boleh membuka skema lain.
    final ok = uri != null && await openExternalLink(uri);
    if (!mounted) return;
    if (ok) {
      _awaitingReturn = true;
    } else {
      _snack(l.cannotOpenLink, kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<BillingBloc, BillingState>(
      listenWhen: (_, current) =>
          current.whenOrNull(
            loaded: (d) =>
                d.createdOrder != null ||
                d.checkoutFailure != null ||
                d.refreshFailure != null,
          ) ??
          false,
      listener: (context, state) {
        final data = state.whenOrNull(loaded: (d) => d);
        if (data == null) return;
        final order = data.createdOrder;
        if (order != null) {
          _openPay(context, order, data.overview);
          return;
        }
        final failure = data.checkoutFailure ?? data.refreshFailure;
        if (failure != null) _snack(failure.message, kind: ToastKind.error);
      },
      builder: (context, state) {
        final overview = state.whenOrNull(loaded: (d) => d.overview);
        return Scaffold(
          appBar: AppBar(
            title: Text(l.billingTitle),
            actions: [
              if (overview != null)
                IconButton(
                  tooltip: l.billingHistoryTitle,
                  icon: const Icon(Icons.history),
                  onPressed: () => _openHistory(context, overview),
                ),
            ],
          ),
          body: state.when(
            initial: () => const LoadingView(),
            loading: () => const LoadingView(),
            error: (failure) => ErrorView(
              message: failure.message,
              onRetry: () =>
                  context.read<BillingBloc>().add(const BillingEvent.load()),
            ),
            loaded: (data) => RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: _content(context, data),
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, BillingViewData data) {
    final l = context.l10n;
    final overview = data.overview;
    final periods = overview.periods;
    final months = periods.any((p) => p.months == _months)
        ? _months!
        : (periods.isEmpty ? 1 : periods.first.months);
    final periodLabel = periods
        .where((p) => p.months == months)
        .map((p) => p.label)
        .firstOrNull;
    final canBuy = overview.emailVerified && !data.isCheckingOut;
    final pending = overview.pendingOrder;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _CurrentPlanCard(plan: overview.current),
        const SizedBox(height: 12),
        if (!overview.emailVerified) ...[
          _NoticeCard(
            icon: Icons.mark_email_unread_outlined,
            title: l.billingEmailUnverifiedTitle,
            message: l.billingEmailUnverifiedMessage,
            extra: ResendVerificationButton(
              onVerified: () =>
                  context.read<BillingBloc>().add(const BillingEvent.refresh()),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (pending != null && pending.isPayable) ...[
          _NoticeCard(
            icon: Icons.hourglass_bottom,
            title: l.billingPendingTitle,
            message: l.billingPendingMessage(
              pending.planName,
              formatRupiah(pending.amount),
            ),
            actionLabel: l.billingContinuePay,
            onAction: () => _openPay(context, pending, overview),
          ),
          const SizedBox(height: 12),
        ],
        if (periods.length > 1) ...[
          Semantics(
            header: true,
            child: Text(
              l.billingPeriod,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [
              for (final p in periods)
                ButtonSegment<int>(value: p.months, label: Text(p.label)),
            ],
            selected: {months},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _months = s.first),
          ),
          const SizedBox(height: 16),
        ],
        Semantics(
          header: true,
          child: Text(
            l.billingPlansTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        if (overview.plans.isEmpty)
          Text(l.billingNoPlans)
        else
          for (final plan in overview.plans)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanCard(
                plan: plan,
                months: months,
                periodLabel: periodLabel,
                busy: data.isCheckingOut,
                enabled: canBuy,
                onChoose: () => context.read<BillingBloc>().add(
                  BillingEvent.checkout(plan: plan.code, months: months),
                ),
              ),
            ),
        if (data.isCheckingOut)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(l.billingCreating),
              ],
            ),
          ),
        if (overview.webBillingUrl != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _openWeb(overview.webBillingUrl!),
            icon: const Icon(Icons.open_in_new),
            label: Text(l.billingOpenWeb),
          ),
        ],
      ],
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  final PlanSummaryModel plan;
  const _CurrentPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final expires = plan.expiresAt?.toLocal();
    final days = plan.daysLeft();
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
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.planCurrent,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plan.name.isEmpty ? '-' : plan.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            validity,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: days != null && days < 0
                  ? const Color(0xFFFFB4A9)
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Widget tambahan di bawah pesan (mis. tombol kirim ulang verifikasi).
  final Widget? extra;

  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      child: Card(
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(color: scheme.onSecondaryContainer),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(96, 48),
                        ),
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ],
                    if (extra != null) ...[
                      const SizedBox(height: 8),
                      extra!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final BillingPlanModel plan;
  final int months;
  final String? periodLabel;
  final bool busy;
  final bool enabled;
  final VoidCallback onChoose;

  const _PlanCard({
    required this.plan,
    required this.months,
    required this.periodLabel,
    required this.busy,
    required this.enabled,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final amount = plan.amountFor(months);
    final priceText = plan.price <= 0
        ? l.billingFree
        : formatRupiah(amount ?? plan.price);
    final rows = plan.limitRows;

    return Card(
      shape: plan.current
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(plan.name, style: theme.textTheme.titleLarge),
                ),
                if (plan.current)
                  SiteChip(
                    icon: Icons.check_circle_outline,
                    label: l.billingCurrentBadge,
                    color: theme.colorScheme.primaryContainer,
                    onColor: theme.colorScheme.onPrimaryContainer,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              priceText,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (plan.price > 0 && amount != null && periodLabel != null)
              Text(
                l.billingForPeriod(periodLabel!),
                style: theme.textTheme.bodySmall,
              ),
            if (rows.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(l.planLimits),
                children: [
                  for (final r in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(r.label)),
                          Text(
                            r.value ?? l.limitUnlimited,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            if (plan.buyable) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
                  onPressed: enabled && !busy ? onChoose : null,
                  child: Text(plan.current ? l.billingRenew : l.billingBuy),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
