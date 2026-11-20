import 'dart:typed_data';

import 'package:compro_builder/data/model/request/section_payload.dart';
import 'package:compro_builder/data/model/response/site_settings_model.dart';

/// Perubahan pengaturan yang akan dikirim. Backend (SiteSettings::apply)
/// hanya mengubah kunci yang dikirim, DENGAN SATU PENGECUALIAN: `socials`
/// menggantikan seluruh daftar tautan. Karena itu bila satu tautan berubah,
/// seluruh peta tautan dikirim.
///
/// Kunci mengikuti validasi backend: `name`, `seo_title`, `seo_description`,
/// `notify_email` (datar, bukan bersarang `seo.title`), `socials[code]`,
/// `logo`/`favicon` (berkas), `logo_remove`/`favicon_remove`, dan `multipage`
/// (boolean; server menolak menyalakannya bila paket tidak mengizinkan).
class SettingsChangesModel {
  final Map<String, String> texts;

  /// Peta tautan LENGKAP (null = tautan tidak berubah).
  final Map<String, String>? socials;
  final Uint8List? logo;
  final Uint8List? favicon;
  final bool removeLogo;
  final bool removeFavicon;

  /// Nilai baru toggle multi-halaman (null = tidak berubah).
  final bool? multipage;

  const SettingsChangesModel({
    this.texts = const {},
    this.socials,
    this.logo,
    this.favicon,
    this.removeLogo = false,
    this.removeFavicon = false,
    this.multipage,
  });

  /// Membandingkan isian [edited] (setelah trim) dengan [original].
  /// [edited] berisi kunci: name, seo_title, seo_description, notify_email,
  /// dan `socials.<code>`.
  factory SettingsChangesModel.diff(
    SiteSettingsModel original,
    Map<String, String> edited, {
    Uint8List? logo,
    Uint8List? favicon,
    bool removeLogo = false,
    bool removeFavicon = false,
    bool? multipage,
  }) {
    final before = <String, String>{
      'name': original.name,
      'seo_title': original.seoTitle,
      'seo_description': original.seoDescription,
      'notify_email': original.notifyEmail,
    };
    final texts = <String, String>{};
    for (final key in before.keys) {
      final v = edited[key];
      if (v != null && v.trim() != before[key]!.trim()) texts[key] = v.trim();
    }

    final nextSocials = <String, String>{};
    var socialsChanged = false;
    for (final code in kSocialLabels.keys) {
      final v = (edited['socials.$code'] ?? original.socials[code] ?? '')
          .trim();
      if (v.isNotEmpty) nextSocials[code] = v;
      if (v != (original.socials[code] ?? '').trim()) socialsChanged = true;
    }

    return SettingsChangesModel(
      texts: texts,
      socials: socialsChanged ? nextSocials : null,
      logo: logo,
      favicon: favicon,
      removeLogo: removeLogo && logo == null,
      removeFavicon: removeFavicon && favicon == null,
      multipage: (multipage != null && multipage != original.multipage)
          ? multipage
          : null,
    );
  }

  bool get touchesFiles =>
      logo != null || favicon != null || removeLogo || removeFavicon;

  bool get isEmpty =>
      texts.isEmpty && socials == null && !touchesFiles && multipage == null;

  /// Payload bersarang; berkas dibungkus [UploadFile] (lihat flattenPayload).
  Map<String, dynamic> toMap() => {
    ...texts,
    if (socials != null) 'socials': socials,
    if (multipage != null) 'multipage': multipage,
    if (logo != null) 'logo': UploadFile(logo!, 'image.jpg'),
    if (favicon != null) 'favicon': UploadFile(favicon!, 'image.jpg'),
    if (removeLogo) 'logo_remove': 1,
    if (removeFavicon) 'favicon_remove': 1,
  };
}
