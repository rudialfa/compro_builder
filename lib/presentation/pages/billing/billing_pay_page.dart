import 'package:compro_builder/presentation/widgets/gradient_card.dart';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:compro_builder/core/helper/link_opener.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/utils/format.dart';
import 'package:compro_builder/core/utils/url.dart';
import 'package:compro_builder/data/datasources/billing_remote_datasource.dart';
import 'package:compro_builder/data/model/response/billing_response_model.dart';
import 'package:compro_builder/presentation/bloc/billing_pay/billing_pay_bloc.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/pages/billing/billing_labels.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Pembayaran satu order: pilih metode, tampilkan nomor VA / kode bayar / QRIS
/// dengan hitung mundur, lalu pantau status sampai lunas. Hasil lunas diteruskan
/// ke [SitesBloc] (paket + masa berlaku). Bila server tidak menyediakan
/// pembayaran di aplikasi, tombol membuka tautan web order dan status diperiksa
/// saat pengguna kembali.
class BillingPayPage extends StatelessWidget {
  final String slug;
  final BillingOrderModel order;
  final List<BillingMethodModel> methods;
  final bool inAppPayment;

  const BillingPayPage({
    super.key,
    required this.slug,
    required this.order,
    required this.methods,
    required this.inAppPayment,
  });

  static Future<void> open(
    BuildContext context, {
    required String slug,
    required BillingOrderModel order,
    required List<BillingMethodModel> methods,
    required bool inAppPayment,
  }) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BillingPayPage(
        slug: slug,
        order: order,
        methods: methods,
        inAppPayment: inAppPayment,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BillingPayBloc(
        BillingRemoteDatasource(),
        slug: slug,
        order: order,
      ),
      child: _PayView(
        slug: slug,
        methods: methods,
        inAppPayment: inAppPayment,
      ),
    );
  }
}

class _PayView extends StatefulWidget {
  final String slug;
  final List<BillingMethodModel> methods;
  final bool inAppPayment;

  const _PayView({
    required this.slug,
    required this.methods,
    required this.inAppPayment,
  });

  @override
  State<_PayView> createState() => _PayViewState();
}

class _PayViewState extends State<_PayView> with WidgetsBindingObserver {
  /// Server membatasi pengecekan ke gateway sekali per 8 detik per order.
  static const _pollEvery = Duration(seconds: 8);

  Timer? _pollTimer;
  Timer? _clock;
  DateTime _now = DateTime.now();

  /// Pengguna menekan "Ganti metode" saat nomor bayar sedang tampil.
  bool _pickingMethod = false;

  /// Tautan web sudah dibuka: pantau status juga saat order masih `choose`.
  bool _awaitingWeb = false;

