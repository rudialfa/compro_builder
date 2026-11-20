import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:compro_builder/core/config/env.dart';
import 'package:compro_builder/core/helper/link_opener.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/utils/color_hex.dart';
import 'package:compro_builder/core/utils/format.dart';
import 'package:compro_builder/data/datasources/checklist_remote_datasource.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/data/model/response/theme_response_model.dart';
import 'package:compro_builder/presentation/bloc/checklist/checklist_bloc.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/pages/billing/billing_page.dart';
import 'package:compro_builder/presentation/pages/messages/messages_page.dart';
import 'package:compro_builder/presentation/pages/onboarding/onboarding_page.dart';
import 'package:compro_builder/presentation/pages/plan/plan_page.dart';
import 'package:compro_builder/presentation/pages/publish/publish_page.dart';
import 'package:compro_builder/presentation/pages/settings/settings_page.dart';
import 'package:compro_builder/presentation/pages/address/address_page.dart';
import 'package:compro_builder/presentation/pages/domain/domain_page.dart';
import 'package:compro_builder/presentation/pages/template/template_page.dart';
import 'package:compro_builder/presentation/pages/theme/theme_page.dart';
import 'package:compro_builder/presentation/widgets/gradient_card.dart';
import 'package:compro_builder/presentation/widgets/resend_verification_button.dart';
import 'package:compro_builder/presentation/widgets/section_icons.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Peringatan masa berlaku paket mulai dari sisa hari ini (sama dengan web).
const kPlanWarningDays = 14;

/// Menu "Domain sendiri" disembunyikan sampai fiturnya dikembangkan.
const bool kShowCustomDomain = false;

/// Beranda situs aktif: status tayang, peringatan (nonaktif, paket hampir
/// habis, email belum terverifikasi), kelengkapan, dan jalan pintas.
/// Data situs dari [SitesBloc] (global); kelengkapan dari [ChecklistBloc]
/// milik halaman ini, dibuat ulang saat situs aktif berganti.
class DashboardPage extends StatelessWidget {
  /// Pindah ke tab Situs untuk mengganti situs aktif.
  final VoidCallback onSwitchSite;

  /// Dipanggil sesudah halaman Publikasi ditutup: section mungkin berubah lewat
  /// BLoC terpisah, jadi tab Section perlu dimuat ulang oleh cangkang.
  final VoidCallback onSectionsMayHaveChanged;

