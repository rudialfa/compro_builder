import 'package:compro_builder/core/helper/link_opener.dart';
import 'package:compro_builder/core/helper/reply_links.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/data/model/response/contact_message_model.dart';
import 'package:compro_builder/presentation/bloc/messages/messages_bloc.dart';
import 'package:compro_builder/presentation/pages/messages/messages_page.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Detail satu pesan. Tidak ada endpoint detail di backend, jadi halaman ini
/// membaca dari [MessagesBloc] milik daftar (BlocProvider.value) — satu sumber
/// kebenaran untuk status dibaca dan hapus. Membuka pesan menandainya dibaca.
class MessageDetailPage extends StatefulWidget {
  final int messageId;
  const MessageDetailPage({super.key, required this.messageId});

  static Future<void> open(BuildContext context, {required int messageId}) {
    final bloc = context.read<MessagesBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: MessageDetailPage(messageId: messageId),
        ),
      ),
    );
  }

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  @override
  void initState() {
    super.initState();
    // Endpoint bersifat toggle: hanya kirim bila pesan masih belum dibaca.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MessagesBloc>().add(
        MessagesEvent.toggleRead(widget.messageId, onlyIfUnread: true),
      );
    });
  }

  ContactMessageModel? _find(MessagesState state) => state.maybeWhen(
    loaded: (v) {
      for (final m in v.items) {
        if (m.id == widget.messageId) return m;
      }
      return null;
    },
    orElse: () => null,
  );

  Future<void> _open(Uri? uri) async {
    if (uri == null) return;
    final ok = await openExternalLink(uri);
    if (!ok && mounted) {
      showToast(context.l10n.cannotOpenLink, kind: ToastKind.error);
    }
  }

  Future<void> _delete(ContactMessageModel m) async {
    final bloc = context.read<MessagesBloc>();
    if (!await confirmDeleteMessage(context, m) || !mounted) return;
    bloc.add(MessagesEvent.delete(m.id));
    // Kembali ke daftar; snackbar sukses/gagal ditampilkan oleh listener
    // halaman daftar, dan bila gagal pesan dikembalikan oleh bloc (rollback).
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocBuilder<MessagesBloc, MessagesState>(
      builder: (context, state) {
        final m = _find(state);
        return Scaffold(
          appBar: AppBar(
            title: Text(l.messagesTitle),
            actions: [
              if (m != null) ...[
                IconButton(
                  tooltip: m.isRead ? l.markUnread : l.markRead,
                  icon: Icon(
                    m.isRead
                        ? Icons.mark_email_unread_outlined
                        : Icons.drafts_outlined,
                  ),
                  onPressed: () => context.read<MessagesBloc>().add(
                    MessagesEvent.toggleRead(m.id),
                  ),
                ),
                IconButton(
                  tooltip: l.actionDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(m),
                ),
              ],
            ],
          ),
          body: m == null
              ? EmptyView(icon: Icons.mail_outline, title: l.messageNotFound)
              : _Detail(message: m, onOpen: _open),
        );
      },
    );
  }
}

class _Detail extends StatelessWidget {
  final ContactMessageModel message;
  final Future<void> Function(Uri?) onOpen;
  const _Detail({required this.message, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final wa = whatsappUri(message.phone, l.waGreeting(message.name));
    final mail = emailUri(message.email, l.replySubject);
    final tel = telUri(message.phone);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(message.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            formatDateTime(message.createdAt),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _Row(
            icon: Icons.mail_outline,
            label: l.fieldEmail,
            value: message.email,
          ),
          if (message.phone != null)
            _Row(
              icon: Icons.phone_outlined,
              label: l.messagePhone,
              value: message.phone!,
            ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: SelectableText(message.message),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (wa != null)
            FilledButton.icon(
              onPressed: () => onOpen(wa),
              icon: const Icon(Icons.chat_outlined),
              label: Text(l.replyWhatsapp),
            ),
          if (mail != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => onOpen(mail),
              icon: const Icon(Icons.mail_outline),
              label: Text(l.replyEmail),
            ),
          ],
          if (tel != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => onOpen(tel),
              icon: const Icon(Icons.call_outlined),
              label: Text(l.replyCall),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        ExcludeSemantics(child: Icon(icon, size: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(label: label, child: SelectableText(value)),
        ),
      ],
    ),
  );
}
