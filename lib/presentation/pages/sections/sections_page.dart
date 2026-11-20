import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/data/datasources/sections_local_datasource.dart';
import 'package:compro_builder/data/datasources/sections_remote_datasource.dart';
import 'package:compro_builder/data/model/response/section_model.dart';
import 'package:compro_builder/presentation/bloc/sections/sections_bloc.dart';
import 'package:compro_builder/presentation/pages/messages/messages_page.dart';
import 'package:compro_builder/presentation/pages/plan/plan_page.dart';
import 'package:compro_builder/presentation/pages/sections/section_editor_page.dart';
import 'package:compro_builder/presentation/pages/settings/settings_page.dart';
import 'package:compro_builder/presentation/widgets/section_icons.dart';
import 'package:compro_builder/presentation/widgets/section_tile.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Daftar section satu situs. Bloc dibuat di sini (per halaman); ganti `key`
/// dengan slug supaya berpindah situs membuat bloc baru.
/// (Tombol ke Preview/Pesan/Publish/Setelan/Paket menyusul di Fase 4.)
class SectionsPage extends StatelessWidget {
  final String slug;
  final String? siteName;
  const SectionsPage({super.key, required this.slug, this.siteName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SectionsBloc(
        SectionsRemoteDatasource(),
        SectionsLocalDatasource(),
        slug: slug,
      )..add(const SectionsEvent.fetch()),
      child: _SectionsView(siteName: siteName),
    );
  }
}

