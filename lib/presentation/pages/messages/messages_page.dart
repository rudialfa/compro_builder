import 'package:compro_builder/core/helper/reply_links.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/data/datasources/messages_remote_datasource.dart';
import 'package:compro_builder/data/model/response/contact_message_model.dart';
import 'package:compro_builder/presentation/bloc/messages/messages_bloc.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/pages/messages/message_detail_page.dart';
import 'package:compro_builder/presentation/pages/plan/plan_page.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pesan masuk dari form kontak situs (berpaginasi).
class MessagesPage extends StatelessWidget {
  final String slug;
  const MessagesPage({super.key, required this.slug});

  static Future<void> open(BuildContext context, {required String slug}) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => MessagesPage(slug: slug)));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MessagesBloc(MessagesRemoteDatasource(), slug: slug)
            ..add(const MessagesEvent.load()),
      child: _MessagesView(slug: slug),
    );
  }
}

Future<bool> confirmDeleteMessage(
  BuildContext context,
  ContactMessageModel m,
) async {
  final l = context.l10n;
  return showConfirmDialog(
    context,
    title: l.messageDeleteTitle,
    message: l.messageDeleteConfirm(m.name),
    confirmLabel: l.actionDelete,
    destructive: true,
  );
}

class _MessagesView extends StatelessWidget {
  final String slug;
  const _MessagesView({required this.slug});

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<MessagesBloc>();
    final next = bloc.stream.first;
    bloc.add(const MessagesEvent.refresh());
    await next.timeout(
      const Duration(seconds: 30),
      onTimeout: () => bloc.state,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<MessagesBloc, MessagesState>(
      listenWhen: (_, current) =>
          current.whenOrNull(
            loaded: (v) =>
                v.actionFailure != null || v.notice != null || v.unreadChanged,
          ) ??
          false,
      listener: (context, state) {
        final v = state.whenOrNull(loaded: (v) => v);
        if (v == null) return;
        if (v.actionFailure != null) {
          _snack(v.actionFailure!.message, kind: ToastKind.error);
        } else if (v.notice == MessagesNotice.deleted) {
          _snack(l.messageDeleted, kind: ToastKind.success);
        }
        // Badge "belum dibaca" di daftar situs mengikuti perubahan ini.
        if (v.unreadChanged) {
          context.read<SitesBloc>().add(const SitesEvent.refresh());
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(l.messagesTitle)),
        body: state.when(
          initial: () => const LoadingView(),
          loading: () => const LoadingView(),
          error: (failure) => failure.isForbidden
              // Paket tanpa form kontak (Standar): ajak upgrade.
              ? EmptyView(
                  icon: Icons.lock_outline,
                  title: l.messagesUpgradeTitle,
                  message: l.messagesUpgradeMessage,
                  actionLabel: l.planViewPlans,
                  onAction: () => PlanPage.open(context, slug: slug),
                )
              : ErrorView(
                  message: failure.message,
                  onRetry: () => context.read<MessagesBloc>().add(
                    const MessagesEvent.load(),
                  ),
                ),
          loaded: (view) => _buildList(context, view),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, MessagesViewData view) {
    final l = context.l10n;
    final bloc = context.read<MessagesBloc>();
    final items = view.items;

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 320,
                  child: EmptyView(
                    icon: Icons.mail_outline,
                    title: l.messagesEmpty,
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length + (view.hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= items.length) {
                  return _Footer(
                    view: view,
                    onLoad: () => bloc.add(const MessagesEvent.loadMore()),
                  );
                }
                final m = items[i];
                return Dismissible(
                  key: ValueKey(m.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => confirmDeleteMessage(context, m),
                  onDismissed: (_) => bloc.add(MessagesEvent.delete(m.id)),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  child: _MessageTile(
                    message: m,
                    onTap: () =>
                        MessageDetailPage.open(context, messageId: m.id),
                    onToggle: () => bloc.add(MessagesEvent.toggleRead(m.id)),
                  ),
                );
              },
            ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final ContactMessageModel message;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  const _MessageTile({
    required this.message,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final unread = !message.isRead;
    return Semantics(
      label: unread ? l.messageUnread : null,
      child: ListTile(
        minVerticalPadding: 12,
        leading: unread
            ? Icon(Icons.mark_email_unread, color: scheme.primary)
            : Icon(Icons.drafts_outlined, color: scheme.outline),
        title: Text(
          message.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        subtitle: Text(
          message.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatDateTime(message.createdAt),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            IconButton(
              tooltip: unread ? l.markRead : l.markUnread,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Icon(unread ? Icons.done : Icons.undo, size: 20),
              onPressed: onToggle,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Footer infinite scroll: saat tampil -> memuat halaman berikutnya.
class _Footer extends StatefulWidget {
  final MessagesViewData view;
  final VoidCallback onLoad;
  const _Footer({required this.view, required this.onLoad});

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  @override
  void initState() {
    super.initState();
    _maybeLoad();
  }

  @override
  void didUpdateWidget(_Footer old) {
    super.didUpdateWidget(old);
    _maybeLoad();
  }

  void _maybeLoad() {
    final v = widget.view;
    if (v.hasMore && !v.isLoadingMore && v.loadMoreFailure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLoad();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final failed = widget.view.loadMoreFailure != null;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: failed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.loadMoreFailed),
                  TextButton(onPressed: widget.onLoad, child: Text(l.retry)),
                ],
              )
            : const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
      ),
    );
  }
}
