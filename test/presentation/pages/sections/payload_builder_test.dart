import 'dart:typed_data';

import 'package:compro_builder/data/model/request/section_payload.dart';
import 'package:compro_builder/data/model/response/field_def_model.dart';
import 'package:compro_builder/presentation/pages/sections/dynamic_form/form_values.dart';
import 'package:compro_builder/presentation/pages/sections/dynamic_form/payload_builder.dart';
import 'package:flutter_test/flutter_test.dart';

final _defs = FieldDefModel.parseList([
  {'key': 'title', 'label': 'Judul', 'type': 'text', 'required': true},
  {'key': 'photo', 'label': 'Foto', 'type': 'image'},
  {
    'key': 'items',
    'label': 'Item',
    'type': 'repeater',
    'max': 3,
    'fields': [
      {'key': 'name', 'label': 'Nama', 'type': 'text'},
      {'key': 'img', 'label': 'Gambar', 'type': 'image'},
    ],
  },
]);

Map<String, dynamic> _content() => {
  'title': 'Halo',
  'photo': '/storage/a.jpg',
  'items': [
    {'name': 'A', 'img': '/storage/i0.jpg'},
    {'name': 'B', 'img': '/storage/i1.jpg'},
  ],
};

Future<Uint8List> _noFetch(String url) async =>
    fail('tidak boleh mengunduh: $url');

void main() {
  test(
    'tanpa perubahan: gambar lama tidak dikirim (server mempertahankan)',
    () async {
      final form = DynamicFormController(_defs, _content());
      final p = await buildPayload(form, fetch: _noFetch);
      expect(p['title'], 'Halo');
      expect(p.containsKey('photo'), isFalse);
      expect(p.containsKey('photo_remove'), isFalse);
      expect((p['items'] as List).first, {'name': 'A'});
    },
  );

  test('gambar dihapus -> <field>_remove', () async {
    final form = DynamicFormController(_defs, _content());
    (form.values['photo'] as ImageValue)
      ..newBytes = null
      ..removed = true;
    final p = await buildPayload(form, fetch: _noFetch);
    expect(p['photo_remove'], 1);
  });

  test('gambar baru -> UploadFile', () async {
    final form = DynamicFormController(_defs, _content());
    (form.values['photo'] as ImageValue).newBytes = Uint8List.fromList([1]);
    final p = await buildPayload(form, fetch: _noFetch);
    expect(p['photo'], isA<UploadFile>());
  });

  test('baris repeater berpindah indeks: gambar lama diunduh ulang', () async {
    final form = DynamicFormController(_defs, _content());
    form.moveRow(form.values['items'] as List<RowValue>, 0, false);
    final fetched = <String>[];
    final p = await buildPayload(
      form,
      fetch: (url) async {
        fetched.add(url);
        return Uint8List.fromList([9]);
      },
    );
    final items = p['items'] as List;
    expect(items.map((e) => (e as Map)['name']), ['B', 'A']);
    expect(items.every((e) => (e as Map)['img'] is UploadFile), isTrue);
    expect(fetched, ['/storage/i1.jpg', '/storage/i0.jpg']);
  });

  test('baris kosong dibuang saat pruneEmptyRows', () {
    final form = DynamicFormController(_defs, _content());
    final rows = form.values['items'] as List<RowValue>;
    form.addRow(rows, _defs.last.children);
    expect(rows, hasLength(3));
    form.pruneEmptyRows();
    expect(rows, hasLength(2));
  });

  group('select / range / color', () {
    final defs = FieldDefModel.parseList([
      {
        'key': 'text_align',
        'label': 'Posisi teks',
        'type': 'select',
        'options': [
          {'value': 'left', 'label': 'Kiri'},
          {'value': 'center', 'label': 'Tengah'},
        ],
        'default': 'center',
      },
      {
        'key': 'overlay_opacity',
        'label': 'Kepekatan',
        'type': 'range',
        'min': 0,
        'max': 90,
        'step': 5,
        'default': 55,
      },
      {'key': 'overlay_color', 'label': 'Warna', 'type': 'color', 'default': '#0b1020'},
    ]);

    test('nilai tersimpan dikirim: range sebagai string, warna huruf kecil', () async {
      final form = DynamicFormController(defs, {
        'text_align': 'left',
        'overlay_opacity': 60,
        'overlay_color': '#AABBCC',
      });
      final p = await buildPayload(form, fetch: _noFetch);
      expect(p, {
        'text_align': 'left',
        'overlay_opacity': '60',
        'overlay_color': '#aabbcc',
      });
    });

    test('konten kosong -> nilai bawaan dari definisi', () async {
      final form = DynamicFormController(defs, {});
      final p = await buildPayload(form, fetch: _noFetch);
      expect(p, {
        'text_align': 'center',
        'overlay_opacity': '55',
        'overlay_color': '#0b1020',
      });
    });

    test('pilihan yang sudah tidak ada di daftar -> kembali ke bawaan; range di luar batas dijepit', () async {
      final form = DynamicFormController(defs, {
        'text_align': 'diagonal',
        'overlay_opacity': 500,
        'overlay_color': 'merah',
      });
      final p = await buildPayload(form, fetch: _noFetch);
      expect(p['text_align'], 'center');
      expect(p['overlay_opacity'], '90');
      expect(p['overlay_color'], '#0b1020');
    });

    test('flattenPayload: semua nilai jadi string multipart yang diterima aturan server', () async {
      final form = DynamicFormController(defs, {'overlay_opacity': 40});
      final flat = flattenPayload(await buildPayload(form, fetch: _noFetch));
      expect(
        {for (final e in flat.fields) e.key: e.value}['overlay_opacity'],
        '40',
      );
    });

    test('baris repeater yang hanya berisi nilai bawaan select/range/color dianggap kosong', () {
      expect(
        isRowEmpty(defs, DynamicFormController.initValues(defs, null)),
        isTrue,
      );
    });
  });
  test('moveRowTo memindahkan baris langsung ke posisi tujuan', () {
    final form = DynamicFormController(_defs, _content());
    final rows = form.values['items'] as List<RowValue>;
    form.addRow(rows, _defs.last.children);
    (rows[2].values)['name'] = 'C';

    form.moveRowTo(rows, 2, 0);
    expect(rows.map((r) => r.values['name']), ['C', 'A', 'B']);

    form.moveRowTo(rows, 0, 2);
    expect(rows.map((r) => r.values['name']), ['A', 'B', 'C']);

    // Di luar jangkauan / posisi sama: tidak berubah.
    form.moveRowTo(rows, 1, 1);
    form.moveRowTo(rows, 1, 9);
    form.moveRowTo(rows, -1, 0);
    expect(rows.map((r) => r.values['name']), ['A', 'B', 'C']);
  });
}
