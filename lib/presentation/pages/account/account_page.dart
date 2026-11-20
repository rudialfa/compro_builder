import 'package:compro_builder/core/constants/variables.dart';
import 'package:compro_builder/core/helper/deep_link_service.dart';
import 'package:compro_builder/core/helper/link_opener.dart';
import 'package:compro_builder/core/helper/share_helper.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:compro_builder/core/utils/site_urls.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/data/model/response/auth_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/presentation/auth/bloc/logout/logout_bloc.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/pages/billing/billing_page.dart';
import 'package:compro_builder/presentation/pages/messages/messages_page.dart';
import 'package:compro_builder/presentation/pages/settings/settings_page.dart';
import 'package:compro_builder/presentation/pages/theme/theme_page.dart';
import 'package:compro_builder/presentation/widgets/gradient_card.dart';
import 'package:compro_builder/presentation/widgets/resend_verification_button.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tab Akun: profil pengguna, ringkasan situs, aksi cepat untuk situs aktif,
/// menu kelola situs, dan tombol keluar.
class AccountPage extends StatefulWidget {
  final UserModel user;

  /// Bisa diganti di test.
  final AuthRemoteDatasource? remote;

  /// Pindah ke tab Situs (tombol "Ganti situs" / statistik situs).
  final VoidCallback? onSwitchSite;

  const AccountPage({
    super.key,
    required this.user,
    this.remote,
    this.onSwitchSite,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage>
    with WidgetsBindingObserver {
  UserModel get user => widget.user;
  bool _checking = false;

  /// Server menjawab email ternyata sudah terverifikasi (data pengguna dari
  /// shell tidak dimuat ulang, jadi banner disembunyikan di sini).
  bool _verifiedNow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DeepLinkService.instance.verifiedTick.addListener(_checkVerified);
    // Verifikasi lewat tautan mungkin selesai sebelum layar ini ada (cold start).
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVerified());
  }

  @override
  void dispose() {
    DeepLinkService.instance.verifiedTick.removeListener(_checkVerified);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Pengguna biasanya baru memverifikasi lewat email/browser lalu kembali ke
  /// aplikasi: muat ulang `/auth/me` saat app kembali aktif atau saat tautan
  /// `email-verified` masuk.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkVerified();
  }

  Future<void> _checkVerified() async {
    if (_checking || user.isEmailVerified || _verifiedNow) return;
    _checking = true;
    final result = await (widget.remote ?? AuthRemoteDatasource()).me();
    _checking = false;
    if (!mounted) return;
    result.fold((_) {}, (fresh) {
      if (fresh.isEmailVerified) {
        setState(() => _verifiedNow = true);
        showToast('Email terverifikasi. Terima kasih!', kind: ToastKind.success);
      }
    });
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l.accountLogoutTitle,
      message: l.accountLogoutMessage,
      confirmLabel: l.actionLogout,
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<LogoutBloc>().add(const LogoutEvent.logout());
    }
  }

  // ── Aksi ────────────────────────────────────────────────────────────────

  Future<void> _refresh() async {
    final sites = context.read<SitesBloc>();
    final next = sites.stream.first;
    sites.add(const SitesEvent.refresh());
    await next.timeout(const Duration(seconds: 30), onTimeout: () => sites.state);
    await _checkVerified();
  }

  Future<void> _copyEmail() async {
    await Clipboard.setData(ClipboardData(text: user.email));
    if (!mounted) return;
    showToast(context.l10n.accountEmailCopied, kind: ToastKind.success);
  }

  String _urlOf(TenantModel t) =>
      publicSiteUrl(t.url, Variables.siteBaseUrl, t.slug);

  Future<void> _openSite(TenantModel t) async {
    final l = context.l10n;
    final ok = await openExternalLink(Uri.parse(_urlOf(t)));
    if (!ok && mounted) showToast(l.cannotOpenLink, kind: ToastKind.error);
  }

  Future<void> _copyLink(TenantModel t) async {
    final l = context.l10n;
    await Clipboard.setData(ClipboardData(text: _urlOf(t)));
    if (!mounted) return;
    showToast(l.previewCopied, kind: ToastKind.success);
  }

  Future<void> _shareSite(TenantModel t) => shareText(
    context.l10n.shareMessage(t.name.isEmpty ? t.slug : t.name, _urlOf(t)),
    subject: t.name,
  );

  /// Buka halaman lain lalu segarkan daftar situs (nama, paket, pesan belum
  /// dibaca bisa berubah di sana).
  Future<void> _openThenRefresh(Future<void> Function() open) async {
    final sites = context.read<SitesBloc>();
    await open();
    if (!sites.isClosed) sites.add(const SitesEvent.refresh());
  }

