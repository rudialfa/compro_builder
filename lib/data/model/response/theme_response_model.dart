import 'dart:convert';

String _toStr(Object? v) => v == null ? '' : v.toString();

// ─── RESPONSE MODEL: ThemeOptionModel ────────────────────────────────────────
/// Satu pilihan warna situs: {code, name, brand, bright, soft}.
/// Dipakai di daftar tema, onboarding, dan `theme` pada tenantSummary.
class ThemeOptionModel {
  final String code;
  final String name;
  final String brand;
  final String bright;
  final String soft;

  const ThemeOptionModel({
    this.code = '',
    this.name = '',
    this.brand = '',
    this.bright = '',
    this.soft = '',
  });

  factory ThemeOptionModel.fromMap(Map<String, dynamic> json) =>
      ThemeOptionModel(
        code: _toStr(json['code']),
        name: _toStr(json['name']),
        brand: _toStr(json['brand']),
        bright: _toStr(json['bright']),
        soft: _toStr(json['soft']),
      );

  /// Daftar dari JSON; entri tanpa `code` dilewati, bukan-list = kosong.
  static List<ThemeOptionModel> listFrom(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ThemeOptionModel.fromMap(e.cast<String, dynamic>()))
        .where((t) => t.code.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'brand': brand,
        'bright': bright,
        'soft': soft,
      };
}

// ─── RESPONSE MODEL: ThemesResponseModel ─────────────────────────────────────
/// GET /{slug}/manage/themes -> {data: {current, themes: [ThemeOptionModel]}}.
class ThemesResponseModel {
  /// Kode tema yang sedang dipakai situs.
  final String current;
  final List<ThemeOptionModel> themes;

  const ThemesResponseModel({this.current = '', this.themes = const []});

  factory ThemesResponseModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) throw const FormatException('Respons tema tidak valid');
    return ThemesResponseModel.fromMap(Map<String, dynamic>.from(decoded));
  }

  factory ThemesResponseModel.fromMap(Map<String, dynamic> json) {
    final inner = json['data'];
    final node = inner is Map ? Map<String, dynamic>.from(inner) : json;
    if (node['themes'] is! List) {
      throw const FormatException('Daftar tema tidak valid');
    }
    return ThemesResponseModel(
      current: _toStr(node['current']),
      themes: ThemeOptionModel.listFrom(node['themes']),
    );
  }
}
