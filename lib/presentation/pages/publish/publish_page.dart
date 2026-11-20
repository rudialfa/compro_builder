import 'package:compro_builder/core/config/env.dart';
import 'package:compro_builder/core/helper/link_opener.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/data/datasources/checklist_remote_datasource.dart';
import 'package:compro_builder/data/datasources/publish_remote_datasource.dart';
import 'package:compro_builder/data/datasources/sections_local_datasource.dart';
import 'package:compro_builder/data/datasources/sections_remote_datasource.dart';
import 'package:compro_builder/data/model/response/checklist_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/presentation/bloc/checklist/checklist_bloc.dart';
import 'package:compro_builder/presentation/bloc/publish/publish_bloc.dart';
import 'package:compro_builder/presentation/bloc/sections/sections_bloc.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/pages/preview/preview_page.dart';
import 'package:compro_builder/presentation/pages/sections/section_editor_page.dart';
import 'package:compro_builder/presentation/widgets/section_icons.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Publikasi situs: status tayang + kelengkapan dari server (GET /checklist).
/// [SectionsBloc] harus ada di atas halaman ini (editor section dan pratinjau
/// membacanya): dari [SectionsPage]/[PreviewPage] lewat [open], dari Beranda
/// lewat [openStandalone] yang membuat instansnya sendiri.
class PublishPage extends StatelessWidget {
  final String slug;
  final SiteStatus initialStatus;
  const PublishPage({
    super.key,
    required this.slug,
    required this.initialStatus,
  });

  static SiteStatus _statusOf(BuildContext context, String slug) =>
      context.read<SitesBloc>().state.maybeWhen(
        loaded: (d) => d.tenants.where((t) => t.slug == slug).firstOrNull,
        orElse: () => null,
      )?.status ??
      SiteStatus.unknown;

  static Future<void> open(BuildContext context, {required String slug}) {
    final sectionsBloc = context.read<SectionsBloc>();
    final status = _statusOf(context, slug);
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: sectionsBloc,
          child: PublishPage(slug: slug, initialStatus: status),
        ),
      ),
    );
  }

  /// Dari Beranda (di luar [SectionsPage]): [SectionsBloc] dibuat khusus untuk
  /// halaman ini dan ditutup saat halaman ditutup. Pemanggil wajib menyegarkan
  /// tab Section sesudahnya karena bloc-nya terpisah.
  static Future<void> openStandalone(
    BuildContext context, {
    required String slug,
  }) {
    final status = _statusOf(context, slug);
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => SectionsBloc(
            SectionsRemoteDatasource(),
            SectionsLocalDatasource(),
            slug: slug,
          )..add(const SectionsEvent.fetch()),
          child: PublishPage(slug: slug, initialStatus: status),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PublishBloc(
            PublishRemoteDatasource(),
            slug: slug,
            initialStatus: initialStatus,
          ),
        ),
        BlocProvider(
          create: (_) => ChecklistBloc(ChecklistRemoteDatasource(), slug: slug)
            ..add(const ChecklistEvent.load()),
        ),
      ],
      child: _PublishView(slug: slug),
    );
  }
}

class _PublishView extends StatefulWidget {
  final String slug;
  const _PublishView({required this.slug});

  @override
  State<_PublishView> createState() => _PublishViewState();
}

class _PublishViewState extends State<_PublishView> with RateLimitMixin<_PublishView> {
  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  Future<bool> _confirm(String title, String message, String action) async {
    return showConfirmDialog(
      context,
      title: title,
      message: message,
      confirmLabel: action,
    );
  }