class _SectionsView extends StatelessWidget {
  final String? siteName;
  const _SectionsView({this.siteName});

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<SectionsBloc>();
    // Berlangganan sebelum add supaya emisi pertama tidak terlewat.
    final next = bloc.stream.first;
    bloc.add(const SectionsEvent.refresh());
    await next.timeout(
      const Duration(seconds: 30),
      onTimeout: () => bloc.state,
    );
  }

  void _showLocked(BuildContext context) {
    final l = context.l10n;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.lock_outline),
        title: Text(l.lockedTitle),
        content: Text(l.lockedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.ok),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              PlanPage.open(context, slug: context.read<SectionsBloc>().slug);
            },
            child: Text(l.planViewPlans),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, SectionModel s) async {
    final l = context.l10n;
    return showConfirmDialog(
      context,
      title: l.deleteConfirmTitle,
      message: l.deleteConfirmMessage(sectionLabel(s.type, s.name)),
      confirmLabel: l.actionDelete,
      destructive: true,
    );
  }

  Future<void> _delete(BuildContext context, SectionModel s) async {
    final bloc = context.read<SectionsBloc>();
    if (!await _confirmDelete(context, s)) return;
    bloc.add(SectionsEvent.delete(s.id));
  }

  Future<void> _openAddSheet(
    BuildContext context,
    SectionsViewData view,
  ) async {
    final l = context.l10n;
    final bloc = context.read<SectionsBloc>();
    final data = view.data;
    final picked = await showModalBottomSheet<SectionTypeModel>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            if (data.limitReached)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l.limitReached),
              ),
            if (data.addable.isEmpty && data.locked.isEmpty)
              ListTile(title: Text(l.noAddable)),
            for (final t in data.addable)
              ListTile(
                leading: Icon(sectionIcon(t.type)),
                title: Text(sectionLabel(t.type, t.name)),
                enabled: !data.limitReached,
                onTap: () => Navigator.pop(sheetContext, t),
              ),
            for (final t in data.locked)
              ListTile(
                leading: Icon(sectionIcon(t.type)),
                title: Text(sectionLabel(t.type, t.name)),
                trailing: const Icon(Icons.lock_outline),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showLocked(context);
                },
              ),
          ],
        ),
      ),
    );
    if (picked != null) bloc.add(SectionsEvent.add(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<SectionsBloc, SectionsState>(
      listenWhen: (_, current) =>
          current.whenOrNull(
            loaded: (v) => v.actionFailure != null || v.notice != null,
          ) ??
          false,
      listener: (context, state) {
        final view = state.whenOrNull(loaded: (v) => v);
        if (view == null) return;
        final failure = view.actionFailure;
        if (failure != null) {
          _snack(failure.message, kind: ToastKind.error);
        } else if (view.notice == SectionsNotice.sectionAdded) {
          _snack(l.sectionAdded, kind: ToastKind.success);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.sectionsTitle),
                if (siteName != null && siteName!.isNotEmpty)
                  Text(
                    siteName!,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: l.messagesTitle,
                icon: const Icon(Icons.mail_outline),
                onPressed: () => MessagesPage.open(
                  context,
                  slug: context.read<SectionsBloc>().slug,
                ),
              ),
              IconButton(
                tooltip: l.settingsTitle,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => SettingsPage.open(
                  context,
                  slug: context.read<SectionsBloc>().slug,
                ),
              ),
              IconButton(
                tooltip: l.planTitle,
                icon: const Icon(Icons.workspace_premium_outlined),
                onPressed: () => PlanPage.open(
                  context,
                  slug: context.read<SectionsBloc>().slug,
                ),
              ),
            ],
          ),
          floatingActionButton: state.maybeWhen(
            loaded: (view) => FloatingActionButton.extended(
              onPressed: view.isAdding
                  ? null
                  : () => _openAddSheet(context, view),
              icon: view.isAdding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(l.addSection),
            ),
            orElse: () => null,
          ),
          body: state.when(
            initial: () => const LoadingView(),
            loading: () => const LoadingView(),
            error: (failure) => ErrorView(
              message: failure.message,
              onRetry: () =>
                  context.read<SectionsBloc>().add(const SectionsEvent.fetch()),
            ),
            loaded: (view) => _buildLoaded(context, view),
          ),
        );
      },
    );
  }

  Widget _buildLoaded(BuildContext context, SectionsViewData view) {
    final l = context.l10n;
    final bloc = context.read<SectionsBloc>();
    final data = view.data;
    final sections = data.sections;

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (view.fromCache)
            SliverToBoxAdapter(
              child: MaterialBanner(
                content: Text(l.offlineBanner),
                leading: const Icon(Icons.cloud_off),
                actions: const [SizedBox.shrink()],
              ),
            ),
          SliverToBoxAdapter(child: _Usage(data: data)),
          if (sections.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.view_agenda_outlined,
                title: l.sectionsEmpty,
              ),
            )
          else
            SliverList.builder(
              itemCount: sections.length,
              itemBuilder: (context, i) {
                final s = sections[i];
                final tile = SectionTile(
                  section: s,
                  position: i + 1,
                  total: sections.length,
                  canMoveUp: i > 0 && !sections[i - 1].locked,
                  canMoveDown:
                      i < sections.length - 1 && !sections[i + 1].locked,
                  onTap: () {
                    if (s.locked) {
                      _showLocked(context);
                    } else {
                      SectionEditorPage.open(
                        context,
                        slug: bloc.slug,
                        section: s,
                      );
                    }
                  },
                  onToggle: () => bloc.add(SectionsEvent.toggle(s.id)),
                  onMove: (up) => bloc.add(SectionsEvent.move(s.id, up: up)),
                  onDelete: () => _delete(context, s),
                );
                if (s.locked) {
                  return KeyedSubtree(key: ValueKey(s.id), child: tile);
                }
                return Dismissible(
                  key: ValueKey(s.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDelete(context, s),
                  onDismissed: (_) => bloc.add(SectionsEvent.delete(s.id)),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  child: tile,
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 88)),
        ],
      ),
    );
  }
}

class _Usage extends StatelessWidget {
  final SectionsDataModel data;
  const _Usage({required this.data});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final limit = data.limit;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            limit == null
                ? l.usageUnlimited(data.used)
                : l.usageLabel(data.used, limit),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (limit != null && limit > 0) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: (data.used / limit).clamp(0.0, 1.0),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ],
      ),
    );
  }
}
