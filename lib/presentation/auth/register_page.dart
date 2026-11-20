import 'package:compro_builder/core/components/components.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/data/model/request/register_request_model.dart';
import 'package:compro_builder/presentation/auth/bloc/register/register_bloc.dart';
import 'package:compro_builder/presentation/bottom_navbar/main_shell_page.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with RateLimitMixin<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _slug = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;

  Map<String, List<String>> _serverErrors = {};

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _slug.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _serverErrors = {});
    if (!(_form.currentState?.validate() ?? false)) return;
    context.read<RegisterBloc>().add(RegisterEvent.register(
          RegisterRequestModel(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            passwordConfirmation: _confirm.text,
            companyName: _company.text.trim(),
            slug: _slug.text.trim(),
          ),
        ));
  }

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) {
      setState(() => _serverErrors = {..._serverErrors}..remove(field));
    }
  }

  void _onResult(BuildContext context, RegisterState state) {
    state.whenOrNull(
      success: (data) {
        MainShellPage.openReplacing(context, data.user);
        showToast(context.l10n.registerCreated, kind: ToastKind.success);
      },
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
      appBar: AppBar(title: Text(l.actionRegister)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocConsumer<RegisterBloc, RegisterState>(
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
                        Text(
                          l.registerHeading,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SpaceHeight(20),
                        TextFormField(
                          controller: _name,
                          enabled: !loading,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          onChanged: (_) => _clearServerError('name'),
                          decoration: InputDecoration(
                            labelText: l.registerNameLabel,
                            prefixIcon:
                                const Icon(Icons.person_outline_rounded),
                            errorText: _serverErrors['name']?.first,
                          ),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return l.registerNameRequired;
                            if (value.length > 100) {
                              return l.registerNameMax;
                            }
                            return null;
                          },
                        ),
                        const SpaceHeight(16),
                        TextFormField(
                          controller: _company,
                          enabled: !loading,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => _clearServerError('company_name'),
                          decoration: InputDecoration(
                            labelText: l.onboardingName,
                            prefixIcon: const Icon(Icons.storefront_outlined),
                            errorText: _serverErrors['company_name']?.first,
                          ),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return l.registerCompanyRequired;
                            if (value.length > 100) {
                              return l.registerCompanyMax;
                            }
                            return null;
                          },
                        ),
                        const SpaceHeight(16),
                        TextFormField(
                          controller: _slug,
                          enabled: !loading,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9-]')),
                            TextInputFormatter.withFunction(
                              (oldValue, newValue) => newValue.copyWith(
                                  text: newValue.text.toLowerCase()),
                            ),
                          ],
                          onChanged: (_) => _clearServerError('slug'),
                          decoration: InputDecoration(
                            labelText: l.registerSlugLabel,
                            helperText: l.registerSlugHelper,
                            helperMaxLines: 2,
                            prefixIcon: const Icon(Icons.link_rounded),
                            // 422 dari server: alamat sudah dipakai / tidak boleh dipakai.
                            errorText: _serverErrors['slug']?.first,
                          ),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return null;
                            if (value.length < 3 || value.length > 40) {
                              return l.registerSlugLength;
                            }
                            if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$')
                                .hasMatch(value)) {
                              return l.registerSlugChars;
                            }
                            return null;
                          },
                        ),
                        const SpaceHeight(16),
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
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: (_) => _clearServerError('password'),
                          decoration: InputDecoration(
                            labelText: l.authPasswordLabel,
                            helperText: l.registerPasswordHelper,
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
                          validator: (v) {
                            final value = v ?? '';
                            if (value.isEmpty) return l.authPasswordRequired;
                            if (value.length < 8) {
                              return l.registerPasswordMin;
                            }
                            return null;
                          },
                        ),
                        const SpaceHeight(16),
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
                            labelText: l.registerConfirmLabel,
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                          ),
                          validator: (v) => (v ?? '') != _password.text
                              ? l.registerConfirmMismatch
                              : null,
                        ),
                        const SpaceHeight(24),
                        LoadingButton(
                          loading: loading,
                          onPressed: locked ? null : _submit,
                          label: isCoolingDown
                              ? l.authRetryIn(cooldownSeconds)
                              : l.actionRegister,
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