  const DashboardPage({
    super.key,
    required this.onSwitchSite,
    required this.onSectionsMayHaveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.dashboardTitle)),
      body: BlocBuilder<SitesBloc, SitesState>(
        builder: (context, state) => state.when(
          initial: () => const LoadingView(),
          loading: () => LoadingView(message: l.dashboardLoading),
          error: (failure) => ErrorView(
            message: failure.message,
            onRetry: () =>
                context.read<SitesBloc>().add(const SitesEvent.fetch()),
          ),
          loaded: (data) {
            final tenant = data.activeTenant;
            if (tenant == null) {
              return EmptyView(
                icon: Icons.storefront_outlined,
                title: l.dashboardNoSiteTitle,
                message: l.dashboardNoSiteMessage,
              );
            }
            return BlocProvider(
              key: ValueKey(tenant.slug),
              create: (_) =>
                  ChecklistBloc(ChecklistRemoteDatasource(), slug: tenant.slug)
                    ..add(const ChecklistEvent.load()),
              child: _DashboardView(
                tenant: tenant,
                canSwitchSite: data.tenants.length > 1,
                fromCache: data.fromCache,
                onSwitchSite: onSwitchSite,
                onSectionsMayHaveChanged: onSectionsMayHaveChanged,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final TenantModel tenant;
  final bool canSwitchSite;
  final bool fromCache;
  final VoidCallback onSwitchSite;
  final VoidCallback onSectionsMayHaveChanged;

  const _DashboardView({
    required this.tenant,
    required this.canSwitchSite,
    required this.fromCache,
    required this.onSwitchSite,
    required this.onSectionsMayHaveChanged,
  });

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  Future<void> _refresh(BuildContext context) async {
    final sites = context.read<SitesBloc>();
    final checklist = context.read<ChecklistBloc>();
    // Berlangganan sebelum add supaya emisi pertama tidak terlewat.
    final sitesNext = sites.stream.first;
    final checklistNext = checklist.stream.first;
    sites.add(const SitesEvent.refresh());
    checklist.add(const ChecklistEvent.refresh());
    const limit = Duration(seconds: 30);
    await Future.wait<Object>([
      sitesNext.timeout(limit, onTimeout: () => sites.state),
      checklistNext.timeout(limit, onTimeout: () => checklist.state),
    ]);
  }

  /// Buka halaman lain lalu segarkan daftar situs (nama, paket, pesan belum
  /// dibaca bisa berubah di sana).
  Future<void> _openThenRefreshSites(
    BuildContext context,
    Future<void> Function() open,
  ) async {
    final sites = context.read<SitesBloc>();
    await open();
    if (!sites.isClosed) sites.add(const SitesEvent.refresh());
  }

  Future<void> _openPublish(BuildContext context) async {
    final checklist = context.read<ChecklistBloc>();
    await PublishPage.openStandalone(context, slug: tenant.slug);
    onSectionsMayHaveChanged();
    if (!checklist.isClosed) checklist.add(const ChecklistEvent.refresh());
  }

  /// Pengaturan awal (kartu muncul selama `needsOnboarding`). Bila isian
  /// tersimpan, hero/kontak berubah: tab Section dan checklist dimuat ulang.
  Future<void> _openOnboarding(BuildContext context) async {
    final checklist = context.read<ChecklistBloc>();
    final saved = await OnboardingPage.open(context, slug: tenant.slug);
    if (!saved) return;
    onSectionsMayHaveChanged();
    if (!checklist.isClosed) checklist.add(const ChecklistEvent.refresh());
  }

  Future<void> _openSite(BuildContext context) async {
    final url = tenant.url;
    if (url == null) return;
    final l = context.l10n;
    final ok = await openExternalLink(Uri.parse(url));
    if (!ok) _snack(l.cannotOpenLink, kind: ToastKind.error);
  }

  /// Tiga kartu ringkas: pesan belum dibaca, sisa hari paket, status situs.
  /// Sentuhan memakai handler yang sama dengan menu sebelumnya.
  Widget _buildStats(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final plan = tenant.plan;
    final days = plan?.daysLeft();
    final unread = tenant.unreadMessages;
    final published = tenant.status == SiteStatus.published;

    final messages = unread == null ? '–' : (unread > 99 ? '99+' : '$unread');
    final planDays = plan == null
        ? '–'
        : (days == null ? '∞' : '${days < 0 ? 0 : days}');
    final IconData statusIcon;
    final Color statusColor;
    final Color? statusOn;
    final String statusText;
    if (tenant.suspended) {
      statusIcon = Icons.block;
      statusColor = scheme.error;
      statusOn = null;
      statusText = l.statusDisabled;
    } else if (published) {
      statusIcon = Icons.public;
      statusColor = AppTheme.teal;
      statusOn = AppTheme.tealDeep;
      statusText = l.statusPublished;
    } else if (tenant.status == SiteStatus.draft) {
      statusIcon = Icons.edit_note;
      statusColor = AppTheme.kunyit;
      statusOn = AppTheme.kunyitDeep;
      statusText = l.statusDraft;
    } else {
      statusIcon = Icons.help_outline;
      statusColor = scheme.outline;
      statusOn = null;
      statusText = '–';
    }

    return Builder(
      builder: (context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.mail_outline,
                color: AppTheme.blue,
                value: messages,
                label: l.dashboardStatMessages,
                onTap: () => _openThenRefreshSites(
                  context,
                  () => MessagesPage.open(context, slug: tenant.slug),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatTile(
                icon: Icons.workspace_premium_outlined,
                color: AppTheme.kunyit,
                foreground: AppTheme.kunyitDeep,
                value: planDays,
                label: l.dashboardStatPlanDays,
                onTap: () => _openThenRefreshSites(
                  context,
                  () => PlanPage.open(context, slug: tenant.slug),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatTile(
                icon: statusIcon,
                color: statusColor,
                foreground: statusOn,
                value: statusText,
                label: l.dashboardStatStatus,
                compactValue: true,
                onTap: published && tenant.url != null
                    ? () => _openSite(context)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kisi dua kolom dengan tinggi baris yang sama.
  Widget _grid(List<Widget> tiles) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final second = i + 1 < tiles.length ? tiles[i + 1] : const SizedBox();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: 10),
              Expanded(child: second),
            ],
          ),
        ),
      );
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final plan = tenant.plan;
    final days = plan?.daysLeft();

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (fromCache) ...[
            Card(
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.cloud_off),
                title: Text(l.offlineBanner),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _SiteHeader(
            tenant: tenant,
            canSwitchSite: canSwitchSite,
            onSwitchSite: onSwitchSite,
          ),
          const SizedBox(height: 16),
          if (tenant.suspended) ...[
            _AlertCard(
              color: Theme.of(context).colorScheme.errorContainer,
              onColor: Theme.of(context).colorScheme.onErrorContainer,
              icon: Icons.block,
              title: l.blockDisabledTitle,
              message: tenant.suspendedReason ?? l.blockDisabledMessage,
              actionLabel: Env.adminContactUrl.isEmpty ? null : l.contactAdmin,
              onAction: Env.adminContactUrl.isEmpty
                  ? null
                  : () async {
                      final ok = await openContactLink(
                        Uri.parse(Env.adminContactUrl),
                      );
                      if (!ok) _snack(l.cannotOpenLink, kind: ToastKind.error);
                    },
            ),
            const SizedBox(height: 12),
          ],
          if (tenant.needsOnboarding && !tenant.suspended) ...[
            _AlertCard(
              color: Theme.of(context).colorScheme.secondaryContainer,
              onColor: Theme.of(context).colorScheme.onSecondaryContainer,
              icon: Icons.auto_awesome_outlined,
              title: l.onboardingCardTitle,
              message: l.onboardingCardMessage,
              actionLabel: l.onboardingStart,
              onAction: () => _openOnboarding(context),
            ),
            const SizedBox(height: 12),
          ],
          if (plan != null && days != null && days <= kPlanWarningDays) ...[
            _AlertCard(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              onColor: Theme.of(context).colorScheme.onTertiaryContainer,
              icon: Icons.hourglass_bottom,
              title: plan.isExpired()
                  ? l.dashboardPlanExpiredTitle
                  : l.dashboardPlanExpiringTitle,
              message: plan.isExpired()
                  ? l.dashboardPlanExpiredMessage
                  : (days <= 0
                        ? l.dashboardPlanExpiresToday
                        : l.dashboardPlanExpiresIn(days)),
              actionLabel: l.dashboardRenew,
              onAction: () => _openThenRefreshSites(
                context,
                () => BillingPage.open(context, slug: tenant.slug),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildStats(context),
          const SizedBox(height: 12),
          BlocBuilder<ChecklistBloc, ChecklistState>(
            builder: (context, state) {
              final report = state.whenOrNull(loaded: (v) => v.data);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (report != null &&
                      report.publish.isEmailBlock &&
                      !tenant.suspended) ...[
                    _AlertCard(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      onColor: Theme.of(
                        context,
                      ).colorScheme.onSecondaryContainer,
                      icon: Icons.mark_email_unread_outlined,
                      title: l.blockEmailTitle,
                      message: l.blockEmailMessage,
                      actionLabel: l.openEmail,
                      onAction: () async {
                        final ok = await openContactLink(Uri(scheme: 'mailto'));
                        if (!ok) _snack(l.cannotOpenLink, kind: ToastKind.error);
                      },
                      extra: ResendVerificationButton(
                        onVerified: () => _refresh(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _CompletenessCard(
                    state: state,
                    fallback: tenant.completeness,
                    onRetry: () => context.read<ChecklistBloc>().add(
                      const ChecklistEvent.refresh(),
                    ),
                    onOpenPublish: () => _openPublish(context),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          SectionLabel(l.dashboardManageTitle),
          const SizedBox(height: 10),
          _grid([
            NavTile(
              icon: Icons.settings_outlined,
              color: AppTheme.blue,
              title: l.settingsTitle,
              subtitle: Text(tenant.name),
              onTap: () => _openThenRefreshSites(
                context,
                () => SettingsPage.open(context, slug: tenant.slug),
              ),
            ),
            NavTile(
              icon: Icons.palette_outlined,
              color: AppTheme.violet,
              title: l.themeTitle,
              subtitle: tenant.theme == null
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tenant.theme != null) _ThemeDots(theme: tenant.theme!),
                        if ((tenant.theme?.name ?? '').isNotEmpty)
                          Flexible(child: Text(tenant.theme!.name)),
                      ],
                    ),
              // Hasil simpan sudah masuk SitesBloc (tenantUpdated).
              onTap: () => ThemePage.open(context, slug: tenant.slug),
            ),
            NavTile(
              icon: Icons.web_outlined,
              color: AppTheme.teal,
              foreground: AppTheme.tealDeep,
              title: l.templateTitle,
              subtitle: (tenant.template?.name ?? '').isEmpty
                  ? null
                  : Text(tenant.template!.name),
              // Hasil ganti sudah masuk SitesBloc (tenantUpdated); refresh
              // saat kembali menangkap perubahan paket dari halaman Paket.
              onTap: () => _openThenRefreshSites(
                context,
                () => TemplatePage.open(context, slug: tenant.slug),
              ),
            ),
            NavTile(
              icon: Icons.link,
              color: AppTheme.rose,
              title: l.addressTitle,
              subtitle: Text(tenant.slug),
              // Slug baru masuk SitesBloc (tenantUpdated) dan menggantikan
              // situs aktif; halaman ini dibangun ulang dengan slug baru.
              onTap: () => AddressPage.open(context, slug: tenant.slug),
            ),
            // Domain sendiri disembunyikan dulu (belum dikembangkan).
            // Ubah kShowCustomDomain jadi true untuk memunculkannya lagi.
            if (kShowCustomDomain)
              NavTile(
                icon: Icons.dns_outlined,
                color: AppTheme.kunyit,
                foreground: AppTheme.kunyitDeep,
                title: l.domainTitle,
                subtitle: (tenant.domain?.host ?? '').isEmpty
                    ? null
                    : Text(tenant.domain!.host!),
                onTap: () => _openThenRefreshSites(
                  context,
                  () => DomainPage.open(context, slug: tenant.slug),
                ),
              ),
          ]),
          if (tenant.status == SiteStatus.published && tenant.url != null) ...[
            const SizedBox(height: 10),
            AppSurface(
              onTap: () => _openSite(context),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const IconChip(
                    icon: Icons.open_in_new,
                    color: AppTheme.indigo,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.dashboardOpenSite,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          tenant.url!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Titik kecil brand + cerah sebagai pratinjau warna situs.
class _ThemeDots extends StatelessWidget {
  final ThemeOptionModel theme;
  const _ThemeDots({required this.theme});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget dot(Color? color) => Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outline),
      ),
    );
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [dot(parseHexColor(theme.brand)), dot(parseHexColor(theme.bright))],
      ),
    );
  }
}

class _SiteHeader extends StatelessWidget {
  final TenantModel tenant;
  final bool canSwitchSite;
  final VoidCallback onSwitchSite;

  const _SiteHeader({
    required this.tenant,
    required this.canSwitchSite,
    required this.onSwitchSite,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final planName = tenant.plan?.name ?? '';
    final trimmed = tenant.name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    initial,
                    style: text.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleLarge?.copyWith(color: Colors.white),
                    ),
                    Text(
                      '/${tenant.slug}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (tenant.status == SiteStatus.published)
                PillBadge(
                  icon: Icons.public,
                  label: l.statusPublished,
                  background: AppTheme.teal.withValues(alpha: 0.45),
                ),
              if (tenant.status == SiteStatus.draft)
                PillBadge(
                  icon: Icons.edit_note,
                  label: l.statusDraft,
                  background: Colors.white.withValues(alpha: 0.2),
                ),
              if (tenant.suspended)
                PillBadge(
                  icon: Icons.block,
                  label: l.blockDisabledTitle,
                  background: const Color(0xFFBA1A1A).withValues(alpha: 0.75),
                ),
              if (planName.isNotEmpty)
                PillBadge(
                  icon: Icons.workspace_premium_outlined,
                  label: l.planLabel(planName),
                  background: AppTheme.kunyit.withValues(alpha: 0.35),
                ),
            ],
          ),
          if (canSwitchSite)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: onSwitchSite,
                icon: const Icon(Icons.swap_horiz),
                label: Text(l.dashboardSwitchSite),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Color color;
  final Color onColor;
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Tombol tambahan di bawah tombol aksi (mis. kirim ulang verifikasi).
  final Widget? extra;

  const _AlertCard({
    required this.color,
    required this.onColor,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radiusTile),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: onColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: onColor, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: onColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: TextStyle(color: onColor)),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 10),
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
    );
  }
}

class _CompletenessCard extends StatelessWidget {
  final ChecklistState state;

  /// Ringkasan dari daftar situs; tampil sementara checklist belum termuat.
  final CompletenessModel? fallback;
  final VoidCallback onRetry;
  final VoidCallback onOpenPublish;

  const _CompletenessCard({
    required this.state,
    required this.fallback,
    required this.onRetry,
    required this.onOpenPublish,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final report = state.whenOrNull(loaded: (v) => v.data);
    final failure = state.whenOrNull(error: (f) => f);
    final percent = report?.percent ?? fallback?.percent;
    final pending = report?.items.where((i) => !i.isComplete).toList() ?? [];
    const maxShown = 3;

    final title = Semantics(
      header: true,
      child: Text(
        l.checklistTitle,
        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );

    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (percent != null)
            Row(
              children: [
                Semantics(
                  label: l.completenessPercent(percent),
                  child: ProgressRing(percent: percent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 2),
                      Text(
                        report != null
                            ? l.completenessCounts(
                                report.complete,
                                report.partial,
                                report.empty,
                              )
                            : l.completenessPercent(percent),
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            title,
            const SizedBox(height: 8),
            if (failure != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.error_outline),
                title: Text(failure.message),
                trailing: TextButton(onPressed: onRetry, child: Text(l.retry)),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
          if (report != null && report.items.isEmpty) ...[
            const SizedBox(height: 12),
            Text(l.checklistNoSections),
          ] else if (report != null && pending.isEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(l.checklistAllGood)),
              ],
            ),
          ] else if (pending.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(l.dashboardNeedsWork, style: text.labelLarge),
            for (final it in pending.take(maxShown))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: scheme.secondary,
                ),
                title: Text(sectionLabel(it.code, it.name)),
                subtitle: it.note == null ? null : Text(it.note!),
                onTap: onOpenPublish,
              ),
            if (pending.length > maxShown)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l.dashboardMoreItems(pending.length - maxShown),
                  style: text.bodySmall,
                ),
              ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onOpenPublish,
            icon: const Icon(Icons.rocket_launch_outlined),
            label: Text(l.dashboardCheckAndPublish),
          ),
        ],
      ),
    );
  }
}
