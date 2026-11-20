import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/presentation/auth/bloc/verify_email/verify_email_bloc.dart';
import 'package:compro_builder/presentation/widgets/dev_verify_notice.dart';
import 'package:compro_builder/presentation/widgets/rate_limit_mixin.dart';
import 'package:compro_builder/presentation/widgets/ux_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tombol "Kirim ulang tautan verifikasi" untuk semua banner email belum
/// terverifikasi. Punya bloc sendiri (tidak perlu disediakan dari atas).
/// Setelah terkirim, tombol menunggu sebentar (server membatasi 3x/menit);
/// 429 memakai Retry-After dari server.
class ResendVerificationButton extends StatelessWidget {
  /// Dipanggil bila server menjawab email ternyata sudah terverifikasi, supaya
  /// halaman memuat ulang data yang bergantung pada status itu.
  final VoidCallback? onVerified;

  /// Bisa diganti di test.
  final AuthRemoteDatasource? remote;

  const ResendVerificationButton({super.key, this.onVerified, this.remote});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VerifyEmailBloc(remote ?? AuthRemoteDatasource()),
      child: _ResendView(onVerified: onVerified),
    );
  }
}

class _ResendView extends StatefulWidget {
  final VoidCallback? onVerified;
  const _ResendView({this.onVerified});

  @override
  State<_ResendView> createState() => _ResendViewState();
}

class _ResendViewState extends State<_ResendView>
    with RateLimitMixin<_ResendView> {
  /// Jeda setelah berhasil mengirim.
  static const _afterSentSeconds = 30;

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    if (message.isEmpty) return;
    showToast(message, kind: kind);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<VerifyEmailBloc, VerifyEmailState>(
      listener: (context, state) {
        state.whenOrNull(
          sent: (result) {
            _snack(result.message, kind: ToastKind.success);
            final devUrl = result.devVerifyUrl;
            if (devUrl != null) showDevVerifyNotice(devUrl);
            if (result.verified == true) {
              widget.onVerified?.call();
            } else {
              startCooldown(_afterSentSeconds);
            }
          },
          error: (failure) {
            _snack(failure.message, kind: ToastKind.error);
            if (failure.isRateLimited) startCooldown(failure.retryAfter);
          },
        );
      },
      builder: (context, state) {
        final loading = state.maybeWhen(loading: () => true, orElse: () => false);
        final locked = loading || isCoolingDown;
        return FilledButton.tonalIcon(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
          onPressed: locked
              ? null
              : () => context.read<VerifyEmailBloc>().add(
                  const VerifyEmailEvent.resend(),
                ),
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.forward_to_inbox_outlined),
          label: Text(
            loading
                ? l.accountResendSending
                : isCoolingDown
                ? l.accountResendWait(cooldownSeconds)
                : l.accountResendVerification,
          ),
        );
      },
    );
  }
}
