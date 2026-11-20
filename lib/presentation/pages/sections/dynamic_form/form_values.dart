import 'package:flutter/foundation.dart';

import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/data/model/response/field_def_model.dart';

String? imageUrlOf(Object? v) {
  if (v is String && v.isNotEmpty) return v;
  if (v is Map && v['url'] is String && (v['url'] as String).isNotEmpty) {
    return v['url'] as String;
  }
  return null;
}

final _hexRe = RegExp(r'^#[0-9a-fA-F]{6}$');

/// Warna valid = `#RRGGBB` (sama dengan aturan server).
bool isHexColor(String s) => _hexRe.hasMatch(s);

int _clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

int? _asInt(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

/// Nilai isian gambar: gambar lama (URL), gambar baru (bytes terkompres), atau dihapus.
class ImageValue {
  ImageValue({this.existingUrl});
  String? existingUrl;
  Uint8List? newBytes;
  bool removed = false;

  bool get hasImage => newBytes != null || (existingUrl != null && !removed);
}

/// Satu baris repeater. [id] stabil untuk key widget; [originIndex] = indeks di hasil GET
/// (null untuk baris baru), dipakai agar gambar lama tetap cocok dengan indeks server.
class RowValue {
  RowValue(this.id, this.values, {this.originIndex});
  final int id;
  final int? originIndex;
  final Map<String, dynamic> values;
}

bool isRowEmpty(List<FieldDefModel> defs, Map<String, dynamic> values) {
  for (final d in defs) {
    final v = values[d.key];
    switch (d.type) {
      case FieldType.text ||
          FieldType.textarea ||
          FieldType.link ||
          FieldType.phone ||
          FieldType.email:
        if (((v as String?) ?? '').trim().isNotEmpty) return false;
      case FieldType.image:
        if (v is ImageValue && v.hasImage) return false;
      case FieldType.toggle:
        if (v == true) return false;
      case FieldType.repeater:
        final rows = (v as List<RowValue>?) ?? const [];
        if (rows.any((r) => !isRowEmpty(d.children, r.values))) return false;
      case FieldType.select ||
          FieldType.range ||
          FieldType.color ||
          FieldType.unknown:
        // Pilihan/slider/warna selalu punya nilai bawaan, jadi tidak menandai baris "terisi".
        break;
    }
  }
  return true;
}

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// State form dinamis (tanpa codegen). Nilai disimpan di [values]; galat per path
/// ("items.0.title", sama dengan notasi Laravel) di [errors].
class DynamicFormController extends ChangeNotifier {
  DynamicFormController(this.defs, Map<String, dynamic> content)
    : original = content,
      values = initValues(defs, content);

  final List<FieldDefModel> defs;
  final Map<String, dynamic> original;
  final Map<String, dynamic> values;
  final Map<String, String> errors = {};

  static int _seq = 0;
  static int nextId() => ++_seq;

  static Map<String, dynamic> initValues(
    List<FieldDefModel> defs,
    Map<String, dynamic>? content,
  ) {
    final out = <String, dynamic>{};
    for (final d in defs) {
      final raw = content?[d.key];
      switch (d.type) {
        case FieldType.text ||
            FieldType.textarea ||
            FieldType.link ||
            FieldType.phone ||
            FieldType.email:
          out[d.key] = raw == null ? '' : raw.toString();
        case FieldType.toggle:
          out[d.key] = raw == true || raw == 1 || raw == '1' || raw == 'true';
        case FieldType.image:
          out[d.key] = ImageValue(existingUrl: imageUrlOf(raw));
        case FieldType.repeater:
          final rows = <RowValue>[];
          if (raw is List) {
            for (var i = 0; i < raw.length; i++) {
              final item = raw[i] is Map
                  ? Map<String, dynamic>.from(raw[i] as Map)
                  : <String, dynamic>{};
              rows.add(
                RowValue(
                  nextId(),
                  initValues(d.children, item),
                  originIndex: i,
                ),
              );
            }
          }
          out[d.key] = rows;
        case FieldType.select:
          final picked = raw?.toString() ?? '';
          final fallback = d.defaultValue?.toString() ?? '';
          // Nilai tersimpan yang sudah tidak ada di daftar pilihan dianggap kosong.
          final known =
              d.options.isEmpty || d.options.any((o) => o.value == picked);
          out[d.key] = (picked.isNotEmpty && known) ? picked : fallback;
        case FieldType.range:
          final n = _asInt(raw) ?? _asInt(d.defaultValue) ?? d.rangeMin;
          out[d.key] = _clampInt(n, d.rangeMin, d.rangeMax);
        case FieldType.color:
          final given = (raw?.toString() ?? '').trim();
          final preset = d.defaultValue?.toString() ?? '';
          final chosen = isHexColor(given)
              ? given
              : (isHexColor(preset) ? preset : '');
          out[d.key] = chosen.toLowerCase();
        case FieldType.unknown:
          break;
      }
    }
    return out;
  }

  // ---- perubahan ----
  void set(Map<String, dynamic> scope, String key, Object? v, String path) {
    scope[key] = v;
    changed(path);
  }

  void changed(String path) {
    errors.remove(path);
    notifyListeners();
  }

  void addRow(List<RowValue> rows, List<FieldDefModel> children) {
    rows.add(RowValue(nextId(), initValues(children, null)));
    notifyListeners();
  }

  void removeRow(List<RowValue> rows, int i) {
    rows.removeAt(i);
    errors.clear(); // indeks bergeser
    notifyListeners();
  }

  void moveRow(List<RowValue> rows, int i, bool up) {
    final j = up ? i - 1 : i + 1;
    if (j < 0 || j >= rows.length) return;
    final t = rows[i];
    rows[i] = rows[j];
    rows[j] = t;
    errors.clear();
    notifyListeners();
  }

  /// Memindahkan baris [from] langsung ke posisi [to] (indeks 0-based);
  /// baris lain bergeser otomatis. Dipakai pilihan "Pindah ke…".
  void moveRowTo(List<RowValue> rows, int from, int to) {
    if (from == to ||
        from < 0 ||
        from >= rows.length ||
        to < 0 ||
        to >= rows.length) {
      return;
    }
    final item = rows.removeAt(from);
    rows.insert(to, item);
    errors.clear();
    notifyListeners();
  }

  /// Membuang baris repeater yang kosong (rekursif), sesuai aturan "baris kosong dibuang".
  void pruneEmptyRows() {
    void prune(List<FieldDefModel> ds, Map<String, dynamic> scope) {
      for (final d in ds.where((d) => d.type == FieldType.repeater)) {
        final rows = scope[d.key] as List<RowValue>;
        rows.removeWhere((r) => isRowEmpty(d.children, r.values));
        for (final r in rows) {
          prune(d.children, r.values);
        }
      }
    }

    prune(defs, values);
    notifyListeners();
  }

  // ---- validasi ----
  bool validate(AppLocalizations l) {
    errors.clear();
    _validate(defs, values, '', l);
    notifyListeners();
    return errors.isEmpty;
  }

  void _validate(
    List<FieldDefModel> ds,
    Map<String, dynamic> scope,
    String prefix,
    AppLocalizations l,
  ) {
    for (final d in ds) {
      final path = prefix.isEmpty ? d.key : '$prefix.${d.key}';
      final v = scope[d.key];
      switch (d.type) {
        case FieldType.text ||
            FieldType.textarea ||
            FieldType.link ||
            FieldType.phone ||
            FieldType.email:
          final s = ((v as String?) ?? '').trim();
          if (s.isEmpty) {
            if (d.required) errors[path] = l.validationRequired;
          } else if (d.maxLength != null && s.length > d.maxLength!) {
            errors[path] = l.validationMaxLength(d.maxLength!);
          } else if (d.type == FieldType.email && !_emailRe.hasMatch(s)) {
            errors[path] = l.validationEmail;
          }
        case FieldType.image:
          if (d.required && !(v is ImageValue && v.hasImage)) {
            errors[path] = l.validationRequired;
          }
        case FieldType.repeater:
          final rows = (v as List<RowValue>?) ?? const [];
          if (d.required && rows.isEmpty) errors[path] = l.validationRequired;
          if (d.maxItems != null && rows.length > d.maxItems!) {
            errors[path] = l.validationMaxItems(d.maxItems!);
          }
          for (var i = 0; i < rows.length; i++) {
            _validate(d.children, rows[i].values, '$path.$i', l);
          }
        case FieldType.select:
          if (d.required && ((v as String?) ?? '').isEmpty) {
            errors[path] = l.validationRequired;
          }
        case FieldType.color:
          final hex = ((v as String?) ?? '').trim();
          if (hex.isEmpty) {
            if (d.required) errors[path] = l.validationRequired;
          } else if (!isHexColor(hex)) {
            errors[path] = l.validationColor;
          }
        case FieldType.toggle || FieldType.range || FieldType.unknown:
          break; // slider selalu di dalam batas
      }
    }
  }

  /// Menaruh galat 422 dari server (kunci notasi titik) di bawah field terkait.
  void setServerErrors(Map<String, List<String>> serverErrors) {
    errors
      ..clear()
      ..addAll({
        for (final e in serverErrors.entries)
          if (e.value.isNotEmpty) e.key: e.value.first,
      });
    notifyListeners();
  }
}
