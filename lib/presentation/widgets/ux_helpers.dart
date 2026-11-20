import 'package:compro_builder/core/helper/app_keys.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Dialog konfirmasi seragam (paritas dialog konfirmasi web, Tahap 6a/6d).
///
/// Mengembalikan `true` hanya bila tombol aksi ditekan; batal, tap di luar,
/// atau tombol kembali menghasilkan `false`. [destructive] mewarnai tombol
/// aksi merah untuk tindakan yang tidak bisa dibatalkan (hapus, keluar).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final cancel = cancelLabel ?? context.l10n.actionCancel;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 48),
              backgroundColor: destructive ? scheme.error : null,
              foregroundColor: destructive ? scheme.onError : null,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

enum ToastKind { success, error, info }

/// Pemberitahuan singkat berwarna menurut jenisnya (paritas toast web).
/// Memakai [AppKeys.messenger] sehingga aman dipanggil dari listener Bloc.
void showToast(String message, {ToastKind kind = ToastKind.info}) {
  final messenger = AppKeys.messenger.currentState;
  if (messenger == null) return;
  final context = AppKeys.messenger.currentContext;
  final scheme = context == null ? null : Theme.of(context).colorScheme;

  Color? background;
  Color? foreground;
  IconData? icon;
  switch (kind) {
    case ToastKind.success:
      background = scheme?.primaryContainer;
      foreground = scheme?.onPrimaryContainer;
      icon = Icons.check_circle_outline_rounded;
    case ToastKind.error:
      background = scheme?.errorContainer;
      foreground = scheme?.onErrorContainer;
      icon = Icons.error_outline_rounded;
    case ToastKind.info:
      break;
  }

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: background,
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: foreground),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
}

/// Tombol utama dengan keadaan memuat (paritas tombol loading web).
/// Saat [loading] tombol nonaktif dan menampilkan spinner; ukuran tetap
/// supaya tata letak tidak bergeser.
class LoadingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Text(label),
    );
  }
}

/// Blok placeholder berdenyut untuk keadaan memuat (paritas x-skeleton).
class SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;

  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Daftar kartu placeholder, pengganti spinner penuh layar pada daftar.
class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const SkeletonList({super.key, this.count = 4, this.itemHeight = 96});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loading,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => SkeletonBox(height: itemHeight, radius: 16),
      ),
    );
  }
}
