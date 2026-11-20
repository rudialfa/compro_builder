import 'dart:convert';

import 'package:compro_builder/data/model/response/tenant_model.dart';

String _toStr(Object? v) => v == null ? '' : v.toString();

/// `state` hasil cek slug dari server.
enum SlugCheckStatus {
  empty,
  invalid,
  same,
  reserved,
  taken,
  available,
  unknown,
}

// ─── RESPONSE MODEL: SlugCheckModel ──────────────────────────────────────────
/// GET /{slug}/manage/slug/check?slug=... ->
/// {data: {ok, state, message, suggestion, slug}}. Selalu 200; hasilnya di `ok`.
class SlugCheckModel {
  final bool ok;
  final SlugCheckStatus status;
  final String message;

  /// Usulan alamat lain bila `taken`.
  final String? suggestion;

  /// Slug yang sudah dinormalisasi server (huruf kecil, tanpa spasi tepi).
  final String slug;

  const SlugCheckModel({
    this.ok = false,
    this.status = SlugCheckStatus.unknown,
    this.message = '',
    this.suggestion,
    this.slug = '',
  });

  factory SlugCheckModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) throw const FormatException('Respons tidak valid');
    return SlugCheckModel.fromMap(Map<String, dynamic>.from(decoded));
  }

  factory SlugCheckModel.fromMap(Map<String, dynamic> json) {
    final inner = json['data'];
    final node = inner is Map ? Map<String, dynamic>.from(inner) : json;
    final rawSuggestion = node['suggestion'];
    return SlugCheckModel(
      ok: node['ok'] == true,
      status: switch (node['state']) {
        'empty' => SlugCheckStatus.empty,
        'invalid' => SlugCheckStatus.invalid,
        'same' => SlugCheckStatus.same,
        'reserved' => SlugCheckStatus.reserved,
        'taken' => SlugCheckStatus.taken,
        'available' => SlugCheckStatus.available,
        _ => SlugCheckStatus.unknown,
      },
      message: _toStr(node['message']),
      suggestion: (rawSuggestion is String && rawSuggestion.isNotEmpty)
          ? rawSuggestion
          : null,
      slug: _toStr(node['slug']),
    );
  }
}

// ─── RESPONSE MODEL: SlugChangeResponseModel ─────────────────────────────────
/// PUT /{slug}/manage/slug -> {data: tenantSummary, old_slug}.
class SlugChangeResponseModel {
  final TenantModel tenant;
  final String oldSlug;

  const SlugChangeResponseModel({required this.tenant, this.oldSlug = ''});

  factory SlugChangeResponseModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) throw const FormatException('Respons tidak valid');
    final inner = decoded['data'];
    if (inner is! Map) throw const FormatException('Respons tidak valid');
    final tenant = TenantModel.fromMap(Map<String, dynamic>.from(inner));
    if (tenant.slug.isEmpty) throw const FormatException('Situs tidak valid');
    return SlugChangeResponseModel(
      tenant: tenant,
      oldSlug: _toStr(decoded['old_slug']),
    );
  }
}
