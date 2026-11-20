import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/media/image_service.dart';
import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:compro_builder/core/utils/url.dart';
import 'package:compro_builder/data/datasources/settings_remote_datasource.dart';
import 'package:compro_builder/data/model/request/settings_changes_model.dart';
import 'package:compro_builder/data/model/response/site_settings_model.dart';
import 'package:compro_builder/presentation/bloc/settings/settings_bloc.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/widgets/gradient_card.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pengaturan situs: nama, logo/favicon, SEO, email notifikasi, tautan sosial,
/// mode multi-halaman.
class SettingsPage extends StatelessWidget {
  final String slug;
  const SettingsPage({super.key, required this.slug});

  static Future<void> open(BuildContext context, {required String slug}) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => SettingsPage(slug: slug)));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SettingsBloc(SettingsRemoteDatasource(), slug: slug)
            ..add(const SettingsEvent.load()),
      child: const _SettingsView(),
    );
  }
}

/// Pilihan gambar baru / hapus untuk logo atau favicon.
class _ImagePick {
  Uint8List? bytes;
  bool removed = false;
}

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  final _controllers = <String, TextEditingController>{};
  final _logo = _ImagePick();
  final _favicon = _ImagePick();
  final _errors = <String, String>{};
  bool _multipage = false;
  String? _banner;
  bool _blocked = false;
  Timer? _unblock;

  @override
  void dispose() {
    _unblock?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _c(String key) =>
      _controllers.putIfAbsent(key, TextEditingController.new);

  /// Mengisi (ulang) isian dari data server.
  void _fill(SiteSettingsModel s) {
    _c('name').text = s.name;
    _c('seo_title').text = s.seoTitle;
    _c('seo_description').text = s.seoDescription;
    _c('notify_email').text = s.notifyEmail;
    _multipage = s.multipage;
    for (final code in kSocialLabels.keys) {
      _c('socials.$code').text = s.socials[code] ?? '';
    }
  }

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  void _onState(BuildContext context, SettingsState state) {
    final data = state.whenOrNull(loaded: (d) => d);
    if (data == null) return;

    if (data.saved) {
      setState(() {
        _fill(data.settings);
        _logo
          ..bytes = null
          ..removed = false;
        _favicon
          ..bytes = null
          ..removed = false;
        _errors.clear();
        _banner = null;
      });
      _snack(context.l10n.saved, kind: ToastKind.success);
      // Nama situs bisa berubah: segarkan daftar situs.
      context.read<SitesBloc>().add(const SitesEvent.refresh());
      return;
    }

    final failure = data.saveFailure;
    if (failure == null) return;
    setState(() {
      _errors.clear();
      if (failure.isValidation) {
        for (final e in failure.fieldErrors.entries) {
          if (e.value.isNotEmpty) _errors[e.key] = e.value.first;
        }
      }
      _banner = failure.message;
      if (failure.isRateLimited) {
        _blocked = true;
        _unblock?.cancel();
        _unblock = Timer(Duration(seconds: failure.retryAfter ?? 30), () {
          if (mounted) setState(() => _blocked = false);
        });
      }
    });
  }

  void _save(SiteSettingsModel original) {
    final l = context.l10n;
    FocusScope.of(context).unfocus();
    final edited = {
      for (final e in _controllers.entries) e.key: e.value.text.trim(),
    };

    final errors = <String, String>{};
    if ((edited['name'] ?? '').isEmpty) errors['name'] = l.validationRequired;
    final email = edited['notify_email'] ?? '';
    if (email.isNotEmpty && !_emailRe.hasMatch(email)) {
      errors['notify_email'] = l.validationEmail;
    }
    if (errors.isNotEmpty) {
      setState(() {
        _errors
          ..clear()
          ..addAll(errors);
        _banner = null;
      });
      return;
    }

    final changes = SettingsChangesModel.diff(
      original,
      edited,
      logo: _logo.bytes,
      favicon: _favicon.bytes,
      removeLogo: _logo.removed,
      removeFavicon: _favicon.removed,
      // Paket yang tidak mengizinkan: toggle terkunci, jadi tidak ada yang dikirim.
      multipage: original.multipageAvailable ? _multipage : null,
    );
    if (changes.isEmpty) {
      _snack(l.settingsNoChanges);
      return;
    }
    setState(() {
      _errors.clear();
      _banner = null;
    });
    context.read<SettingsBloc>().add(SettingsEvent.save(changes));
  }

  Future<void> _pickImage(_ImagePick target) async {
    final l = context.l10n;
    final camera = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.pickCamera),
              onTap: () => Navigator.pop(sheetContext, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.pickGallery),
              onTap: () => Navigator.pop(sheetContext, false),
            ),
          ],
        ),
      ),
    );
    if (camera == null) return;
    const maxKb = 1024;
    final bytes = await ImageService().pick(camera: camera, maxKb: maxKb);
    if (bytes == null || !mounted) return;
    if (bytes.lengthInBytes > maxKb * 1024) {
      _snack(l.imageTooLarge(maxKb), kind: ToastKind.error);
      return;
    }
    setState(() {
      target
        ..bytes = bytes
        ..removed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: _onState,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(l.settingsTitle)),
        body: state.when(
          initial: () => const LoadingView(),
          loading: () => const LoadingView(),
          error: (failure) => ErrorView(
            message: failure.message,
            onRetry: () =>
                context.read<SettingsBloc>().add(const SettingsEvent.load()),
          ),
          loaded: (data) {
            if (_controllers.isEmpty) _fill(data.settings);
            return _buildForm(context, data);
          },
        ),
      ),
    );
  }

  /// Avatar logo di kartu hero: menampilkan logo saat ini dan membuka pemilih
  /// gambar yang sama dengan tombol "Pilih gambar" di bawah.
  Widget _logoAvatar(SiteSettingsModel s) {
    final l = context.l10n;
    Widget inner;
    if (_logo.bytes != null) {
      inner = Image.memory(_logo.bytes!, fit: BoxFit.cover);
    } else if (s.logo != null && !_logo.removed) {
      inner = CachedNetworkImage(
        imageUrl: resolveUrl(s.logo!),
        fit: BoxFit.cover,
        placeholder: (_, _) => const SizedBox.shrink(),
        errorWidget: (_, _, _) =>
            const Icon(Icons.storefront_outlined, color: Colors.white, size: 28),
      );
    } else {
      inner = const Icon(Icons.storefront_outlined, color: Colors.white, size: 28);
    }
    return Semantics(
      button: true,
      label: l.settingsLogo,
      excludeSemantics: true,
      onTap: () => _pickImage(_logo),
      child: GestureDetector(
        onTap: () => _pickImage(_logo),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: SizedBox.expand(child: Center(child: inner)),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppTheme.kunyit,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    size: 13,
                    color: AppTheme.indigo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, SettingsViewData data) {
    final l = context.l10n;
    final s = data.settings;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget field(
      String key,
      String label, {
      int? maxLength,
      int maxLines = 1,
      TextInputType? keyboard,
      IconData? icon,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _c(key),
        maxLength: maxLength,
        maxLines: maxLines,
        minLines: 1,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          errorText: _errors[key],
          prefixIcon: icon == null ? null : Icon(icon, size: 20),
        ),
        onChanged: (_) {
          if (_errors.containsKey(key)) setState(() => _errors.remove(key));
        },
      ),
    );

    /// Kelompok isian dalam satu kartu dengan kepala ikon + judul.
    Widget group(
      IconData icon,
      Color color,
      String title,
      List<Widget> children, {
      Color? foreground,
    }) => AppSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                IconChip(
                  icon: icon,
                  color: color,
                  foreground: foreground,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );

    // Pratinjau hasil pencarian: mengikuti isian judul/deskripsi SEO.
    final seoPreview = AnimatedBuilder(
      animation: Listenable.merge([_c('seo_title'), _c('seo_description')]),
      builder: (context, _) {
        final title = _c('seo_title').text.trim();
        final desc = _c('seo_description').text.trim();
        if (title.isEmpty && desc.isEmpty) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(color: scheme.primary),
                ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  desc,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (_banner != null) ...[
                  _ErrorBox(_banner!),
                  const SizedBox(height: 12),
                ],
                GradientCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _logoAvatar(s),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _c('name'),
                          builder: (context, v, _) => Text(
                            v.text.trim().isEmpty ? s.name : v.text.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                group(Icons.storefront_outlined, AppTheme.blue, l.settingsGeneral, [
                  field(
                    'name',
                    l.settingsSiteName,
                    maxLength: 100,
                    icon: Icons.storefront_outlined,
                  ),
                  _ImageTile(
                    label: l.settingsLogo,
                    existingUrl: s.logo,
                    pick: _logo,
                    error: _errors['logo'],
                    onPick: () => _pickImage(_logo),
                    onRemove: () => setState(() {
                      _logo
                        ..bytes = null
                        ..removed = true;
                    }),
                  ),
                  const SizedBox(height: 12),
                  _ImageTile(
                    label: l.settingsFavicon,
                    existingUrl: s.favicon,
                    pick: _favicon,
                    error: _errors['favicon'],
                    onPick: () => _pickImage(_favicon),
                    onRemove: () => setState(() {
                      _favicon
                        ..bytes = null
                        ..removed = true;
                    }),
                  ),
                ]),
                const SizedBox(height: 12),
                group(
                  Icons.search,
                  AppTheme.teal,
                  l.settingsSeo,
                  [
                    seoPreview,
                    field(
                      'seo_title',
                      l.settingsSeoTitle,
                      maxLength: 70,
                      icon: Icons.title,
                    ),
                    field(
                      'seo_description',
                      l.settingsSeoDescription,
                      maxLength: 160,
                      maxLines: 3,
                    ),
                  ],
                  foreground: AppTheme.tealDeep,
                ),
                const SizedBox(height: 12),
                group(
                  Icons.notifications_none,
                  AppTheme.kunyit,
                  l.settingsNotify,
                  [
                    field(
                      'notify_email',
                      l.settingsNotifyEmail,
                      maxLength: 150,
                      keyboard: TextInputType.emailAddress,
                      icon: Icons.mail_outline,
                    ),
                  ],
                  foreground: AppTheme.kunyitDeep,
                ),
                const SizedBox(height: 12),
                group(Icons.share_outlined, AppTheme.rose, l.settingsSocial, [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      l.settingsSocialHint,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final e in kSocialLabels.entries)
                    field(
                      'socials.${e.key}',
                      e.value,
                      maxLength: 200,
                      keyboard: TextInputType.url,
                      icon: Icons.link,
                    ),
                ]),
                const SizedBox(height: 12),
                group(Icons.palette_outlined, AppTheme.violet, l.settingsDisplay, [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.settingsMultipage),
                    subtitle: Text(
                      s.multipageAvailable
                          ? l.settingsMultipageHint
                          : l.settingsMultipageLocked,
                    ),
                    value: s.multipageAvailable && _multipage,
                    onChanged: s.multipageAvailable
                        ? (v) => setState(() => _multipage = v)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    header: true,
                    child: Text(l.settingsTheme, style: text.labelLarge),
                  ),
                  const SizedBox(height: 10),
                  _ThemeChips(theme: s.theme),
                ]),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Bilah simpan: lembar putih dengan sudut atas membulat.
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? scheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusSheet),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.indigo.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data.isSaving)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(),
                  ),
                FilledButton.icon(
                  onPressed: (data.isSaving || _blocked) ? null : () => _save(s),
                  icon: const Icon(Icons.check),
                  label: Text(l.actionSave),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String label;
  final String? existingUrl;
  final _ImagePick pick;
  final String? error;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  const _ImageTile({
    required this.label,
    required this.existingUrl,
    required this.pick,
    required this.error,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasImage =
        pick.bytes != null || (existingUrl != null && !pick.removed);

    Widget preview;
    if (pick.bytes != null) {
      preview = Image.memory(pick.bytes!, fit: BoxFit.contain);
    } else if (existingUrl != null && !pick.removed) {
      preview = CachedNetworkImage(
        imageUrl: resolveUrl(existingUrl!),
        fit: BoxFit.contain,
        placeholder: (_, _) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (_, _, _) =>
            const Center(child: Icon(Icons.broken_image_outlined, size: 32)),
      );
    } else {
      preview = Center(
        child: Icon(Icons.image_outlined, size: 32, color: scheme.outline),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Semantics(
          image: true,
          label: label,
          child: Container(
            height: 96,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: error != null ? Border.all(color: scheme.error) : null,
            ),
            child: preview,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: onPick,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(l.chooseImage),
            ),
            if (hasImage)
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                label: Text(l.removeImage),
              ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error!, style: TextStyle(color: scheme.error)),
          ),
      ],
    );
  }
}

/// Warna tema (hanya baca; backend belum menyediakan ubah tema lewat API).
class _ThemeChips extends StatelessWidget {
  final SiteThemeModel theme;
  const _ThemeChips({required this.theme});

  static Color? _hex(String v) {
    final m = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(v.trim());
    return m == null
        ? null
        : Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final entries = [
      (l.themeBrand, _hex(theme.brand)),
      (l.themeBright, _hex(theme.bright)),
      (l.themeSoft, _hex(theme.soft)),
    ];
    return Row(
      children: [
        for (final (label, color) in entries)
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color ?? Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
      ],
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
          borderRadius: BorderRadius.circular(AppTheme.radiusTile),
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
