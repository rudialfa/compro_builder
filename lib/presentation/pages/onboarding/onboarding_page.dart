import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/data/datasources/onboarding_remote_datasource.dart';
import 'package:compro_builder/data/model/request/onboarding_request_model.dart';
import 'package:compro_builder/data/model/response/onboarding_response_model.dart';
import 'package:compro_builder/presentation/bloc/onboarding/onboarding_bloc.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pengaturan awal situs (3 langkah: usaha, kontak, warna) dengan opsi lewati.
/// Menutup dengan `true` bila isian tersimpan (section hero/kontak berubah di
/// server), `false` bila dilewati/ditutup; pemanggil memuat ulang tab Section.
class OnboardingPage extends StatelessWidget {
  final String slug;
  const OnboardingPage({super.key, required this.slug});

  static Future<bool> open(BuildContext context, {required String slug}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OnboardingPage(slug: slug),
      ),
    );
    return saved ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          OnboardingBloc(OnboardingRemoteDatasource(), slug: slug)
            ..add(const OnboardingEvent.load()),
      child: const _OnboardingView(),
    );
  }
}

const _lastStep = 2;

// Sama dengan aturan tipe `phone` di server (SectionManager).
final _phoneRe = RegExp(r'^\+?[0-9][0-9\s\-]{6,18}$');

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView>
    with RateLimitMixin<_OnboardingView> {
  final _name = TextEditingController();
  final _subtitle = TextEditingController();
  final _whatsapp = TextEditingController();
  final _errors = <String, String>{};

  int _step = 0;
  String _theme = '';
  String? _banner;
  bool _filled = false;
  bool _checkedNeeded = false;

  @override
  void dispose() {
    _name.dispose();
    _subtitle.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  /// Isi awal dari server (sekali). Tidak memanggil setState: dipakai di build.
  void _fill(OnboardingResponseModel data) {
    _filled = true;
    _name.text = data.values.name;
    _subtitle.text = data.values.subtitle;
    _whatsapp.text = data.values.whatsapp;
    final known = data.themes.any((t) => t.code == data.values.theme);
    _theme = known
        ? data.values.theme
        : (data.themes.isEmpty ? '' : data.themes.first.code);
  }

  int _stepOfField(String field) => switch (field) {
    'name' || 'subtitle' => 0,
    'whatsapp' => 1,
    _ => 2,
  };

  void _onState(BuildContext context, OnboardingState state) {
    final data = state.whenOrNull(loaded: (d) => d);
    if (data == null) return;

    // Sudah selesai/dilewati di tempat lain (mis. web): tutup dan segarkan.
    if (!_checkedNeeded) {
      _checkedNeeded = true;
      if (!data.data.needed) {
        context.read<SitesBloc>().add(const SitesEvent.refresh());
        Navigator.of(context).pop(false);
        return;
      }
    }

    final done = data.doneTenant;
    if (done != null) {
      context.read<SitesBloc>().add(SitesEvent.tenantUpdated(done));
      _snack(
        data.wasSkipped
            ? context.l10n.onboardingSkipped
            : context.l10n.onboardingDone,
        kind: ToastKind.success,
      );
      Navigator.of(context).pop(!data.wasSkipped);
      return;
    }

    final failure = data.failure;
    if (failure == null) return;
    setState(() {
      _errors.clear();
      _banner = failure.message;
      if (failure.isValidation) {
        var firstStep = _lastStep;
        for (final e in failure.fieldErrors.entries) {
          if (e.value.isEmpty) continue;
          _errors[e.key] = e.value.first;
          final s = _stepOfField(e.key);
          if (s < firstStep) firstStep = s;
        }
        // Galat di luar field (kunci `onboarding`) tetap tampil sebagai banner.
        if (_errors.keys.any(
          (k) => const ['name', 'subtitle', 'whatsapp', 'theme'].contains(k),
        )) {
          _step = firstStep;
        }
      }
    });
    if (failure.isRateLimited) startCooldown(failure.retryAfter);
  }

  /// Validasi inline satu langkah; true bila lolos.
  bool _validate(int step) {
    final l = context.l10n;
    final errors = <String, String>{};
    switch (step) {
      case 0:
        final name = _name.text.trim();
        if (name.isEmpty) {
          errors['name'] = l.validationRequired;
        } else if (name.length > 100) {
          errors['name'] = l.validationMaxLength(100);
        }
        if (_subtitle.text.trim().length > 255) {
          errors['subtitle'] = l.validationMaxLength(255);
        }
      case 1:
        final wa = _whatsapp.text.trim();
        if (wa.isNotEmpty && !_phoneRe.hasMatch(wa)) {
          errors['whatsapp'] = l.onboardingWhatsappInvalid;
        }
      default:
        if (_theme.isEmpty) errors['theme'] = l.validationRequired;
    }
    setState(() {
      for (final k in const ['name', 'subtitle', 'whatsapp', 'theme']) {
        if (_stepOfField(k) == step) _errors.remove(k);
      }
      _errors.addAll(errors);
      _banner = null;
    });
    return errors.isEmpty;
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (!_validate(_step)) return;
    if (_step < _lastStep) {
      setState(() => _step++);
      return;
    }
    // Langkah terakhir: pastikan semua langkah lolos sebelum kirim.
    for (var s = 0; s < _lastStep; s++) {
      if (!_validate(s)) {
        setState(() => _step = s);
        return;
      }
    }
    context.read<OnboardingBloc>().add(
      OnboardingEvent.submit(
        OnboardingRequestModel(
          name: _name.text,
          subtitle: _subtitle.text,
          whatsapp: _whatsapp.text,
          theme: _theme,
        ),
      ),
    );
  }

  Future<void> _confirmSkip() async {
    final l = context.l10n;
    final bloc = context.read<OnboardingBloc>();
    final ok = await showConfirmDialog(
      context,
      title: l.onboardingSkipTitle,
      message: l.onboardingSkipMessage,
      confirmLabel: l.onboardingSkip,
    );
    if (ok && !bloc.isClosed) bloc.add(const OnboardingEvent.skip());
  }

  Widget _field(
    String key,
    TextEditingController controller,
    String label, {
    int? maxLength,
    int maxLines = 1,
    TextInputType? keyboard,
    TextInputAction action = TextInputAction.next,
    TextCapitalization capitalization = TextCapitalization.none,
    String? helper,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: 1,
      keyboardType: keyboard,
      textInputAction: action,
      textCapitalization: capitalization,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
        errorText: _errors[key],
      ),
      onChanged: (_) {
        if (_errors.containsKey(key)) setState(() => _errors.remove(key));
      },
    ),
  );

  Widget _stepBody(BuildContext context, OnboardingViewData data) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    Widget head(String title, String hint) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: text.titleLarge)),
        const SizedBox(height: 4),
        Text(hint, style: text.bodyMedium),
        const SizedBox(height: 16),
      ],
    );

    return switch (_step) {
      0 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          head(l.onboardingBusinessTitle, l.onboardingBusinessHint),
          _field(
            'name',
            _name,
            l.onboardingName,
            maxLength: 100,
            capitalization: TextCapitalization.words,
          ),
          _field(
            'subtitle',
            _subtitle,
            l.onboardingSubtitle,
            maxLength: 255,
            maxLines: 3,
            helper: l.onboardingSubtitleHelp,
            action: TextInputAction.done,
          ),
        ],
      ),
      1 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          head(l.onboardingContactTitle, l.onboardingContactHint),
          _field(
            'whatsapp',
            _whatsapp,
            l.onboardingWhatsapp,
            maxLength: 30,
            keyboard: TextInputType.phone,
            action: TextInputAction.done,
            helper: l.onboardingWhatsappHelp,
          ),
        ],
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          head(l.onboardingThemeTitle, l.onboardingThemeHint),
          ThemePicker(
            themes: data.data.themes,
            selected: _theme,
            onSelect: data.isBusy
                ? null
                : (code) => setState(() {
                    _theme = code;
                    _errors.remove('theme');
                  }),
          ),
          if (_errors['theme'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errors['theme']!,
                style: text.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: _onState,
      builder: (context, state) {
        final data = state.whenOrNull(loaded: (d) => d);
        if (data != null && !_filled) _fill(data.data);
        final busy = data?.isBusy ?? false;
        final locked = busy || isCoolingDown;

        return PopScope(
          // Langkah > 1: tombol kembali sistem mundur satu langkah.
          canPop: _step == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) setState(() => _step--);
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(l.onboardingTitle),
              actions: [
                if (data != null)
                  TextButton(
                    onPressed: busy ? null : _confirmSkip,
                    child: Text(l.onboardingSkip),
                  ),
              ],
            ),
            body: state.when(
              initial: () => const LoadingView(),
              loading: () => const LoadingView(),
              error: (failure) => ErrorView(
                message: failure.message,
                onRetry: () => context.read<OnboardingBloc>().add(
                  const OnboardingEvent.load(),
                ),
              ),
              loaded: (d) => SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.onboardingStepOf(_step + 1, _lastStep + 1),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: (_step + 1) / (_lastStep + 1),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          if (_banner != null) ...[
                            _ErrorBox(_banner!),
                            const SizedBox(height: 16),
                          ],
                          _stepBody(context, d),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          if (_step > 0) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () => setState(() => _step--),
                                child: Text(l.actionBack),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: FilledButton(
                              onPressed: locked ? null : _next,
                              child: busy
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      isCoolingDown
                                          ? l.authRetryIn(cooldownSeconds)
                                          : (_step == _lastStep
                                                ? l.onboardingFinish
                                                : l.actionNext),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(Icons.error_outline, color: scheme.onErrorContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
