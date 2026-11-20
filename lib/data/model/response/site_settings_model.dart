import 'dart:convert';

/// Tautan sosial yang diterima backend (config/compro.php). Urutan = urutan form.
const kSocialLabels = <String, String>{
  'instagram': 'Instagram',
  'facebook': 'Facebook',
  'tiktok': 'TikTok',
  'youtube': 'YouTube',
  'x': 'X (Twitter)',
  'linkedin': 'LinkedIn',
};

String _s(Object? v) => v == null ? '' : v.toString();

bool _b(Object? v) => switch (v) {
  bool b => b,
  num n => n != 0,
  String s => s == '1' || s == 'true',
  _ => false,
};

String? _nullable(Object? v) {
  final s = _s(v).trim();
  return s.isEmpty ? null : s;
}

/// Warna tema situs (hanya baca; backend belum menyediakan ubah tema).
class SiteThemeModel {
  final String code;
  final String brand;
  final String bright;
  final String soft;
  const SiteThemeModel({
    this.code = '',
    this.brand = '',
    this.bright = '',
    this.soft = '',
  });

  factory SiteThemeModel.fromMap(Object? raw) {
    if (raw is! Map) return SiteThemeModel(code: _s(raw));
    return SiteThemeModel(
      code: _s(raw['code']),
      brand: _s(raw['brand']),
      bright: _s(raw['bright']),
      soft: _s(raw['soft']),
    );
  }

  Map<String, dynamic> toMap() => {
    'code': code,
    'brand': brand,
    'bright': bright,
    'soft': soft,
  };
}

// ─── RESPONSE MODEL: SiteSettingsModel ───────────────────────────────────────
/// Isi GET /{slug}/manage/settings (juga balasan PUT|POST):
/// {data: {name, slug, url, logo, favicon, plan, theme{code,brand,bright,soft},
/// seo{title,description}, socials{code:{label,url}}, notify_email,
/// multipage (pilihan pemilik), multipage_available (paket mengizinkan)}}.
class SiteSettingsModel {
  final String name;
  final String slug;
  final String url;
  final String? logo;
  final String? favicon;
  final String plan;
  final SiteThemeModel theme;
  final String seoTitle;
  final String seoDescription;
  final String notifyEmail;

  /// Pilihan pemilik (settings.multipage). Yang berlaku di situs = [multipage] DAN [multipageAvailable].
  final bool multipage;
  final bool multipageAvailable;

  /// code -> url (hanya yang terisi).
  final Map<String, String> socials;

  const SiteSettingsModel({
    required this.name,
    this.slug = '',
    this.url = '',
    this.logo,
    this.favicon,
    this.plan = '',
    this.theme = const SiteThemeModel(),
    this.seoTitle = '',
    this.seoDescription = '',
    this.notifyEmail = '',
    this.multipage = false,
    this.multipageAvailable = false,
    this.socials = const {},
  });

  factory SiteSettingsModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) throw const FormatException('Pengaturan tidak valid');
    final inner = decoded['data'];
    return SiteSettingsModel.fromMap(
      Map<String, dynamic>.from(inner is Map ? inner : decoded),
    );
  }

  factory SiteSettingsModel.fromMap(Map<String, dynamic> json) {
    final seo = json['seo'] is Map ? json['seo'] as Map : const {};
    final rawSocials = json['socials'] is Map
        ? json['socials'] as Map
        : const {};
    final socials = <String, String>{};
    for (final e in rawSocials.entries) {
      final v = e.value;
      final url = v is Map ? _nullable(v['url']) : _nullable(v);
      if (url != null) socials['${e.key}'] = url;
    }
    return SiteSettingsModel(
      name: _s(json['name']),
      slug: _s(json['slug']),
      url: _s(json['url']),
      logo: _nullable(json['logo']),
      favicon: _nullable(json['favicon']),
      plan: _s(
        json['plan'] is Map ? (json['plan'] as Map)['code'] : json['plan'],
      ),
      theme: SiteThemeModel.fromMap(json['theme']),
      seoTitle: _s(seo['title']),
      seoDescription: _s(seo['description']),
      notifyEmail: _s(json['notify_email']),
      multipage: _b(json['multipage']),
      multipageAvailable: _b(json['multipage_available']),
      socials: socials,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'slug': slug,
    'url': url,
    'logo': logo,
    'favicon': favicon,
    'plan': plan,
    'theme': theme.toMap(),
    'seo': {'title': seoTitle, 'description': seoDescription},
    'socials': {
      for (final e in socials.entries) e.key: {'url': e.value},
    },
    'notify_email': notifyEmail,
    'multipage': multipage,
    'multipage_available': multipageAvailable,
  };

  String toJson() => jsonEncode({'data': toMap()});
}
