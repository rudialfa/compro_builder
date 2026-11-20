import 'dart:convert';

int? _toInt(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

enum FieldType {
  text,
  textarea,
  link,
  phone,
  email,
  image,
  toggle,
  repeater,
  select,
  range,
  color,
  unknown,
}

/// Satu pilihan field `select` (urutan dari server dipertahankan).
class FieldOption {
  final String value;
  final String label;
  const FieldOption(this.value, this.label);

  Map<String, dynamic> toMap() => {'value': value, 'label': label};

  /// Menerima [{value,label}], peta {value: label}, atau larik string.
  static List<FieldOption> parseList(Object? raw) {
    final out = <FieldOption>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          final value = e['value']?.toString();
          if (value == null) continue;
          out.add(FieldOption(value, (e['label'] ?? value).toString()));
        } else if (e != null) {
          out.add(FieldOption(e.toString(), e.toString()));
        }
      }
    } else if (raw is Map) {
      for (final e in raw.entries) {
        out.add(FieldOption(e.key.toString(), (e.value ?? e.key).toString()));
      }
    }
    return out;
  }
}

// ─── RESPONSE MODEL: FieldDefModel ───────────────────────────────────────────
/// Definisi satu isian form dari `section.fields[]` (key, label, type,
/// required, max, hint, item_label, max_kb, max_items, fields[] untuk repeater;
/// select: options/default; range: min/max/step/suffix/default; color: default).
/// Form dinamis (Fase 3b) digerakkan oleh definisi ini, bukan di-hardcode.
///
/// Arti `max` bergantung pada tipe: teks = panjang maksimal ([maxLength]),
/// repeater = jumlah baris ([maxItems]), range = batas angka ([maxValue]).
class FieldDefModel {
  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final int? maxLength;
  final int? maxItems;
  final int? maxKb;
  final String? hint;
  final String? itemLabel;
  final List<FieldDefModel> children;

  // select / range / color
  final List<FieldOption> options;
  final Object? defaultValue;
  final int? min;
  final int? maxValue;
  final int? step;
  final String? suffix;

  /// Isi field ditulis dengan Markdown sederhana (server: SectionPresenter).
  final bool markdown;

  const FieldDefModel({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.maxLength,
    this.maxItems,
    this.maxKb,
    this.hint,
    this.itemLabel,
    this.children = const [],
    this.options = const [],
    this.defaultValue,
    this.min,
    this.maxValue,
    this.step,
    this.suffix,
    this.markdown = false,
  });

  /// Batas range yang aman dipakai UI (min default 0, max default 100, step minimal 1).
  int get rangeMin => min ?? 0;
  int get rangeMax => maxValue ?? 100;
  int get rangeStep => (step == null || step! < 1) ? 1 : step!;

  factory FieldDefModel.fromJson(String str) =>
      FieldDefModel.fromMap(jsonDecode(str) as Map<String, dynamic>);

  factory FieldDefModel.fromMap(Map<String, dynamic> json) {
    final key = (json['key'] ?? json['name'])?.toString();
    if (key == null || key.isEmpty) {
      throw const FormatException('Field tanpa key');
    }
    final type = _parseType(json['type']?.toString());
    final rawChildren = json['fields'] ?? json['children'] ?? json['items'];
    final hint = json['hint']?.toString();
    final itemLabel = json['item_label']?.toString();
    final suffix = json['suffix']?.toString();
    // `max` bukan panjang teks untuk repeater/range; select/color tak memakainya.
    final maxIsLength = switch (type) {
      FieldType.repeater ||
      FieldType.range ||
      FieldType.select ||
      FieldType.color => false,
      _ => true,
    };
    return FieldDefModel(
      key: key,
      label: (json['label'] ?? key).toString(),
      type: type,
      required: json['required'] == true || json['required'] == 1,
      maxLength: maxIsLength ? _toInt(json['max']) : null,
      maxItems: _toInt(
        json['max_items'] ?? (type == FieldType.repeater ? json['max'] : null),
      ),
      maxKb: _toInt(json['max_kb']),
      hint: (hint == null || hint.isEmpty) ? null : hint,
      itemLabel: (itemLabel == null || itemLabel.isEmpty) ? null : itemLabel,
      children: rawChildren is List ? parseList(rawChildren) : const [],
      options: type == FieldType.select
          ? FieldOption.parseList(json['options'])
          : const [],
      defaultValue: json['default'],
      min: _toInt(json['min']),
      maxValue: type == FieldType.range ? _toInt(json['max']) : null,
      step: _toInt(json['step']),
      suffix: (suffix == null || suffix.isEmpty) ? null : suffix,
      markdown: json['markdown'] == true || json['markdown'] == 1,
    );
  }

  /// Field yang tak bisa diparse dilewati agar satu field aneh tidak merusak layar.
  static List<FieldDefModel> parseList(List<dynamic> raw) {
    final out = <FieldDefModel>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        out.add(FieldDefModel.fromMap(Map<String, dynamic>.from(e)));
      } on FormatException {
        continue;
      }
    }
    return out;
  }

  Map<String, dynamic> toMap() => {
    'key': key,
    'label': label,
    'type': _typeName(type),
    'required': required,
    'max': switch (type) {
      FieldType.repeater => maxItems,
      FieldType.range => maxValue,
      _ => maxLength,
    },
    'max_items': maxItems,
    'max_kb': maxKb,
    'hint': hint,
    'item_label': itemLabel,
    'fields': children.map((c) => c.toMap()).toList(),
    'options': options.map((o) => o.toMap()).toList(),
    'default': defaultValue,
    'min': min,
    'step': step,
    'suffix': suffix,
    'markdown': markdown,
  };

  String toJson() => jsonEncode(toMap());

  static FieldType _parseType(String? t) => switch (t) {
    'text' || 'string' => FieldType.text,
    'textarea' || 'longtext' => FieldType.textarea,
    'link' || 'url' => FieldType.link,
    'phone' || 'tel' => FieldType.phone,
    'email' => FieldType.email,
    'image' || 'file' => FieldType.image,
    'toggle' || 'boolean' || 'bool' || 'checkbox' => FieldType.toggle,
    'repeater' || 'list' => FieldType.repeater,
    'select' => FieldType.select,
    'range' => FieldType.range,
    'color' => FieldType.color,
    _ => FieldType.unknown,
  };

  static String _typeName(FieldType t) => switch (t) {
    FieldType.text => 'text',
    FieldType.textarea => 'textarea',
    FieldType.link => 'link',
    FieldType.phone => 'phone',
    FieldType.email => 'email',
    FieldType.image => 'image',
    FieldType.toggle => 'toggle',
    FieldType.repeater => 'repeater',
    FieldType.select => 'select',
    FieldType.range => 'range',
    FieldType.color => 'color',
    FieldType.unknown => 'unknown',
  };
}
