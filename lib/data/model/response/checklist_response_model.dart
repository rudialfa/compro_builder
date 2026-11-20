import 'dart:convert';

import 'package:compro_builder/data/model/response/tenant_model.dart';

int _toInt(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

enum ChecklistStatus { empty, partial, full, unknown }

// ─── RESPONSE MODEL: ChecklistItemModel ──────────────────────────────────────
/// Satu section di checklist: {id, code, name, status, missing, note, is_sample}.
/// `status` server: kosong | sebagian | lengkap.
class ChecklistItemModel {
  final int id;
  final String code;
  final String name;
  final ChecklistStatus status;

  /// Label field wajib yang belum terisi.
  final List<String> missing;

  /// Kalimat siap tampil dari server ("Belum diisi: WhatsApp", "Masih teks contoh").
  final String? note;
  final bool isSample;

  const ChecklistItemModel({
    required this.id,
    this.code = '',
    required this.name,
    this.status = ChecklistStatus.unknown,
    this.missing = const [],
    this.note,
    this.isSample = false,
  });

  bool get isComplete => status == ChecklistStatus.full;

  factory ChecklistItemModel.fromMap(Map<String, dynamic> json) {
    final rawMissing = json['missing'];
    final rawNote = json['note'];
    return ChecklistItemModel(
      id: _toInt(json['id']),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      status: switch (json['status']) {
        'lengkap' => ChecklistStatus.full,
        'sebagian' => ChecklistStatus.partial,
        'kosong' => ChecklistStatus.empty,
        _ => ChecklistStatus.unknown,
      },
      missing: rawMissing is List
          ? rawMissing.map((e) => '$e').toList(growable: false)
          : const [],
      note: (rawNote is String && rawNote.trim().isNotEmpty) ? rawNote : null,
      isSample: json['is_sample'] == true,
    );
  }
}

// ─── RESPONSE MODEL: ChecklistPublishModel ───────────────────────────────────
/// Blok `publish` dari checklist. Belum lengkap TIDAK menghalangi tayang;
/// yang menghalangi hanya [blockers]: `suspended` dan `email_unverified`
/// (keduanya ditolak 403 oleh POST /status).
class ChecklistPublishModel {
  final SiteStatus status;
  final bool emailVerified;
  final bool suspended;
  final bool canPublish;
  final List<String> blockers;

  const ChecklistPublishModel({
    this.status = SiteStatus.unknown,
    this.emailVerified = true,
    this.suspended = false,
    this.canPublish = true,
    this.blockers = const [],
  });

  bool get isSuspendedBlock => blockers.contains('suspended');
  bool get isEmailBlock => blockers.contains('email_unverified');

  factory ChecklistPublishModel.fromMap(Map<String, dynamic> json) {
    final rawBlockers = json['blockers'];
    final blockers = rawBlockers is List
        ? rawBlockers.map((e) => '$e').toList(growable: false)
        : const <String>[];
    return ChecklistPublishModel(
      status: switch (json['status']) {
        'published' => SiteStatus.published,
        'draft' => SiteStatus.draft,
        _ => SiteStatus.unknown,
      },
      emailVerified: json['email_verified'] != false,
      suspended: json['suspended'] == true,
      canPublish: json.containsKey('can_publish')
          ? json['can_publish'] == true
          : blockers.isEmpty,
      blockers: blockers,
    );
  }
}

// ─── RESPONSE MODEL: ChecklistResponseModel ──────────────────────────────────
/// GET /{slug}/manage/checklist -> {data: {percent, total, counts, items, publish}}.
class ChecklistResponseModel {
  final int percent;
  final int total;
  final int complete;
  final int partial;
  final int empty;
  final List<ChecklistItemModel> items;
  final ChecklistPublishModel publish;

  const ChecklistResponseModel({
    this.percent = 0,
    this.total = 0,
    this.complete = 0,
    this.partial = 0,
    this.empty = 0,
    this.items = const [],
    this.publish = const ChecklistPublishModel(),
  });

  /// Jumlah section yang belum lengkap (dipakai dialog konfirmasi tayang).
  int get issueCount => items.where((i) => !i.isComplete).length;

  factory ChecklistResponseModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) throw const FormatException('Checklist tidak valid');
    return ChecklistResponseModel.fromMap(Map<String, dynamic>.from(decoded));
  }

  factory ChecklistResponseModel.fromMap(Map<String, dynamic> json) {
    final inner = json['data'];
    final node = inner is Map ? Map<String, dynamic>.from(inner) : json;
    final rawCounts = node['counts'];
    final counts = rawCounts is Map
        ? rawCounts.cast<String, dynamic>()
        : const <String, dynamic>{};
    final rawItems = node['items'];
    final rawPublish = node['publish'];
    return ChecklistResponseModel(
      percent: _toInt(node['percent']).clamp(0, 100),
      total: _toInt(node['total']),
      complete: _toInt(counts['lengkap']),
      partial: _toInt(counts['sebagian']),
      empty: _toInt(counts['kosong']),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => ChecklistItemModel.fromMap(e.cast<String, dynamic>()))
              .toList(growable: false)
          : const [],
      publish: rawPublish is Map
          ? ChecklistPublishModel.fromMap(rawPublish.cast<String, dynamic>())
          : const ChecklistPublishModel(),
    );
  }
}
