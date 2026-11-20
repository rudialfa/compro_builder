import 'package:compro_builder/data/model/response/field_def_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseList: field tanpa key dilewati, tipe tak dikenal -> unknown', () {
    final list = FieldDefModel.parseList([
      {'key': 'title', 'type': 'text', 'label': 'Judul', 'required': true, 'max': 80},
      {'key': 'weird', 'type': 'color-picker', 'label': 'Warna'},
      {'type': 'text'}, // tanpa key
      'bukan-objek',
    ]);
    expect(list.map((f) => f.key), ['title', 'weird']);
    expect(list[0].type, FieldType.text);
    expect(list[0].required, isTrue);
    expect(list[0].maxLength, 80);
    expect(list[1].type, FieldType.unknown);
  });

  test('repeater: max berarti jumlah baris, anak ikut terparse', () {
    final rep = FieldDefModel.fromMap({
      'key': 'items',
      'type': 'repeater',
      'label': 'Butir',
      'max': 3,
      'fields': [
        {'key': 'image', 'type': 'image', 'label': 'Foto', 'max_kb': 1024},
        {'key': 'label', 'type': 'text', 'label': 'Label'},
      ],
    });
    expect(rep.type, FieldType.repeater);
    expect(rep.maxItems, 3);
    expect(rep.maxLength, isNull);
    expect(rep.children.first.type, FieldType.image);
    expect(rep.children.first.maxKb, 1024);
  });

  test('alias tipe, required angka 1, hint/item_label kosong -> null', () {
    final f = FieldDefModel.fromMap({
      'key': 'k',
      'type': 'boolean',
      'required': 1,
      'hint': '',
      'item_label': '',
    });
    expect(f.type, FieldType.toggle);
    expect(f.required, isTrue);
    expect(f.hint, isNull);
    expect(f.itemLabel, isNull);
    expect(f.label, 'k'); // tanpa label -> memakai key
  });

  test('toJson -> fromJson bolak-balik (cache offline)', () {
    final rep = FieldDefModel.fromMap({
      'key': 'items',
      'type': 'repeater',
      'label': 'Butir',
      'max': 3,
      'fields': [
        {'key': 'label', 'type': 'text', 'label': 'Label', 'required': true},
      ],
    });
    final back = FieldDefModel.fromJson(rep.toJson());
    expect(back.type, FieldType.repeater);
    expect(back.maxItems, 3);
    expect(back.children.single.key, 'label');
    expect(back.children.single.required, isTrue);
  });

  test('select: options [{value,label}] urut, default, hint; max bukan panjang teks', () {
    final f = FieldDefModel.fromMap({
      'key': 'text_align',
      'type': 'select',
      'label': 'Posisi teks',
      'options': [
        {'value': 'left', 'label': 'Kiri'},
        {'value': 'center', 'label': 'Tengah'},
      ],
      'default': 'center',
      'max': 255,
    });
    expect(f.type, FieldType.select);
    expect(f.options.map((o) => o.value), ['left', 'center']);
    expect(f.options.last.label, 'Tengah');
    expect(f.defaultValue, 'center');
    expect(f.maxLength, isNull);
  });

  test('select: options berbentuk peta atau larik string tetap terbaca', () {
    final fromMap = FieldDefModel.fromMap({
      'key': 'a',
      'type': 'select',
      'options': {'pill': 'Bulat', 'square': 'Kotak'},
    });
    expect(fromMap.options.map((o) => '${o.value}=${o.label}'), [
      'pill=Bulat',
      'square=Kotak',
    ]);
    final fromList = FieldDefModel.fromMap({
      'key': 'b',
      'type': 'select',
      'options': ['x', 'y'],
    });
    expect(fromList.options.map((o) => o.label), ['x', 'y']);
  });

  test('range: max = batas angka (bukan panjang teks), min/step/suffix/default', () {
    final f = FieldDefModel.fromMap({
      'key': 'overlay_opacity',
      'type': 'range',
      'label': 'Kepekatan',
      'min': 0,
      'max': 90,
      'step': 5,
      'default': 55,
      'suffix': '%',
    });
    expect(f.type, FieldType.range);
    expect(f.maxValue, 90);
    expect(f.maxLength, isNull);
    expect(f.maxItems, isNull);
    expect([f.rangeMin, f.rangeMax, f.rangeStep], [0, 90, 5]);
    expect(f.suffix, '%');
    expect(f.defaultValue, 55);
  });

  test('range tanpa min/max/step memakai nilai aman', () {
    final f = FieldDefModel.fromMap({'key': 'r', 'type': 'range', 'step': 0});
    expect([f.rangeMin, f.rangeMax, f.rangeStep], [0, 100, 1]);
  });

  test('color + penanda markdown terbaca', () {
    final c = FieldDefModel.fromMap({
      'key': 'overlay_color',
      'type': 'color',
      'default': '#0b1020',
    });
    expect(c.type, FieldType.color);
    expect(c.defaultValue, '#0b1020');
    final md = FieldDefModel.fromMap({
      'key': 'body',
      'type': 'textarea',
      'max': 2000,
      'markdown': true,
    });
    expect(md.markdown, isTrue);
    expect(md.maxLength, 2000);
    expect(c.markdown, isFalse);
  });

  test('toJson -> fromJson untuk select/range/color/markdown (cache offline)', () {
    final defs = FieldDefModel.parseList([
      {
        'key': 'a',
        'type': 'select',
        'options': [
          {'value': 'x', 'label': 'X'},
        ],
        'default': 'x',
      },
      {'key': 'r', 'type': 'range', 'min': 10, 'max': 80, 'step': 5, 'suffix': '%', 'default': 20},
      {'key': 'c', 'type': 'color', 'default': '#ffffff'},
      {'key': 'body', 'type': 'textarea', 'max': 2000, 'markdown': true},
    ]);
    final back = defs.map((d) => FieldDefModel.fromJson(d.toJson())).toList();
    expect(back[0].options.single.label, 'X');
    expect(back[0].defaultValue, 'x');
    expect([back[1].rangeMin, back[1].rangeMax, back[1].rangeStep], [10, 80, 5]);
    expect(back[1].suffix, '%');
    expect(back[2].type, FieldType.color);
    expect(back[3].markdown, isTrue);
    expect(back[3].maxLength, 2000);
  });
}