  /// Batas waktu yang sudah memicu satu pengecekan (supaya tidak berulang).
  DateTime? _expiryPolledFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(_pollEvery, (_) => _pollIfWaiting());
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Kembali dari aplikasi bank / browser -> cek status segera.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<BillingPayBloc>().add(const BillingPayEvent.poll());
    }
  }

  BillingPayData get _data =>
      context.read<BillingPayBloc>().state.when(ready: (d) => d);

  void _pollIfWaiting() {
    if (!mounted) return;
    final order = _data.order;
    final waiting =
        order.step == BillingOrderStep.instructions ||
        (order.step == BillingOrderStep.choose && _awaitingWeb);
    if (waiting) {
      context.read<BillingPayBloc>().add(const BillingPayEvent.poll());
    }
  }

  void _tick() {
    if (!mounted) return;
    final order = _data.order;
    final expires = order.expiresAt;
    if (order.step != BillingOrderStep.instructions || expires == null) return;
    setState(() => _now = DateTime.now());
    if (!_now.isBefore(expires) && _expiryPolledFor != expires) {
      _expiryPolledFor = expires;
      context.read<BillingPayBloc>().add(const BillingPayEvent.poll());
    }
  }

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  void _choose(String code) {
    setState(() => _pickingMethod = false);
    context.read<BillingPayBloc>().add(BillingPayEvent.charge(code));
  }

  Future<void> _openWeb(String? rawUrl) async {
    final l = context.l10n;
    final uri = rawUrl == null ? null : Uri.tryParse(resolveUrl(rawUrl));
    // Hanya http/https: tautan dari server tidak boleh membuka skema lain.
    final ok = uri != null && await openExternalLink(uri);
    if (!mounted) return;
    if (ok) {
      _awaitingWeb = true;
    } else {
      _snack(l.cannotOpenLink, kind: ToastKind.error);
    }
  }

  Future<void> _copy(String value) async {
    final l = context.l10n;
    await Clipboard.setData(ClipboardData(text: value));
    _snack(l.billingCopied, kind: ToastKind.success);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<BillingPayBloc, BillingPayState>(
      listenWhen: (_, current) {
        final d = current.when(ready: (d) => d);
        return d.chargeFailure != null || d.paidNow;
      },
      listener: (context, state) {
        final d = state.when(ready: (d) => d);
        if (d.paidNow) {
          final sites = context.read<SitesBloc>();
          final tenant = d.paidTenant;
          // Ringkasan situs terbaru (paket + masa berlaku) dari server; bila
          // tidak ada, muat ulang daftar situs.
          sites.add(
            tenant != null
                ? SitesEvent.tenantUpdated(tenant)
                : const SitesEvent.refresh(),
          );
          _snack(l.billingPaidSnack, kind: ToastKind.success);
          return;
        }
        final failure = d.chargeFailure;
        if (failure != null) _snack(failure.message, kind: ToastKind.error);
      },
      builder: (context, state) {
        final data = state.when(ready: (d) => d);
        return Scaffold(
          appBar: AppBar(title: Text(l.billingPayTitle)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _OrderSummary(order: data.order),
              const SizedBox(height: 16),
              ..._body(context, data),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _body(BuildContext context, BillingPayData data) {
    final order = data.order;
    return switch (order.step) {
      BillingOrderStep.paid => [
        _PaidCard(slug: widget.slug, order: order),
      ],
      BillingOrderStep.instructions =>
        _pickingMethod
            ? _chooseBody(context, data)
            : _instructionsBody(context, data),
      BillingOrderStep.choose => _chooseBody(context, data),
      BillingOrderStep.closed || BillingOrderStep.unknown => [
        _ClosedCard(order: order),
      ],
    };
  }

  // ─── Pilih metode (atau bayar lewat web) ──────────────────────────────────
  List<Widget> _chooseBody(BuildContext context, BillingPayData data) {
    final l = context.l10n;
    final order = data.order;
    final inApp = widget.inAppPayment && widget.methods.isNotEmpty;

    return [
      if (order.timedOut) ...[
        Card(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: ListTile(
            leading: Icon(
              Icons.timer_off_outlined,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
            title: Text(
              l.billingTimedOut,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (inApp) ...[
        Semantics(
          header: true,
          child: Text(
            l.billingChooseMethod,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        if (data.isCharging) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
        ],
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < widget.methods.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  enabled: !data.isCharging,
                  leading: Icon(
                    widget.methods[i].group == 'qris'
                        ? Icons.qr_code_2
                        : Icons.account_balance_outlined,
                  ),
                  title: Text(widget.methods[i].label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _choose(widget.methods[i].code),
                ),
              ],
            ],
          ),
        ),
        if (_pickingMethod)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _pickingMethod = false),
              child: Text(l.actionCancel),
            ),
          ),
        if (order.webPayUrl != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openWeb(order.webPayUrl),
              icon: const Icon(Icons.open_in_new),
              label: Text(l.billingPayWeb),
            ),
          ),
      ] else
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.webPayUrl == null ? l.billingWebUnavailable : l.billingWebHint),
                if (order.webPayUrl != null) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(96, 48),
                    ),
                    onPressed: () => _openWeb(order.webPayUrl),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l.billingPayWeb),
                  ),
                ],
              ],
            ),
          ),
        ),
    ];
  }

  // ─── Nomor bayar + hitung mundur ──────────────────────────────────────────
  List<Widget> _instructionsBody(BuildContext context, BillingPayData data) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final order = data.order;
    final details = order.details;
    final expires = order.expiresAt;

    return [
      Semantics(
        header: true,
        child: Text(
          l.billingInstructionsTitle,
          style: theme.textTheme.titleMedium,
        ),
      ),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order.methodLabel != null)
                Text(
                  order.methodLabel!,
                  style: theme.textTheme.titleMedium,
                ),
              const SizedBox(height: 12),
              ..._detailRows(context, details),
              if (expires != null) ...[
                const Divider(height: 24),
                Text(l.billingPayBefore(formatDateTimeId(expires))),
                const SizedBox(height: 4),
                Text(
                  l.billingTimeLeft(formatCountdown(expires.difference(_now))),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(l.billingWaiting)),
        ],
      ),
      const SizedBox(height: 16),
      FilledButton.tonal(
        style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
        onPressed: () =>
            context.read<BillingPayBloc>().add(const BillingPayEvent.poll()),
        child: Text(l.billingCheckStatus),
      ),
      if (widget.inAppPayment && widget.methods.isNotEmpty)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _pickingMethod = true),
            child: Text(l.billingChangeMethod),
          ),
        ),
    ];
  }

  List<Widget> _detailRows(BuildContext context, BillingPayDetails? d) {
    final l = context.l10n;
    if (d == null) return [Text(l.billingDetailsMissing)];
    switch (d.type) {
      case BillingDetailsType.va:
        return [
          if (d.bank != null) _InfoRow(label: l.billingVaBank, value: d.bank!),
          if (d.number != null)
            _CopyRow(
              label: l.billingVaNumber,
              value: d.number!,
              copyLabel: l.billingCopy,
              onCopy: _copy,
            ),
        ];
      case BillingDetailsType.bill:
        return [
          if (d.billerCode != null)
            _CopyRow(
              label: l.billingBillerCode,
              value: d.billerCode!,
              copyLabel: l.billingCopy,
              onCopy: _copy,
            ),
          if (d.billKey != null)
            _CopyRow(
              label: l.billingBillKey,
              value: d.billKey!,
              copyLabel: l.billingCopy,
              onCopy: _copy,
            ),
        ];
      case BillingDetailsType.qris:
        return [_QrBlock(details: d)];
      case BillingDetailsType.unknown:
        return [Text(l.billingDetailsMissing)];
    }
  }
}

