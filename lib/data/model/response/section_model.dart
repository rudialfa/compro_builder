import 'dart:convert';

import 'package:compro_builder/data/model/response/field_def_model.dart';

bool _toBool(Object? v, {bool def = false}) => switch (v) {
  bool b => b,
  num n => n != 0,
  String s => s == '1' || s == 'true',
  _ => def,
};

int? _toInt(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

/// Backend membungkus hampir semua respons dengan {data: ...}; cache lokal
/// menyimpan bentuk datar. Keduanya dibaca di sini.
Map<String, dynamic> _unwrap(Object? decoded) {
  if (decoded is! Map) throw const FormatException('Respons tidak valid');
  final inner = decoded['data'];
  return Map<String, dynamic>.from(inner is Map ? inner : decoded);
}

// ─── RESPONSE MODEL: SectionTypeModel ────────────────────────────────────────
/// Tipe section yang bisa ditambah (`addable`: id, code, name) atau yang
/// terkunci paket (`locked`: code, name, min_level).
class SectionTypeModel {
  final String type;
  final String name;
  final int? sectionTypeId;
  final int? minLevel;
  final bool locked;

  const SectionTypeModel({
    required this.type,
    required this.name,
    this.sectionTypeId,
    this.minLevel,
    this.locked = false,
  });

  /// Entri tanpa kode dilewati (null) agar satu data aneh tidak merusak daftar.
  static SectionTypeModel? tryParse(Object? raw, {bool locked = false}) {
    if (raw is String && raw.isNotEmpty) {
      return SectionTypeModel(type: raw, name: raw, locked: locked);
    }
    if (raw is! Map) return null;
    final type = (raw['code'] ?? raw['type'] ?? raw['slug'])?.toString();
    if (type == null || type.isEmpty) return null;
    return SectionTypeModel(
      type: type,
      name: (raw['name'] ?? raw['label'] ?? type).toString(),
      sectionTypeId: _toInt(raw['id'] ?? raw['section_type_id']),
      minLevel: _toInt(raw['min_level']),
      locked: locked || _toBool(raw['locked']),
    );
  }

  static List<SectionTypeModel> parseList(Object? raw, {required bool locked}) {
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        ?tryParse(e, locked: locked),
    ];
  }

  Map<String, dynamic> toMap() => {
    'id': sectionTypeId,
    'code': type,
    'name': name,
    'min_level': minLevel,
  };
}

// ─── RESPONSE MODEL: SectionModel ────────────────────────────────────────────
/// Satu section (SectionPresenter::managed). Pada section terkunci, `content`
/// null dan `fields` kosong. Kunci status tampil di backend adalah `enabled`
/// (versi lama membaca `is_enabled`, jadi dua-duanya diterima).
class SectionModel {
  final int id;
  final String type;
  final String name;
  final int order;
  final bool isEnabled;
  final bool isSample;
  final bool locked;
  final Map<String, dynamic> content;
  final List<FieldDefModel> fields;

  const SectionModel({
    required this.id,
    required this.type,
    required this.name,
    this.order = 0,
    this.isEnabled = true,
    this.isSample = false,
    this.locked = false,
    this.content = const {},
    this.fields = const [],
  });

  /// Menerima {data: section} maupun objek section langsung.
  factory SectionModel.fromJson(String str) =>
      SectionModel.fromMap(_unwrap(jsonDecode(str)));

  factory SectionModel.fromMap(Map<String, dynamic> json) {
    final id = _toInt(json['id']);
    if (id == null) throw const FormatException('Section tanpa id');
    final type = (json['type'] ?? '').toString();
    final content = json['content'];
    final fields = json['fields'];
    return SectionModel(
      id: id,
      type: type,
      name: (json['name'] ?? type).toString(),
      order: _toInt(json['order']) ?? 0,
      isEnabled: _toBool(json['enabled'] ?? json['is_enabled'], def: true),
      isSample: _toBool(json['is_sample']),
      locked: _toBool(json['locked']),
      content: content is Map ? Map<String, dynamic>.from(content) : const {},
      fields: fields is List ? FieldDefModel.parseList(fields) : const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'name': name,
    'order': order,
    'enabled': isEnabled,
    'is_sample': isSample,
    'locked': locked,
    'content': locked ? null : content,
    'fields': fields.map((f) => f.toMap()).toList(),
  };

  String toJson() => jsonEncode(toMap());

  SectionModel copyWith({bool? isEnabled}) => SectionModel(
    id: id,
    type: type,
    name: name,
    order: order,
    isEnabled: isEnabled ?? this.isEnabled,
    isSample: isSample,
    locked: locked,
    content: content,
    fields: fields,
  );
}

// ─── RESPONSE MODEL: SectionsDataModel ───────────────────────────────────────
/// Isi GET /{slug}/manage/sections (juga balasan POST .../move):
/// {data: {sections, usage: {used, limit}, addable, locked}}.
class SectionsDataModel {
  final List<SectionModel> sections;
  final int used;

  /// Null = tanpa batas.
  final int? limit;
  final List<SectionTypeModel> addable;
  final List<SectionTypeModel> locked;

  const SectionsDataModel({
    required this.sections,
    required this.used,
    this.limit,
    this.addable = const [],
    this.locked = const [],
  });

  bool get limitReached => limit != null && used >= limit!;

  factory SectionsDataModel.fromJson(String str) =>
      SectionsDataModel.fromMap(_unwrap(jsonDecode(str)));

  factory SectionsDataModel.fromMap(Map<String, dynamic> json) {
    final raw = json['sections'];
    if (raw is! List) throw const FormatException('Daftar section tidak valid');
    final sections = <SectionModel>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        sections.add(SectionModel.fromMap(Map<String, dynamic>.from(e)));
      } on FormatException {
        continue;
      }
    }
    sections.sort((a, b) => a.order.compareTo(b.order));
    final usage = json['usage'] is Map ? json['usage'] as Map : const {};
    return SectionsDataModel(
      sections: sections,
      used: _toInt(usage['used']) ?? sections.length,
      limit: _toInt(usage['limit']),
      addable: SectionTypeModel.parseList(json['addable'], locked: false),
      locked: SectionTypeModel.parseList(json['locked'], locked: true),
    );
  }

  /// Bentuk datar (tanpa pembungkus `data`); dipakai untuk cache offline.
  Map<String, dynamic> toMap() => {
    'sections': sections.map((s) => s.toMap()).toList(),
    'usage': {'used': used, 'limit': limit},
    'addable': addable.map((t) => t.toMap()).toList(),
    'locked': locked.map((t) => t.toMap()).toList(),
  };

  String toJson() => jsonEncode(toMap());

  SectionsDataModel copyWith({List<SectionModel>? sections, int? used}) =>
      SectionsDataModel(
        sections: sections ?? this.sections,
        used: used ?? this.used,
        limit: limit,
        addable: addable,
        locked: locked,
      );
}
