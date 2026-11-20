import 'package:compro_builder/core/components/components.dart';
import 'package:compro_builder/core/constants/variables.dart';
import 'package:compro_builder/core/helper/deep_link_service.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/data/model/request/login_request_model.dart';
import 'package:compro_builder/presentation/auth/bloc/login/login_bloc.dart';
import 'package:compro_builder/presentation/auth/forgot_password_page.dart';
import 'package:compro_builder/presentation/auth/register_page.dart';
import 'package:compro_builder/presentation/auth/reset_password_page.dart';
import 'package:compro_builder/presentation/auth/post_auth_route.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  /// Ganti seluruh tumpukan halaman dengan layar masuk.
  static void openReplacing(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with RateLimitMixin<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  /// Galat 422 dari server, ditampilkan di bawah field terkait.
  Map<String, List<String>> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    // Aplikasi dibuka dari tautan atur ulang password saat belum berjalan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = DeepLinkService.instance.takePending();
      if (pending != null && mounted) {
        ResetPasswordPage.open(context, initialLink: pending, fromLink: true);
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _serverErrors = {});
    if (!(_form.currentState?.validate() ?? false)) return;
    context.read<LoginBloc>().add(LoginEvent.login(LoginRequestModel(
          email: _email.text.trim(),
          password: _password.text,
        )));
  }

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) {
      setState(() => _serverErrors = {..._serverErrors}..remove(field));
    }
  }

  void _onResult(BuildContext context, LoginState state) {
    state.whenOrNull(
      success: (data) => openAfterAuth(context, data.user),
      error: (failure) {
        if (failure.isRateLimited) startCooldown(failure.retryAfter);
        if (failure.fieldErrors.isNotEmpty) {
          setState(() => _serverErrors = failure.fieldErrors);
        } else {
          showToast(failure.message, kind: ToastKind.error);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocConsumer<LoginBloc, LoginState>(
                listener: _onResult,
                builder: (context, state) {
                  final loading =
                      state.maybeWhen(loading: () => true, orElse: () => false);
                  final locked = loading || isCoolingDown;
                  return Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const BrandBadge(icon: Icons.web_rounded),
                        const SpaceHeight(16),
                        Text(
                          Variables.appName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SpaceHeight(4),
                        Text(
                          l.loginSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SpaceHeight(32),
                        TextFormField(
                          controller: _email,
                          enabled: !loading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          onChanged: (_) => _clearServerError('email'),
                          decoration: InputDecoration(
                            labelText: l.fieldEmail,
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                            errorText: _serverErrors['email']?.first,
                          ),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return l.authEmailRequired;
                            if (!value.contains('@') || !value.contains('.')) {
                              return l.authEmailInvalid;
                            }
                            return null;
                          },
                        ),
                        const SpaceHeight(16),
                        TextFormField(
                          controller: _password,
                          enabled: !loading,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onChanged: (_) => _clearServerError('password'),
                          onFieldSubmitted: (_) {
                            if (!locked) _submit();
                          },
                          decoration: InputDecoration(
                            labelText: l.authPasswordLabel,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            errorText: _serverErrors['password']?.first,
                            suffixIcon: IconButton(
                              tooltip: _hidePassword
                                  ? l.accountShowPassword
                                  : l.accountHidePassword,
                              icon: Icon(_hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword),
                            ),
                          ),
                          validator: (v) => (v ?? '').isEmpty
                              ? l.authPasswordRequired
                              : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: loading
                                ? null
                                : () => ForgotPasswordPage.open(
                                      context,
                                      initialEmail: _email.text.trim(),
                                    ),
                            child: Text(l.authForgotLink),
                          ),
                        ),
                        const SpaceHeight(8),
                        LoadingButton(
                          loading: loading,
                          onPressed: locked ? null : _submit,
                          label: isCoolingDown
                              ? l.authRetryIn(cooldownSeconds)
                              : l.actionLogin,
                        ),
                        const SpaceHeight(8),
                        TextButton(
                          onPressed: loading
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => const RegisterPage()),
                                  ),
                          child: Text(l.noAccount),
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
