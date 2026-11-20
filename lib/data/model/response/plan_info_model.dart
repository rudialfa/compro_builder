import 'dart:convert';

import 'package:compro_builder/core/utils/format.dart';

/// Satu baris batas paket yang siap tampil. [value] null = tanpa batas.
class PlanLimit {
  final String key;
  final String label;
  final String? value;
  const PlanLimit(this.key, this.label, this.value);
}

// ─── RESPONSE MODEL: PlanInfoModel ───────────────────────────────────────────
/// Isi GET /{slug}/manage/plan:
/// {data: {code, name, level, expires_at, price, limits{...}, upgrade_url}}.
class PlanInfoModel {
  final String code;
  final String name;
  final int level;
  final DateTime? expiresAt;
  final int? price;

  /// Mentah dari server (mis. max_sections, contact_form, custom_domain).
  final Map<String, Object?> limits;
  final String? upgradeUrl;

  const PlanInfoModel({
    required this.code,
    required this.name,
    this.level = 0,
    this.expiresAt,
    this.price,
    this.limits = const {},
    this.upgradeUrl,
  });

  factory PlanInfoModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) throw const FormatException('Data paket tidak valid');
    final inner = decoded['data'];
    return PlanInfoModel.fromMap(
      Map<String, dynamic>.from(inner is Map ? inner : decoded),
    );
  }

  factory PlanInfoModel.fromMap(Map<String, dynamic> json) {
    final name = (json['name'] ?? json['code'])?.toString() ?? '';
    if (name.isEmpty) throw const FormatException('Paket tanpa nama');
    final price = json['price'];
    final limits = json['limits'];
    final url = json['upgrade_url']?.toString();
    return PlanInfoModel(
      code: (json['code'] ?? '').toString(),
      name: name,
      level: json['level'] is num ? (json['level'] as num).toInt() : 0,
      expiresAt: DateTime.tryParse('${json['expires_at'] ?? ''}')?.toLocal(),
      price: price is num
          ? price.round()
          : (price is String ? double.tryParse(price.trim())?.round() : null),
      limits: limits is Map ? Map<String, Object?>.from(limits) : const {},
      upgradeUrl: (url == null || url.isEmpty) ? null : url,
    );
  }

  Map<String, dynamic> toMap() => {
    'code': code,
    'name': name,
    'level': level,
    'expires_at': expiresAt?.toUtc().toIso8601String(),
    'price': price,
    'limits': limits,
    'upgrade_url': upgradeUrl,
  };

  String toJson() => jsonEncode({'data': toMap()});

  /// Sisa hari (tanggal saja). Negatif = sudah berakhir; null = tanpa batas waktu.
  int? daysLeft(DateTime now) {
    final e = expiresAt;
    if (e == null) return null;
    return DateTime(
      e.year,
      e.month,
      e.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  String? get priceLabel => price == null ? null : formatRupiah(price!);

  static const _labels = {
    'max_sections': 'Jumlah section',
    'max_products': 'Jumlah produk',
    'max_features': 'Jumlah fitur',
    'max_kb': 'Ukuran gambar maks.',
    'contact_form': 'Form kontak',
    'remove_branding': 'Hapus branding',
    'custom_domain': 'Domain sendiri',
    'multipage': 'Mode multi-halaman',
  };

  static String _humanize(String key) {
    final s = key.replaceAll('_', ' ').trim();
    return s.isEmpty ? key : s[0].toUpperCase() + s.substring(1);
  }

  static String? _fmt(String key, Object? v) {
    if (v == null) return null;
    if (v is bool) return v ? 'Ya' : 'Tidak';
    if (v is num) {
      if (key.toLowerCase().contains('kb')) {
        return v >= 1024 && v % 1024 == 0
            ? '${(v / 1024).round()} MB'
            : '${v.round()} KB';
      }
      return '${v.round()}';
    }
    return '$v';
  }

  /// Baris batas untuk UI; nilai bersarang dilewati.
  List<PlanLimit> get limitRows => [
    for (final e in limits.entries)
      if (e.value is! Map && e.value is! List)
        PlanLimit(
          e.key,
          _labels[e.key] ?? _humanize(e.key),
          _fmt(e.key, e.value),
        ),
  ];
}