// ─── Potongan tampilan ───────────────────────────────────────────────────────

class _OrderSummary extends StatelessWidget {
  final BillingOrderModel order;
  const _OrderSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.billingPlanMonths(order.planName, order.months),
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(order.amount),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.billingOrderNumber(order.number),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String value;
  final String copyLabel;
  final Future<void> Function(String value) onCopy;

  const _CopyRow({
    required this.label,
    required this.value,
    required this.copyLabel,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                SelectableText(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: copyLabel,
            icon: const Icon(Icons.copy),
            onPressed: () => onCopy(value),
          ),
        ],
      ),
    );
  }
}

/// QRIS: `qr_string` digambar sebagai QR di aplikasi (kontrak API). `qr_url`
/// (gambar dari gateway) hanya cadangan bila `qr_string` tidak ada.
class _QrBlock extends StatelessWidget {
  final BillingPayDetails details;
  const _QrBlock({required this.details});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final qr = details.qrString;
    final url = details.qrUrl;
    Widget image;
    if (qr != null) {
      image = QrImageView(
        data: qr,
        size: 220,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.all(8),
      );
    } else if (url != null) {
      image = CachedNetworkImage(
        imageUrl: url,
        width: 220,
        height: 220,
        placeholder: (_, _) => const SizedBox(
          width: 220,
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, _, _) => Text(l.billingQrMissing),
      );
    } else {
      return Text(l.billingQrMissing);
    }
    return Column(
      children: [
        Center(
          child: Semantics(label: l.billingQrSemantics, image: true, child: image),
        ),
        const SizedBox(height: 8),
        Text(l.billingQrHint, textAlign: TextAlign.center),
      ],
    );
  }
}

class _PaidCard extends StatelessWidget {
  final String slug;
  final BillingOrderModel order;
  const _PaidCard({required this.slug, required this.order});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              l.billingPaidTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              l.billingPaidMessage(order.planName),
              textAlign: TextAlign.center,
            ),
            // Masa berlaku terbaru sudah masuk SitesBloc lewat tenantUpdated.
            BlocBuilder<SitesBloc, SitesState>(
              builder: (context, state) {
                final expires = state.whenOrNull(
                  loaded: (d) => d.tenants
                      .where((t) => t.slug == slug)
                      .map((t) => t.plan?.expiresAt)
                      .firstOrNull,
                );
                if (expires == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l.planExpiresOn(formatDateId(expires.toLocal())),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.billingPaidDone),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosedCard extends StatelessWidget {
  final BillingOrderModel order;
  const _ClosedCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.highlight_off, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              l.billingClosedTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${l.billingClosedMessage}\n${billingStatusLabel(l, order.status)}',
              textAlign: TextAlign.center,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                'debug: status=${order.status} step=${order.step.name} method=${order.method}',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(96, 48)),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.billingBackToPlans),
            ),
          ],
        ),
      ),
    );
  }
}
