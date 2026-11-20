import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/utils/reset_link.dart';
import 'package:compro_builder/core/utils/validators.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/data/model/request/reset_password_request_model.dart';
import 'package:compro_builder/presentation/auth/bloc/reset_password/reset_password_bloc.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Atur ulang password dengan tautan/kode dari email. Email berisi tautan web
/// `/reset-password/{token}?email=...`; pengguna menempel tautan utuh (token
/// dan email diambil otomatis) atau hanya tokennya. Sukses: server mencabut
/// semua token login lama, jadi pengguna kembali ke layar masuk.
///
/// Halaman ini dibuka dari ForgotPasswordPage, jadi sukses menutup dua halaman
/// (ini dan lupa password).
class ResetPasswordPage extends StatelessWidget {
  final String initialEmail;

  /// Token (dan email) dari deep link; mengisi isian otomatis.
  final ResetLinkInput? initialLink;

  /// Dibuka dari tautan (bukan dari halaman lupa password): sukses hanya
  /// menutup halaman ini, bukan dua halaman.
  final bool fromLink;

  /// Bisa diganti di test.
  final AuthRemoteDatasource? remote;

  const ResetPasswordPage({
    super.key,
    this.initialEmail = '',
    this.initialLink,
    this.fromLink = false,
    this.remote,
  });

  static Future<void> open(
    BuildContext context, {
    String initialEmail = '',
    ResetLinkInput? initialLink,
    bool fromLink = false,
  }) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ResetPasswordPage(
        initialEmail: initialEmail,
        initialLink: initialLink,
        fromLink: fromLink,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ResetPasswordBloc(remote ?? AuthRemoteDatasource()),
      child: _ResetView(
        initialEmail: initialEmail,
        initialLink: initialLink,
        fromLink: fromLink,
      ),
    );
  }
}

class _ResetView extends StatefulWidget {
  final String initialEmail;
  final ResetLinkInput? initialLink;
  final bool fromLink;
  const _ResetView({
    required this.initialEmail,
    required this.initialLink,
    required this.fromLink,
  });

  @override
  State<_ResetView> createState() => _ResetViewState();
}

class _ResetViewState extends State<_ResetView>
    with RateLimitMixin<_ResetView> {
  final _form = GlobalKey<FormState>();
  final _token = TextEditingController();
  late final TextEditingController _email = TextEditingController(
    text: widget.initialLink?.email ?? widget.initialEmail,
  );
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;
  Map<String, List<String>> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    final link = widget.initialLink;
    if (link != null) _token.text = link.token;
  }

  @override
  void dispose() {
    _token.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) {
      setState(() => _serverErrors = {..._serverErrors}..remove(field));
    }
  }

  /// Tautan utuh membawa email: isi otomatis supaya pengguna tidak mengetik lagi.
  void _onTokenChanged(String value) {
    _clearServerError('email');
    final email = parseResetInput(value).email;
    if (email != null && email != _email.text) _email.text = email;
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty || !mounted) return;
    _token.text = text;
    _onTokenChanged(text);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _serverErrors = {});
    if (!(_form.currentState?.validate() ?? false)) return;
    final parsed = parseResetInput(_token.text);
    context.read<ResetPasswordBloc>().add(
      ResetPasswordEvent.submit(
        ResetPasswordRequestModel(
          token: parsed.token,
          email: _email.text.trim(),
          password: _password.text,
          passwordConfirmation: _confirm.text,
        ),
      ),
    );
  }

  void _onResult(BuildContext context, ResetPasswordState state) {
    state.whenOrNull(
      success: (message) {
        _snack(message, kind: ToastKind.success);
        // Tutup halaman ini dan halaman lupa password -> layar masuk.
        final navigator = Navigator.of(context);
        navigator.pop();
        if (!widget.fromLink) navigator.pop();
      },
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
      appBar: AppBar(title: Text(l.resetTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
                listener: _onResult,
                builder: (context, state) {
                  final loading = state.maybeWhen(
                    loading: () => true,
                    orElse: () => false,
                  );
                  final locked = loading || isCoolingDown;
                  return Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l.resetIntro, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _token,
                          enabled: !loading,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          onChanged: _onTokenChanged,
                          decoration: InputDecoration(
                            labelText: l.resetTokenLabel,
                            prefixIcon: const Icon(Icons.link),
                            // Galat token salah/kedaluwarsa datang pada kunci `email`.
                            errorText: _serverErrors['email']?.first,
                            errorMaxLines: 3,
                            suffixIcon: IconButton(
                              tooltip: l.resetPaste,
                              icon: const Icon(Icons.content_paste),
                              onPressed: loading ? null : _paste,
                            ),
                          ),
                          validator: (v) => parseResetInput(v ?? '').token.isEmpty
                              ? l.validationRequired
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _email,
                          enabled: !loading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          onChanged: (_) => _clearServerError('email'),
                          decoration: InputDecoration(
                            labelText: l.accountEmailLabel,
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                          ),
                          validator: Validators.email(l),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          enabled: !loading,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: (_) => _clearServerError('password'),
                          decoration: InputDecoration(
                            labelText: l.resetPasswordLabel,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            errorText: _serverErrors['password']?.first,
                            suffixIcon: IconButton(
                              tooltip: _hidePassword
                                  ? l.accountShowPassword
                                  : l.accountHidePassword,
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                            ),
                          ),
                          validator: Validators.password(l),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirm,
                          enabled: !loading,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) {
                            if (!locked) _submit();
                          },
                          decoration: InputDecoration(
                            labelText: l.resetConfirmLabel,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                          ),
                          validator: Validators.matches(l, _password),
                        ),
                        const SizedBox(height: 24),
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
                                      : l.resetSubmit,
                                ),
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
