import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/utils/validators.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/presentation/auth/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:compro_builder/presentation/auth/reset_password_page.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Minta tautan atur ulang password lewat email. Jawaban server selalu sama,
/// ada atau tidaknya akun, jadi halaman ini tidak pernah memberi tahu apakah
/// email terdaftar. Tautan di email membuka web; pengguna menyalinnya ke
/// [ResetPasswordPage].
class ForgotPasswordPage extends StatelessWidget {
  final String initialEmail;

  /// Bisa diganti di test.
  final AuthRemoteDatasource? remote;

  const ForgotPasswordPage({super.key, this.initialEmail = '', this.remote});

  static Future<void> open(BuildContext context, {String initialEmail = ''}) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ForgotPasswordPage(initialEmail: initialEmail),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgotPasswordBloc(remote ?? AuthRemoteDatasource()),
      child: _ForgotView(initialEmail: initialEmail),
    );
  }
}

class _ForgotView extends StatefulWidget {
  final String initialEmail;
  const _ForgotView({required this.initialEmail});

  @override
  State<_ForgotView> createState() => _ForgotViewState();
}

class _ForgotViewState extends State<_ForgotView>
    with RateLimitMixin<_ForgotView> {
  /// Jeda sebelum boleh kirim ulang (server membatasi 5x/menit).
  static const _afterSentSeconds = 30;

  final _form = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  Map<String, List<String>> _serverErrors = {};

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _serverErrors = {});
    if (!(_form.currentState?.validate() ?? false)) return;
    context.read<ForgotPasswordBloc>().add(
      ForgotPasswordEvent.submit(_email.text.trim()),
    );
  }

  void _onResult(BuildContext context, ForgotPasswordState state) {
    state.whenOrNull(
      sent: (_) => startCooldown(_afterSentSeconds),
      error: (failure) {
        if (failure.isRateLimited) startCooldown(failure.retryAfter);
        if (failure.fieldErrors.isNotEmpty) {
          setState(() => _serverErrors = failure.fieldErrors);
        } else {
          _snack(failure.message, kind: ToastKind.error);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.forgotTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
                listener: _onResult,
                builder: (context, state) {
                  final loading = state.maybeWhen(
                    loading: () => true,
                    orElse: () => false,
                  );
                  final sentMessage = state.whenOrNull(sent: (m) => m);
                  final locked = loading || isCoolingDown;
                  return Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l.forgotIntro, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _email,
                          enabled: !loading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          onChanged: (_) {
                            if (_serverErrors.containsKey('email')) {
                              setState(
                                () => _serverErrors = {..._serverErrors}
                                  ..remove('email'),
                              );
                            }
                          },
                          onFieldSubmitted: (_) {
                            if (!locked) _submit();
                          },
                          decoration: InputDecoration(
                            labelText: l.accountEmailLabel,
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                            errorText: _serverErrors['email']?.first,
                          ),
                          validator: Validators.email(l),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(96, 48),
                          ),
                          onPressed: locked ? null : _submit,
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  isCoolingDown
                                      ? l.accountResendWait(cooldownSeconds)
                                      : sentMessage == null
                                      ? l.forgotSubmit
                                      : l.forgotResend,
                                ),
                        ),
                        if (sentMessage != null) ...[
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Card(
                              color: theme.colorScheme.secondaryContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.forgotSentTitle,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSecondaryContainer,
                                          ),
                                    ),
                                    if (sentMessage.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        sentMessage,
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme
                                              .onSecondaryContainer,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(96, 48),
                            ),
                            onPressed: () => ResetPasswordPage.open(
                              context,
                              initialEmail: _email.text.trim(),
                            ),
                            child: Text(l.forgotHaveLink),
                          ),
                        ],
                        TextButton(
                          onPressed: loading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(l.forgotBack),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