  void _showAbout() {
    final l = context.l10n;
    showAboutDialog(
      context: context,
      applicationName: 'Compro Builder',
      children: [Text(l.accountAboutText)],
    );
  }

  // ── Tampilan ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.shellTabAccount)),
      body: BlocBuilder<SitesBloc, SitesState>(
        builder: (context, state) {
          final data = state.whenOrNull(loaded: (d) => d);
          final tenants = data?.tenants ?? const <TenantModel>[];
          final tenant = data?.activeTenant;
          final published = tenants
              .where((t) => t.status == SiteStatus.published)
              .length;
          final unread = tenants.fold<int>(
            0,
            (sum, t) => sum + (t.unreadMessages ?? 0),
          );

          var i = 0;
          Widget reveal(Widget child) => _Reveal(index: i++, child: child);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                reveal(_buildHero(context)),
                const SizedBox(height: 12),
                reveal(
                  _buildStats(
                    context,
                    sites: tenants.length,
                    published: published,
                    unread: unread,
                    tenant: tenant,
                  ),
                ),
                if (!user.isEmailVerified && !_verifiedNow) ...[
                  const SizedBox(height: 12),
                  reveal(_buildVerifyBanner(context)),
                ],
                const SizedBox(height: 12),
                reveal(_buildActiveSite(context, tenant, tenants.length)),
                if (tenant != null) ...[
                  const SizedBox(height: 20),
                  reveal(SectionLabel(l.accountManageTitle)),
                  const SizedBox(height: 10),
                  reveal(_buildManageMenu(context, tenant)),
                ],
                const SizedBox(height: 20),
                reveal(SectionLabel(l.accountMoreTitle)),
                const SizedBox(height: 10),
                reveal(
                  AppSurface(
                    padding: EdgeInsets.zero,
                    child: _MenuRow(
                      icon: Icons.info_outline_rounded,
                      color: AppTheme.violet,
                      title: l.accountAbout,
                      onTap: _showAbout,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                reveal(
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(l.actionLogout),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return GradientCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Text(
                user.name.isEmpty ? '?' : user.name.characters.first.toUpperCase(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                // Ketuk email untuk menyalin.
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: _copyEmail,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (user.isEmailVerified || _verifiedNow)
                  PillBadge(
                    icon: Icons.check_circle_outline,
                    label: l.accountEmailVerified,
                    background: Colors.white.withValues(alpha: 0.2),
                  )
                else
                  PillBadge(
                    icon: Icons.mark_email_unread_outlined,
                    label: l.accountEmailUnverifiedTitle,
                    background: AppTheme.kunyit,
                    foreground: AppTheme.indigo,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(
    BuildContext context, {
    required int sites,
    required int published,
    required int unread,
    required TenantModel? tenant,
  }) {
    final l = context.l10n;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatTile(
              icon: Icons.storefront_outlined,
              color: AppTheme.blue,
              value: '$sites',
              label: l.accountStatSites,
              onTap: widget.onSwitchSite,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              icon: Icons.public,
              color: AppTheme.teal,
              foreground: AppTheme.tealDeep,
              value: '$published',
              label: l.statusPublished,
              onTap: widget.onSwitchSite,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              icon: Icons.mail_outline,
              color: AppTheme.rose,
              value: unread > 99 ? '99+' : '$unread',
              label: l.accountStatUnread,
              onTap: tenant == null
                  ? null
                  : () => _openThenRefresh(
                      () => MessagesPage.open(context, slug: tenant.slug),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyBanner(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusTile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.onSecondaryContainer.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      color: scheme.onSecondaryContainer,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.accountEmailUnverifiedTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l.accountEmailUnverifiedMessage,
                        style: TextStyle(color: scheme.onSecondaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ResendVerificationButton(
              onVerified: () => setState(() => _verifiedNow = true),
            ),
          ],
        ),
      ),
    );
  }

  /// Lencana status situs: Tayang / Draft / Nonaktif.
  Widget _statusBadge(BuildContext context, TenantModel t) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    if (t.suspended) {
      return PillBadge(
        icon: Icons.block,
        label: l.statusDisabled,
        background: scheme.error.withValues(alpha: 0.14),
        foreground: scheme.error,
      );
    }
    if (t.status == SiteStatus.published) {
      return PillBadge(
        icon: Icons.public,
        label: l.statusPublished,
        background: AppTheme.teal.withValues(alpha: 0.16),
        foreground: AppTheme.tealDeep,
      );
    }
    return PillBadge(
      icon: Icons.edit_note,
      label: l.statusDraft,
      background: AppTheme.kunyit.withValues(alpha: 0.22),
      foreground: AppTheme.kunyitDeep,
    );
  }

  Widget _buildActiveSite(BuildContext context, TenantModel? t, int count) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (t == null) {
      return AppSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.dashboardNoSiteTitle,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l.dashboardNoSiteMessage,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (widget.onSwitchSite != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: widget.onSwitchSite,
                icon: const Icon(Icons.storefront_outlined),
                label: Text(l.shellTabSites),
              ),
            ],
          ],
        ),
      );
    }

    final canOpen =
        t.status == SiteStatus.published && !t.suspended && t.url != null;
    final plan = t.plan;
    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconChip(icon: Icons.language, color: AppTheme.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.accountActiveSite,
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      t.name.isEmpty ? t.slug : t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '/${t.slug}${plan != null && plan.name.isNotEmpty ? '  ·  ${l.accountPlanName(plan.name)}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(context, t),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.open_in_new_rounded,
                  label: l.accountOpenSite,
                  color: AppTheme.blue,
                  onTap: canOpen ? () => _openSite(t) : null,
                ),
              ),
              Expanded(
                child: _QuickAction(
                  icon: Icons.link_rounded,
                  label: l.accountCopyLink,
                  color: AppTheme.teal,
                  foreground: AppTheme.tealDeep,
                  onTap: () => _copyLink(t),
                ),
              ),
              Expanded(
                child: _QuickAction(
                  icon: Icons.ios_share_rounded,
                  label: l.accountShare,
                  color: AppTheme.violet,
                  onTap: () => _shareSite(t),
                ),
              ),
              if (count > 1 && widget.onSwitchSite != null)
                Expanded(
                  child: _QuickAction(
                    icon: Icons.swap_horiz_rounded,
                    label: l.accountSwitchSite,
                    color: AppTheme.kunyit,
                    foreground: AppTheme.kunyitDeep,
                    onTap: widget.onSwitchSite,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManageMenu(BuildContext context, TenantModel t) {
    final l = context.l10n;
    final unread = t.unreadMessages ?? 0;
    final rows = <Widget>[
      _MenuRow(
        icon: Icons.mail_outline,
        color: AppTheme.blue,
        title: l.messagesTitle,
        subtitle: unread > 0 ? l.accountUnreadCount(unread) : l.accountNoUnread,
        badge: unread > 0 ? (unread > 99 ? '99+' : '$unread') : null,
        onTap: () => _openThenRefresh(
          () => MessagesPage.open(context, slug: t.slug),
        ),
      ),
      _MenuRow(
        icon: Icons.workspace_premium_outlined,
        color: AppTheme.kunyit,
        foreground: AppTheme.kunyitDeep,
        title: l.billingTitle,
        subtitle: l.accountMenuBillingDesc,
        onTap: () => _openThenRefresh(
          () => BillingPage.open(context, slug: t.slug),
        ),
      ),
      _MenuRow(
        icon: Icons.settings_outlined,
        color: AppTheme.teal,
        foreground: AppTheme.tealDeep,
        title: l.settingsTitle,
        subtitle: l.accountMenuSettingsDesc,
        onTap: () => _openThenRefresh(
          () => SettingsPage.open(context, slug: t.slug),
        ),
      ),
      _MenuRow(
        icon: Icons.palette_outlined,
        color: AppTheme.violet,
        title: l.themeTitle,
        subtitle: l.accountMenuThemeDesc,
        onTap: () => ThemePage.open(context, slug: t.slug),
      ),
    ];
    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var k = 0; k < rows.length; k++) ...[
            if (k > 0) const Divider(height: 1, indent: 68),
            rows[k],
          ],
        ],
      ),
    );
  }
}

/// Tombol aksi cepat: ikon-chip di atas, label di bawah. Nonaktif bila [onTap] null.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.foreground,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconChip(icon: icon, color: color, foreground: foreground),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Satu baris menu: ikon-chip, judul, keterangan, lencana angka (opsional), panah.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.foreground,
    this.subtitle,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final Color? foreground;
  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            IconChip(icon: icon, color: color, foreground: foreground),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (badge != null) ...[
              PillBadge(label: badge!, background: AppTheme.rose),
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Muncul pelan-pelan (fade + geser sedikit) berurutan menurut [index].
/// Dimatikan bila pengguna memilih "kurangi animasi".
class _Reveal extends StatelessWidget {
  const _Reveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 70),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
      ),
    );
  }
}