  /// Menayangkan SELALU meminta konfirmasi; bila masih ada yang belum lengkap,
  /// dialognya menyebut jumlahnya. Menjadikan draft juga dikonfirmasi.
  Future<void> _change(SiteStatus target, int issues) async {
    final l = context.l10n;
    final bloc = context.read<PublishBloc>();
    final proceed = target == SiteStatus.published
        ? (issues == 0
              ? await _confirm(
                  l.publishConfirmTitle,
                  l.publishConfirm,
                  l.publishActionPublish,
                )
              : await _confirm(
                  l.publishConfirmIssuesTitle,
                  l.publishConfirmIssues(issues),
                  l.publishAnyway,
                ))
        : await _confirm(
            l.publishConfirmDraftTitle,
            l.publishConfirmDraft,
            l.publishActionDraft,
          );
    if (!proceed || !mounted) return;
    bloc.add(PublishEvent.setStatus(target));
  }

  Future<void> _openLink(Uri uri) async {
    final ok = await openContactLink(uri);
    if (!ok && mounted) _snack(context.l10n.cannotOpenLink, kind: ToastKind.error);
  }

  /// Buka editor section dari baris checklist; sesudahnya checklist dimuat ulang
  /// karena isian section mengubah kelengkapan.
  Future<void> _openSection(int sectionId) async {
    final l = context.l10n;
    final checklist = context.read<ChecklistBloc>();
    final view = context.read<SectionsBloc>().state.whenOrNull(loaded: (v) => v);
    final section = view?.data.sections
        .where((s) => s.id == sectionId)
        .firstOrNull;
    if (section == null) {
      _snack(l.checklistSectionUnavailable);
      return;
    }
    await SectionEditorPage.open(context, slug: widget.slug, section: section);
    if (!checklist.isClosed) checklist.add(const ChecklistEvent.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return MultiBlocListener(
      listeners: [
        BlocListener<ChecklistBloc, ChecklistState>(
          listenWhen: (_, s) =>
              s.whenOrNull(loaded: (v) => v.refreshFailure) != null,
          listener: (context, s) {
            final failure = s.whenOrNull(loaded: (v) => v.refreshFailure);
            if (failure != null) _snack(failure.message, kind: ToastKind.error);
          },
        ),
      ],
      child: BlocConsumer<PublishBloc, PublishState>(
        listenWhen: (_, s) =>
            s.notice != null || s.updatedTenant != null || s.failure != null,
        listener: (context, s) {
          final tenant = s.updatedTenant;
          if (tenant != null) {
            // Daftar situs menampilkan status juga: gabungkan hasil server.
            context.read<SitesBloc>().add(SitesEvent.tenantUpdated(tenant));
          }
          switch (s.notice) {
            case PublishNotice.published:
              _snack(l.publishedOk, kind: ToastKind.success);
            case PublishNotice.drafted:
              _snack(l.draftOk, kind: ToastKind.success);
            case null:
              break;
          }
          if (s.notice != null) {
            // Status tayang ikut tercatat di blok `publish` checklist.
            context.read<ChecklistBloc>().add(const ChecklistEvent.refresh());
          }
          final failure = s.failure;
          if (failure != null) {
            _snack(failure.message, kind: ToastKind.error);
            if (failure.isRateLimited) startCooldown(failure.retryAfter);
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: Text(l.publishTitle)),
            body: BlocBuilder<ChecklistBloc, ChecklistState>(
              builder: (context, checklistState) {
                final report = checklistState.whenOrNull(
                  loaded: (v) => v.data,
                );
                // Hambatan dari server (sebelum pengguna mencoba) dan dari 403.
                final serverBlock = report == null
                    ? null
                    : report.publish.isSuspendedBlock
                    ? PublishBlock.siteDisabled
                    : report.publish.isEmailBlock
                    ? PublishBlock.emailUnverified
                    : null;
                final block = state.block ?? serverBlock;
                final target = state.isPublished
                    ? SiteStatus.draft
                    : SiteStatus.published;
                final busy = state.isChanging || isCoolingDown;
                // Hanya menahan menayangkan; menjadikan draft tetap boleh.
                final blockedPublish = !state.isPublished && serverBlock != null;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (block != null) ...[
                      _BlockCard(
                        block: block,
                        serverMessage: state.blockMessage,
                        onOpenEmail: () => _openLink(Uri(scheme: 'mailto')),
                        onContactAdmin: Env.adminContactUrl.isEmpty
                            ? null
                            : () => _openLink(Uri.parse(Env.adminContactUrl)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _StatusCard(status: state.status),
                    const SizedBox(height: 16),
                    _ChecklistCard(
                      state: checklistState,
                      onRetry: () => context.read<ChecklistBloc>().add(
                        const ChecklistEvent.refresh(),
                      ),
                      onOpenSection: _openSection,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed:
                          (busy ||
                              state.status == SiteStatus.unknown ||
                              blockedPublish)
                          ? null
                          : () => _change(target, report?.issueCount ?? 0),
                      icon: state.isChanging
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              state.isPublished
                                  ? Icons.visibility_off_outlined
                                  : Icons.rocket_launch_outlined,
                            ),
                      label: Text(
                        state.isPublished
                            ? l.publishActionDraft
                            : l.publishActionPublish,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => PreviewPage.open(
                        context,
                        slug: widget.slug,
                        canOpenPublish: false,
                      ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(l.previewTitle),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SiteStatus status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (icon, label, text) = switch (status) {
      SiteStatus.published => (
        Icons.public,
        l.statusPublished,
        l.publishStatusPublished,
      ),
      SiteStatus.draft => (
        Icons.edit_note,
        l.statusDraft,
        l.publishStatusDraft,
      ),
      SiteStatus.unknown => (Icons.help_outline, '', l.publishStatusUnknown),
    };
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label.isNotEmpty)
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final ChecklistState state;
  final VoidCallback onRetry;
  final void Function(int sectionId) onOpenSection;

  const _ChecklistCard({
    required this.state,
    required this.onRetry,
    required this.onOpenSection,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final report = state.whenOrNull(loaded: (v) => v.data);
    final failure = state.whenOrNull(error: (f) => f);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Semantics(
                header: true,
                child: Text(
                  l.checklistTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            if (report != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.completenessPercent(report.percent)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: report.percent / 100,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              if (report.items.isEmpty)
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.checklistNoSections),
                )
              else if (report.issueCount == 0)
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(l.checklistAllGood),
                ),
              for (final it in report.items) _tile(context, it),
            ] else if (failure != null)
              ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(failure.message),
                trailing: TextButton(onPressed: onRetry, child: Text(l.retry)),
              )
            else
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, ChecklistItemModel it) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      minVerticalPadding: 8,
      leading: Icon(
        it.isComplete ? Icons.check_circle : Icons.warning_amber_rounded,
        color: it.isComplete ? scheme.primary : null,
      ),
      title: Text(sectionLabel(it.code, it.name)),
      subtitle: (it.isComplete || it.note == null) ? null : Text(it.note!),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => onOpenSection(it.id),
    );
  }
}

class _BlockCard extends StatelessWidget {
  final PublishBlock block;
  final String? serverMessage;
  final VoidCallback onOpenEmail;
  final VoidCallback? onContactAdmin;

  const _BlockCard({
    required this.block,
    required this.serverMessage,
    required this.onOpenEmail,
    required this.onContactAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final (title, message) = switch (block) {
      PublishBlock.emailUnverified => (
        l.blockEmailTitle,
        l.blockEmailMessage,
      ),
      PublishBlock.siteDisabled => (
        l.blockDisabledTitle,
        l.blockDisabledMessage,
      ),
      PublishBlock.other => (l.blockOtherTitle, serverMessage ?? l.errorGeneric),
    };
    return Semantics(
      liveRegion: true,
      child: Card(
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(message, style: TextStyle(color: scheme.onErrorContainer)),
              if (block == PublishBlock.emailUnverified) ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: onOpenEmail,
                  icon: const Icon(Icons.mail_outline),
                  label: Text(l.openEmail),
                ),
              ],
              if (block == PublishBlock.siteDisabled &&
                  onContactAdmin != null) ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: onContactAdmin,
                  icon: const Icon(Icons.support_agent),
                  label: Text(l.contactAdmin),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
