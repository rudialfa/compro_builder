import 'dart:typed_data';

import 'package:compro_builder/data/model/request/section_payload.dart';

import 'package:compro_builder/data/model/response/field_def_model.dart';
import 'package:compro_builder/presentation/pages/sections/dynamic_form/form_values.dart';

/// Mengunduh bytes gambar lama (dipakai saat baris berpindah indeks).
typedef ImageFetcher = Future<Uint8List> Function(String url);

/// Membangun payload bersarang dari state form.
/// Aturan: gambar baru -> [UploadFile]; gambar dihapus -> `{field}_remove = 1`;
/// gambar lama tak berubah -> kunci dihilangkan (server mempertahankan).
/// Karena baris repeater dicocokkan per INDEKS di server:
///  - baris tanpa gambar di indeks yang sebelumnya bergambar -> kirim `_remove`;
///  - baris bergambar lama yang berpindah indeks -> gambar diunduh & diunggah ulang.
Future<Map<String, dynamic>> buildPayload(
  DynamicFormController form, {
  required ImageFetcher fetch,
}) => _scope(form.defs, form.values, form.original, fetch);

Future<Map<String, dynamic>> _scope(
  List<FieldDefModel> defs,
  Map<String, dynamic> scope,
  Map<String, dynamic>? original,
  ImageFetcher fetch, {
  int? index,
  int? originIndex,
}) async {
  final out = <String, dynamic>{};
  for (final d in defs) {
    final v = scope[d.key];
    switch (d.type) {
      case FieldType.text ||
          FieldType.textarea ||
          FieldType.link ||
          FieldType.phone ||
          FieldType.email:
        out[d.key] = ((v as String?) ?? '').trim();
      case FieldType.toggle:
        out[d.key] = v == true;
      case FieldType.select:
        out[d.key] = (v as String?) ?? '';
      case FieldType.range:
        // Dikirim sebagai string: aturan server `string|integer|between` menolak angka JSON.
        out[d.key] = '${(v as num?)?.toInt() ?? d.rangeMin}';
      case FieldType.color:
        out[d.key] = ((v as String?) ?? '').trim().toLowerCase();
      case FieldType.image:
        final iv = v as ImageValue;
        if (iv.newBytes != null) {
          out[d.key] = UploadFile(iv.newBytes!, 'image.jpg');
        } else if (iv.existingUrl != null && !iv.removed) {
          final moved =
              originIndex != null && index != null && originIndex != index;
          if (moved) {
            out[d.key] = UploadFile(await fetch(iv.existingUrl!), 'image.jpg');
          }
        } else if (imageUrlOf(original?[d.key]) != null) {
          out['${d.key}_remove'] = 1;
        }
      case FieldType.repeater:
        final rows = (v as List<RowValue>)
            .where((r) => !isRowEmpty(d.children, r.values))
            .toList();
        final origRows = original?[d.key];
        final list = <Map<String, dynamic>>[];
        for (var i = 0; i < rows.length; i++) {
          final orig =
              (origRows is List && i < origRows.length && origRows[i] is Map)
              ? Map<String, dynamic>.from(origRows[i] as Map)
              : null;
          list.add(
            await _scope(
              d.children,
              rows[i].values,
              orig,
              fetch,
              index: i,
              originIndex: rows[i].originIndex,
            ),
          );
        }
        out[d.key] = list;
      case FieldType.unknown:
        break;
    }
  }
  return out;
}
