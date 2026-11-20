import 'dart:convert';

import 'package:compro_builder/data/model/response/domain_response_model.dart';
import 'package:compro_builder/data/model/response/template_response_model.dart';
import 'package:compro_builder/data/model/response/theme_response_model.dart';

int? _toInt(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String _toStr(Object? v) => v == null ? '' : v.toString();

// ─── RESPONSE MODEL: PlanSummaryModel ────────────────────────────────────────
/// Ringkasan paket di dalam tenantSummary: {code, name, level, expires_at}.
/// Cache lama menyimpan `plan` sebagai string nama; itu tetap terbaca.
class PlanSummaryModel {
  final String code;
  final String name;
  final int level;
  final DateTime? expiresAt;

  /// Hitungan server (dibulatkan ke atas, negatif bila lewat). Hanya cadangan:
  /// [daysLeft] menghitung ulang dari [expiresAt] supaya tidak basi di cache.
  final int? expiresInDays;

  const PlanSummaryModel({
    this.code = '',
    this.name = '',
    this.level = 0,
    this.expiresAt,
    this.expiresInDays,
  });

  /// Sisa hari sampai paket berakhir (dibulatkan ke atas seperti server);
  /// null = tanpa masa berlaku.
  int? daysLeft({DateTime? now}) {
    final end = expiresAt;
    if (end == null) return expiresInDays;
    final seconds = end.difference(now ?? DateTime.now()).inSeconds;
    return (seconds / 86400).ceil();
  }

  /// True bila masa berlaku sudah lewat.
  bool isExpired({DateTime? now}) {
    final end = expiresAt;
    return end != null && !end.isAfter(now ?? DateTime.now());
  }

  factory PlanSummaryModel.fromJson(String str) =>
      PlanSummaryModel.fromMap(jsonDecode(str) as Map<String, dynamic>);

  factory PlanSummaryModel.fromMap(Map<String, dynamic> json) {
    final rawExpires = json['expires_at'];
    return PlanSummaryModel(
      code: _toStr(json['code']),
      name: _toStr(json['name']),
      level: _toInt(json['level']) ?? 0,
      expiresAt: rawExpires == null ? null : DateTime.tryParse('$rawExpires'),
      expiresInDays: _toInt(json['expires_in_days']),
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'level': level,
        'expires_at': expiresAt?.toIso8601String(),
        'expires_in_days': expiresInDays,
      };

  String toJson() => jsonEncode(toMap());
}

// ─── RESPONSE MODEL: CompletenessModel ───────────────────────────────────────
/// Ringkasan kelengkapan di tenantSummary:
/// {percent, total, counts: {lengkap, sebagian, kosong}}.
class CompletenessModel {
  final int percent;
  final int total;
  final int complete;
  final int partial;
  final int empty;

  const CompletenessModel({
    this.percent = 0,
    this.total = 0,
    this.complete = 0,
    this.partial = 0,
    this.empty = 0,
  });

  factory CompletenessModel.fromMap(Map<String, dynamic> json) {
    final raw = json['counts'];
    final counts = raw is Map ? raw.cast<String, dynamic>() : const <String, dynamic>{};
    return CompletenessModel(
      percent: (_toInt(json['percent']) ?? 0).clamp(0, 100),
      total: _toInt(json['total']) ?? 0,
      complete: _toInt(counts['lengkap']) ?? 0,
      partial: _toInt(counts['sebagian']) ?? 0,
      empty: _toInt(counts['kosong']) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'percent': percent,
        'total': total,
        'counts': {'lengkap': complete, 'sebagian': partial, 'kosong': empty},
      };
}

enum SiteStatus { draft, published, unknown }

// ─── RESPONSE MODEL: TenantModel ─────────────────────────────────────────────
/// Satu situs milik pengguna (tenantSummary dari GET /me/tenants).
/// `unreadMessages` null = server tidak menyertakannya (hanya /me/tenants yang
/// memuatnya); jangan dianggap 0 saat menggabungkan data.
class TenantModel {
  final int? id;
  final String name;
  final String slug;
  final SiteStatus status;
  final String? url;
  final PlanSummaryModel? plan;
  final int? unreadMessages;

  /// Dinonaktifkan admin (situs tidak bisa ditayangkan). Cache lama = false.
  final bool suspended;
  final String? suspendedReason;

  /// Null bila server/cache lama tidak menyertakannya.
  final CompletenessModel? completeness;

  /// Warna situs saat ini (tenantSummary.theme). Null bila cache lama.
  final ThemeOptionModel? theme;

  /// Template tampilan yang dipakai situs (tenantSummary.template). Null bila cache lama.
  final TemplateSummaryModel? template;

  /// Domain sendiri (tenantSummary.domain). Null bila cache lama.
  final DomainSummaryModel? domain;

  /// Belum menyelesaikan/melewati onboarding. Cache lama = false supaya
  /// wizard tidak muncul dari data basi.
  final bool needsOnboarding;

  const TenantModel({
    this.id,
    required this.name,
    required this.slug,
    this.status = SiteStatus.unknown,
    this.url,
    this.plan,
    this.unreadMessages,
    this.suspended = false,
    this.suspendedReason,
    this.completeness,
    this.theme,
    this.template,
    this.domain,
    this.needsOnboarding = false,
  });

  factory TenantModel.fromJson(String str) =>
      TenantModel.fromMap(jsonDecode(str) as Map<String, dynamic>);

  factory TenantModel.fromMap(Map<String, dynamic> json) {
    final slug = _toStr(json['slug']);
    final rawName = _toStr(json['name'] ?? json['site_name']);
    final rawPlan = json['plan'];
    final rawUrl = json['url'];
    final rawReason = json['suspended_reason'];
    final rawCompleteness = json['completeness'];
    final rawTheme = json['theme'];
    final rawTemplate = json['template'];
    final rawDomain = json['domain'];
    return TenantModel(
      id: _toInt(json['id']),
      name: rawName.isNotEmpty ? rawName : slug,
      slug: slug,
      status: switch (json['status']) {
        'published' => SiteStatus.published,
        'draft' => SiteStatus.draft,
        _ => SiteStatus.unknown,
      },
      url: (rawUrl is String && rawUrl.isNotEmpty) ? rawUrl : null,
      plan: switch (rawPlan) {
        Map m => PlanSummaryModel.fromMap(m.cast<String, dynamic>()),
        String s when s.isNotEmpty => PlanSummaryModel(name: s),
        _ => null,
      },
      // `unread_count` = nama lama di cache aplikasi versi sebelumnya.
      unreadMessages: _toInt(json['unread_messages'] ?? json['unread_count']),
      suspended: json['suspended'] == true,
      suspendedReason: (rawReason is String && rawReason.trim().isNotEmpty)
          ? rawReason.trim()
          : null,
      completeness: rawCompleteness is Map
          ? CompletenessModel.fromMap(rawCompleteness.cast<String, dynamic>())
          : null,
      theme: rawTheme is Map
          ? ThemeOptionModel.fromMap(rawTheme.cast<String, dynamic>())
          : null,
      template: rawTemplate is Map
          ? TemplateSummaryModel.fromMap(rawTemplate.cast<String, dynamic>())
          : null,
      domain: rawDomain is Map
          ? DomainSummaryModel.fromMap(rawDomain.cast<String, dynamic>())
          : null,
      needsOnboarding: json['needs_onboarding'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'slug': slug,
        'status': switch (status) {
          SiteStatus.published => 'published',
          SiteStatus.draft => 'draft',
          SiteStatus.unknown => null,
        },
        'url': url,
        'plan': plan?.toMap(),
        'unread_messages': unreadMessages,
        'suspended': suspended,
        'suspended_reason': suspendedReason,
        'completeness': completeness?.toMap(),
        'theme': theme?.toMap(),
        'template': template?.toMap(),
        'domain': domain?.toMap(),
        'needs_onboarding': needsOnboarding,
      };

  String toJson() => jsonEncode(toMap());

  TenantModel copyWith({
    String? name,
    String? slug,
    SiteStatus? status,
    String? url,
    PlanSummaryModel? plan,
    int? unreadMessages,
    bool? suspended,
    String? suspendedReason,
    CompletenessModel? completeness,
    ThemeOptionModel? theme,
    TemplateSummaryModel? template,
    DomainSummaryModel? domain,
    bool? needsOnboarding,
  }) =>
      TenantModel(
        id: id,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        status: status ?? this.status,
        url: url ?? this.url,
        plan: plan ?? this.plan,
        unreadMessages: unreadMessages ?? this.unreadMessages,
        suspended: suspended ?? this.suspended,
        suspendedReason: suspendedReason ?? this.suspendedReason,
        completeness: completeness ?? this.completeness,
        theme: theme ?? this.theme,
        template: template ?? this.template,
        domain: domain ?? this.domain,
        needsOnboarding: needsOnboarding ?? this.needsOnboarding,
      );
}

// ─── RESPONSE MODEL: TenantsResponseModel ────────────────────────────────────
/// GET /me/tenants -> {data: [tenantSummary]}.
/// Toleran: daftar di akar atau di kunci `tenants`; entri tanpa slug dilewati.
class TenantsResponseModel {
  final List<TenantModel> data;

  const TenantsResponseModel({required this.data});

  factory TenantsResponseModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is List) return TenantsResponseModel.fromList(decoded);
    if (decoded is Map<String, dynamic>) {
      return TenantsResponseModel.fromMap(decoded);
    }
    throw const FormatException('Daftar situs tidak valid');
  }

  factory TenantsResponseModel.fromMap(Map<String, dynamic> json) {
    final raw = json['data'] ?? json['tenants'];
    if (raw is! List) throw const FormatException('Daftar situs tidak valid');
    return TenantsResponseModel.fromList(raw);
  }

  factory TenantsResponseModel.fromList(List<dynamic> list) =>
      TenantsResponseModel(
        data: list
            .whereType<Map>()
            .map((e) => TenantModel.fromMap(e.cast<String, dynamic>()))
            .where((t) => t.slug.isNotEmpty)
            .toList(growable: false),
      );

  Map<String, dynamic> toMap() => {
        'data': data.map((t) => t.toMap()).toList(),
      };

  String toJson() => jsonEncode(toMap());
}
