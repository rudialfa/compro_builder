import 'package:compro_builder/core/helper/link_opener.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/utils/url.dart';
import 'package:compro_builder/data/datasources/address_remote_datasource.dart';
import 'package:compro_builder/data/model/response/domain_response_model.dart';
import 'package:compro_builder/presentation/bloc/domain/domain_bloc.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/pages/plan/plan_page.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Status domain sendiri (hanya baca) + petunjuk DNS. Menyetel, memverifikasi,
/// dan melepas domain dilakukan di dashboard web; saat pengguna kembali ke
/// aplikasi, status dimuat ulang otomatis.
class DomainPage extends StatelessWidget {
  final String slug;
  const DomainPage({super.key, required this.slug});

  static Future<void> open(BuildContext context, {required String slug}) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DomainPage(slug: slug)),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DomainBloc(AddressRemoteDatasource(), slug: slug)
            ..add(const DomainEvent.load()),
      child: _DomainView(slug: slug),
    );
  }
}

class _DomainView extends StatefulWidget {
  final String slug;
  const _DomainView({required this.slug});

  @override
  State<_DomainView> createState() => _DomainViewState();
}

class _DomainViewState extends State<_DomainView> with WidgetsBindingObserver {
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

  /// Kembali dari web -> muat ulang status domain dan data situs (alamat publik
  /// bisa berubah bila domain sudah aktif).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingReturn) {
      _awaitingReturn = false;
      context.read<DomainBloc>().add(const DomainEvent.load());
      context.read<SitesBloc>().add(const SitesEvent.refresh());
    }
  }

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  void _onState(BuildContext context, DomainState state) {
    final failure = state.whenOrNull(loaded: (d) => d.failure);
    if (failure != null) _snack(failure.message, kind: ToastKind.error);
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

  Future<void> _openPlan(BuildContext context) async {
    final bloc = context.read<DomainBloc>();
    final sites = context.read<SitesBloc>();
    await PlanPage.open(context, slug: widget.slug);
    if (!bloc.isClosed) bloc.add(const DomainEvent.load());
    if (!sites.isClosed) sites.add(const SitesEvent.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<DomainBloc, DomainState>(
      listener: _onState,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(l.domainTitle)),
        body: state.when(
          initial: () => const LoadingView(),
          loading: () => const LoadingView(),
          error: (failure) => ErrorView(
            message: failure.message,
            onRetry: () =>
                context.read<DomainBloc>().add(const DomainEvent.load()),
          ),
          loaded: (data) => RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<DomainBloc>()
                ..add(const DomainEvent.load());
              await bloc.stream.first;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: _content(context, data.status),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, DomainStatusModel s) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return [
      if (s.url != null)
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.public),
            title: Text(l.domainCurrentUrl),
            subtitle: SelectableText(s.url!),
          ),
        ),
      const SizedBox(height: 12),
      if (!s.allowed) ...[
        _Notice(
          icon: Icons.lock_outline,
          text: l.domainLocked,
          color: scheme.tertiaryContainer,
          onColor: scheme.onTertiaryContainer,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _openPlan(context),
          icon: const Icon(Icons.workspace_premium_outlined, size: 18),
          label: Text(l.planViewPlans),
        ),
      ] else ...[
        if (!s.featureReady) ...[
          _Notice(
            icon: Icons.info_outline,
            text: l.domainNotReady,
            color: scheme.secondaryContainer,
            onColor: scheme.onSecondaryContainer,
          ),
          const SizedBox(height: 12),
        ],
        if (s.host == null)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.domainNone, style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(l.domainNoneHint, style: text.bodyMedium),
                ],
              ),
            ),
          )
        else
          _HostCard(status: s),
        if (s.dns != null) ...[
          const SizedBox(height: 12),
          _DnsCard(dns: s.dns!),
        ],
        const SizedBox(height: 12),
        Text(
          l.domainWebHint,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (s.webUrl != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _openWeb(s.webUrl!),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(l.domainManageWeb),
          ),
        ],
      ],
    ];
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color onColor;

  const _Notice({
    required this.icon,
    required this.text,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: onColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HostCard extends StatelessWidget {
  final DomainStatusModel status;
  const _HostCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final label = status.active
        ? l.domainStatusActive
        : (status.verified
              ? l.domainStatusVerifiedInactive
              : l.domainStatusPending);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(status.active ? Icons.check_circle : Icons.schedule),
        title: SelectableText(status.host ?? ''),
        subtitle: Text(label),
      ),
    );
  }
}

class _DnsCard extends StatelessWidget {
  final DomainDnsModel dns;
  const _DnsCard({required this.dns});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final rows = <(String, String)>[
      if (dns.txtName != null) (l.domainDnsTxtName, dns.txtName!),
      if (dns.txtValue != null) (l.domainDnsTxtValue, dns.txtValue!),
      if (dns.serverIp != null) (l.domainDnsA, dns.serverIp!),
      if (dns.cnameTarget != null) (l.domainDnsCname, dns.cnameTarget!),
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.domainDnsTitle, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(l.domainDnsHint, style: text.bodySmall),
            const SizedBox(height: 8),
            for (final (label, value) in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(label, style: text.labelMedium),
                subtitle: SelectableText(value),
                trailing: IconButton(
                  tooltip: l.domainCopy,
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (!context.mounted) return;
                    showToast(l.domainCopied, kind: ToastKind.success);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
