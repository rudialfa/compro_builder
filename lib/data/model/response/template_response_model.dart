import 'dart:convert';

String _toStr(Object? v) => v == null ? '' : v.toString();

int? _toInt(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

// ─── RESPONSE MODEL: TemplateSummaryModel ────────────────────────────────────
/// Template yang dipakai situs di dalam tenantSummary:
/// {code, name, tier, min_level}. Null di TenantModel bila cache lama.
class TemplateSummaryModel {
  final String code;
  final String name;

  /// "classic" | "medium" | "pro" (nilai lain dari server dibiarkan apa adanya).
  final String tier;
  final int minLevel;

  const TemplateSummaryModel({
    this.code = '',
    this.name = '',
    this.tier = '',
    this.minLevel = 0,
  });

  factory TemplateSummaryModel.fromMap(Map<String, dynamic> json) =>
      TemplateSummaryModel(
        code: _toStr(json['code']),
        name: _toStr(json['name']),
        tier: _toStr(json['tier']),
        minLevel: _toInt(json['min_level']) ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'tier': tier,
        'min_level': minLevel,
      };
}

Map<String, String> _palette(Object? raw) {
  if (raw is! Map) return const {};
  return {
    for (final e in raw.entries)
      if (e.value is String) e.key.toString(): e.value as String,
  };
}

// ─── RESPONSE MODEL: TemplateOptionModel ─────────────────────────────────────
/// Satu template di GET /{slug}/manage/templates. `locked` dan `active` dihitung
/// server; aplikasi tidak menghitung ulang dari level paket.
class TemplateOptionModel {
  final String code;
  final String name;
  final String tagline;
  final String bestFor;
  final String tier;
  final int minLevel;

  /// Paket minimum (plan_required): level dan nama.
  final int requiredLevel;
  final String requiredPlanName;
  final bool locked;
  final bool active;

  /// URL gambar contoh dari server (opsional). Kosong = app menggambar thumbnail sendiri.
  final String previewImage;

  /// Warna situs {brand, bright, soft} (hex) untuk thumbnail. Kosong = warna bawaan.
  final Map<String, String> palette;

  const TemplateOptionModel({
    this.code = '',
    this.name = '',
    this.tagline = '',
    this.bestFor = '',
    this.tier = '',
    this.minLevel = 0,
    this.requiredLevel = 0,
    this.requiredPlanName = '',
    this.locked = false,
    this.active = false,
    this.previewImage = '',
    this.palette = const {},
  });

  factory TemplateOptionModel.fromMap(Map<String, dynamic> json) {
    final rawPlan = json['plan_required'];
    final plan = rawPlan is Map ? rawPlan.cast<String, dynamic>() : const <String, dynamic>{};
    final minLevel = _toInt(json['min_level']) ?? 0;
    return TemplateOptionModel(
      code: _toStr(json['code']),
      name: _toStr(json['name']),
      tagline: _toStr(json['tagline']),
      bestFor: _toStr(json['best_for']),
      tier: _toStr(json['tier']),
      minLevel: minLevel,
      requiredLevel: _toInt(plan['level']) ?? minLevel,
      requiredPlanName: _toStr(plan['name']),
      locked: json['locked'] == true,
      active: json['active'] == true,
      previewImage: _toStr(json['preview_image']),
      palette: _palette(json['palette']),
    );
  }

  /// Daftar dari JSON; entri tanpa `code` dilewati, bukan-list = kosong.
  static List<TemplateOptionModel> listFrom(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => TemplateOptionModel.fromMap(e.cast<String, dynamic>()))
        .where((t) => t.code.isNotEmpty)
        .toList(growable: false);
  }
}

// ─── RESPONSE MODEL: TemplatesResponseModel ──────────────────────────────────
/// GET /{slug}/manage/templates ->
/// {data: {active, chosen, templates: [TemplateOptionModel]}}.
class TemplatesResponseModel {
  /// Template yang benar-benar dipakai situs (jatuh ke Classic bila paket turun).
  final String active;

  /// Pilihan tersimpan; null bila belum pernah memilih. Bisa beda dari [active].
  final String? chosen;
  final List<TemplateOptionModel> templates;

  const TemplatesResponseModel({
    this.active = '',
    this.chosen,
    this.templates = const [],
  });

  factory TemplatesResponseModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) throw const FormatException('Respons template tidak valid');
    return TemplatesResponseModel.fromMap(Map<String, dynamic>.from(decoded));
  }

  /// Menerima isi `data` langsung ataupun yang dibungkus `{data: ...}`.
  factory TemplatesResponseModel.fromMap(Map<String, dynamic> json) {
    final inner = json['data'];
    final node = inner is Map ? Map<String, dynamic>.from(inner) : json;
    if (node['templates'] is! List) {
      throw const FormatException('Daftar template tidak valid');
    }
    final rawChosen = node['chosen'];
    return TemplatesResponseModel(
      active: _toStr(node['active']),
      chosen: (rawChosen is String && rawChosen.isNotEmpty) ? rawChosen : null,
      templates: TemplateOptionModel.listFrom(node['templates']),
    );
  }
}

// ─── RESPONSE MODEL: PreviewLinkModel ────────────────────────────────────────
/// POST /{slug}/manage/templates/{code}/preview-link ->
/// {data: {url, expires_at}}. URL bertanda tangan, berlaku 10 menit.
class PreviewLinkModel {
  final String url;
  final DateTime? expiresAt;

  const PreviewLinkModel({required this.url, this.expiresAt});

  factory PreviewLinkModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) throw const FormatException('Respons pratinjau tidak valid');
    final inner = decoded['data'];
    final node = inner is Map ? Map<String, dynamic>.from(inner) : Map<String, dynamic>.from(decoded);
    final url = _toStr(node['url']);
    if (url.isEmpty) throw const FormatException('Tautan pratinjau kosong');
    final rawExpires = node['expires_at'];
    return PreviewLinkModel(
      url: url,
      expiresAt: rawExpires == null ? null : DateTime.tryParse('$rawExpires'),
    );
  }
}
