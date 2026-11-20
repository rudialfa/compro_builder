import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/utils/format.dart';
import 'package:compro_builder/data/datasources/billing_remote_datasource.dart';
import 'package:compro_builder/data/model/response/billing_response_model.dart';
import 'package:compro_builder/presentation/bloc/billing_history/billing_history_bloc.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/pages/billing/billing_labels.dart';
import 'package:compro_builder/presentation/pages/billing/billing_pay_page.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Riwayat order (terbaru dulu). Order yang masih bisa dibayar bisa dilanjutkan.
class BillingHistoryPage extends StatelessWidget {
  final String slug;
  final List<BillingMethodModel> methods;
  final bool inAppPayment;

  const BillingHistoryPage({
    super.key,
    required this.slug,
    required this.methods,
    required this.inAppPayment,
  });

  static Future<void> open(
    BuildContext context, {
    required String slug,
    required List<BillingMethodModel> methods,
    required bool inAppPayment,
  }) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BillingHistoryPage(
        slug: slug,
        methods: methods,
        inAppPayment: inAppPayment,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BillingHistoryBloc(BillingRemoteDatasource(), slug: slug)
            ..add(const BillingHistoryEvent.load()),
      child: _HistoryView(
        slug: slug,
        methods: methods,
        inAppPayment: inAppPayment,
      ),
    );
  }
}

class _HistoryView extends StatelessWidget {
  final String slug;
  final List<BillingMethodModel> methods;
  final bool inAppPayment;

  const _HistoryView({
    required this.slug,
    required this.methods,
    required this.inAppPayment,
  });

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<BillingHistoryBloc>();
    final next = bloc.stream.first;
    bloc.add(const BillingHistoryEvent.refresh());
    await next.timeout(
      const Duration(seconds: 30),
      onTimeout: () => bloc.state,
    );
  }

  /// Lanjutkan order yang belum lunas, lalu muat ulang riwayat dan situs
  /// (order bisa lunas selama layar bayar terbuka).
  Future<void> _openOrder(BuildContext context, BillingOrderModel order) async {
    final bloc = context.read<BillingHistoryBloc>();
    final sites = context.read<SitesBloc>();
    await BillingPayPage.open(
      context,
      slug: slug,
      order: order,
      methods: methods,
      inAppPayment: inAppPayment,
    );
    if (!bloc.isClosed) bloc.add(const BillingHistoryEvent.refresh());
    if (!sites.isClosed) sites.add(const SitesEvent.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<BillingHistoryBloc, BillingHistoryState>(
      listenWhen: (_, current) =>
          current.whenOrNull(loaded: (d) => d.refreshFailure != null) ?? false,
      listener: (context, state) {
        final failure = state.whenOrNull(loaded: (d) => d.refreshFailure);
        if (failure != null) _snack(failure.message, kind: ToastKind.error);
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(l.billingHistoryTitle)),
        body: state.when(
          initial: () => const LoadingView(),
          loading: () => const LoadingView(),
          error: (failure) => ErrorView(
            message: failure.message,
            onRetry: () => context.read<BillingHistoryBloc>().add(
              const BillingHistoryEvent.load(),
            ),
          ),
          loaded: (data) => RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: data.orders.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 360,
                        child: EmptyView(
                          icon: Icons.receipt_long_outlined,
                          title: l.billingHistoryEmpty,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: data.orders.length + (data.hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= data.orders.length) {
                        return _LoadMoreFooter(data: data);
                      }
                      final order = data.orders[i];
                      return _OrderTile(
                        order: order,
                        onTap: order.isPayable
                            ? () => _openOrder(context, order)
                            : null,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final BillingOrderModel order;
  final VoidCallback? onTap;

  const _OrderTile({required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final paid = order.isPaid;
    final created = order.createdAt;
    return ListTile(
      isThreeLine: true,
      title: Text(l.billingPlanMonths(order.planName, order.months)),
      subtitle: Text(
        [
          order.number,
          if (created != null) formatDateTimeId(created),
          if (onTap != null) l.billingContinuePay,
        ].join('\n'),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatRupiah(order.amount),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            billingStatusLabel(l, order.status),
            style: TextStyle(
              color: paid ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: paid ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  final BillingHistoryData data;
  const _LoadMoreFooter({required this.data});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (data.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (data.loadMoreFailure != null) ...[
            Text(data.loadMoreFailure!.message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(96, 48)),
            onPressed: () => context.read<BillingHistoryBloc>().add(
              const BillingHistoryEvent.loadMore(),
            ),
            child: Text(l.billingLoadMore),
          ),
        ],
      ),
    );
  }
}
