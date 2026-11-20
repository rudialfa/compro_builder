import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/data/model/response/field_def_model.dart';
import 'package:compro_builder/presentation/pages/sections/dynamic_form/dynamic_form.dart';
import 'package:compro_builder/presentation/pages/sections/dynamic_form/form_values.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const defs = [
  FieldDefModel(key: 'title', label: 'Judul', type: FieldType.text, required: true),
  FieldDefModel(key: 'on', label: 'Aktif', type: FieldType.toggle),
  FieldDefModel(key: 'cover', label: 'Sampul', type: FieldType.image),
  FieldDefModel(key: 'x', label: 'Aneh', type: FieldType.unknown),
  FieldDefModel(
    key: 'items',
    label: 'Butir',
    type: FieldType.repeater,
    maxItems: 2,
    children: [
      FieldDefModel(key: 'label', label: 'Label', type: FieldType.text, required: true),
    ],
  ),
];

Widget _wrap(DynamicFormController c) => MaterialApp(
  locale: const Locale('id'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: DynamicForm(controller: c))),
);

void main() {
  testWidgets('merender semua tipe dari definisi, termasuk fallback tipe tak dikenal', (
    tester,
  ) async {
    final c = DynamicFormController(defs, {'title': 'Halo'});
    await tester.pumpWidget(_wrap(c));
    expect(find.text('Judul *'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Pilih gambar'), findsOneWidget);
    expect(find.textContaining('belum didukung'), findsOneWidget);
    expect(find.text('Halo'), findsOneWidget);
  });

  testWidgets('repeater: tambah/hapus baris, batas max_items, validasi wajib', (
    tester,
  ) async {
    final c = DynamicFormController(defs, {});
    await tester.pumpWidget(_wrap(c));
    final l = AppLocalizations.of(tester.element(find.byType(DynamicForm)));

    // Kosong -> judul wajib.
    expect(c.validate(l), isFalse);
    await tester.pump();
    expect(find.text('Wajib diisi'), findsOneWidget);

    // OutlinedButton.icon mengembalikan subclass privat, jadi cari lewat subtype
    // (find.byType / widgetWithText mencocokkan tipe persis dan akan gagal).
    Finder addBtn() => find.ancestor(
      of: find.text('Tambah baris'),
      matching: find.bySubtype<OutlinedButton>(),
    );
    await tester.ensureVisible(addBtn());
    await tester.tap(addBtn());
    await tester.pump();
    await tester.ensureVisible(addBtn());
    await tester.tap(addBtn());
    await tester.pump();

    expect(find.text('Butir 1'), findsOneWidget);
    expect(find.text('Butir 2'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(addBtn()).onPressed, isNull); // max 2

    // Baris kosong dibuang saat pruning.
    c.pruneEmptyRows();
    await tester.pump();
    expect(find.text('Butir 1'), findsNothing);

    // Isi satu baris + judul -> valid.
    c.set(c.values, 'title', 'Judul', 'title');
    await tester.ensureVisible(addBtn());
    await tester.tap(addBtn());
    await tester.pump();
    final rows = c.values['items'] as List<RowValue>;
    c.set(rows[0].values, 'label', 'Satu', 'items.0.label');
    expect(c.validate(l), isTrue);
  });

  const alignDef = FieldDefModel(
    key: 'text_align',
    label: 'Posisi teks',
    type: FieldType.select,
    options: [FieldOption('left', 'Kiri'), FieldOption('center', 'Tengah')],
    defaultValue: 'center',
  );
  const opacityDef = FieldDefModel(
    key: 'overlay_opacity',
    label: 'Kepekatan',
    type: FieldType.range,
    min: 0,
    maxValue: 90,
    step: 5,
    defaultValue: 55,
    suffix: '%',
  );
  const colorDef = FieldDefModel(
    key: 'overlay_color',
    label: 'Warna lapisan',
    type: FieldType.color,
    defaultValue: '#0b1020',
  );

  testWidgets('select, range, color dirender (tidak jatuh ke "belum didukung") dan memakai nilai bawaan', (
    tester,
  ) async {
    final c = DynamicFormController(const [alignDef, opacityDef, colorDef], {});
    await tester.pumpWidget(_wrap(c));
    expect(find.textContaining('belum didukung'), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('55%'), findsOneWidget);
    expect(find.text('#0b1020'), findsOneWidget);
    expect(c.values['text_align'], 'center');
    expect(c.values['overlay_opacity'], 55);
    expect(c.values['overlay_color'], '#0b1020');
  });

  testWidgets('select: memilih opsi mengubah nilai form', (tester) async {
    final c = DynamicFormController(const [alignDef], {});
    await tester.pumpWidget(_wrap(c));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kiri').last);
    await tester.pumpAndSettle();
    expect(c.values['text_align'], 'left');
  });

  testWidgets('range: menggeser slider mengubah angka dan label', (tester) async {
    final c = DynamicFormController(const [opacityDef], {'overlay_opacity': 0});
    await tester.pumpWidget(_wrap(c));
    expect(find.text('0%'), findsOneWidget);
    await tester.drag(find.byType(Slider), const Offset(2000, 0));
    await tester.pumpAndSettle();
    expect(c.values['overlay_opacity'], 90);
    expect(find.text('90%'), findsOneWidget);
  });

  testWidgets('color: format salah ditolak; pilihan cepat mengisi kolom', (tester) async {
    final c = DynamicFormController(const [colorDef], {});
    await tester.pumpWidget(_wrap(c));
    final l = AppLocalizations.of(tester.element(find.byType(DynamicForm)));

    await tester.enterText(find.byType(TextFormField), '#12');
    expect(c.values['overlay_color'], '#12');
    expect(c.validate(l), isFalse);
    await tester.pump();
    expect(find.text(l.validationColor), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('#f5b400'));
    await tester.pump();
    expect(c.values['overlay_color'], '#f5b400');
    expect(c.validate(l), isTrue);
    expect(find.text('#f5b400'), findsOneWidget);
  });

  testWidgets('field Markdown: pratinjau menampilkan "###" sebagai judul, bukan teks mentah', (
    tester,
  ) async {
    const bodyDef = FieldDefModel(
      key: 'body',
      label: 'Isi',
      type: FieldType.textarea,
      markdown: true,
      hint: 'Boleh pakai format sederhana.',
    );
    final c = DynamicFormController(const [bodyDef], {
      'body': '### Visi\n\nKami **melayani**',
    });
    await tester.pumpWidget(_wrap(c));
    await tester.tap(find.text('Pratinjau'));
    await tester.pumpAndSettle();
    expect(find.text('Visi'), findsOneWidget);
    expect(find.text('Kami melayani'), findsOneWidget);
    expect(find.text('Boleh pakai format sederhana.'), findsOneWidget);
  });

  testWidgets('textarea biasa tanpa penanda markdown tidak punya pratinjau', (tester) async {
    const plain = FieldDefModel(key: 'subtitle', label: 'Subjudul', type: FieldType.textarea);
    final c = DynamicFormController(const [plain], {});
    await tester.pumpWidget(_wrap(c));
    expect(find.text('Pratinjau'), findsNothing);
  });
  testWidgets('repeater: kontrol urutan berlabel, Turun memindah kartu, Pindah ke… memilih posisi', (
    tester,
  ) async {
    final c = DynamicFormController(defs, {
      'items': [
        {'label': 'Satu'},
        {'label': 'Dua'},
      ],
    });
    await tester.pumpWidget(_wrap(c));

    // Dua kartu: tiap kartu menampilkan posisinya + tombol Naik/Turun berlabel.
    expect(find.text('Urutan 1 dari 2'), findsOneWidget);
    expect(find.text('Urutan 2 dari 2'), findsOneWidget);
    expect(find.text('Naik'), findsNWidgets(2));
    expect(find.text('Turun'), findsNWidgets(2));

    final rows = c.values['items'] as List<RowValue>;
    expect(rows.map((r) => r.values['label']), ['Satu', 'Dua']);

    await tester.tap(find.text('Turun').first);
    await tester.pumpAndSettle();
    expect(rows.map((r) => r.values['label']), ['Dua', 'Satu']);

    // Pindah ke… -> lembar pilihan posisi; pilih urutan 2 untuk kartu pertama.
    await tester.tap(find.text('Pindah ke…').first);
    await tester.pumpAndSettle();
    expect(find.text('Pindahkan ke urutan berapa?'), findsOneWidget);
    // 'Satu' juga ada di isian teks kartu: batasi pencarian ke baris lembar pilihan.
    await tester.tap(
      find.descendant(of: find.byType(ListTile), matching: find.text('Satu')),
    );
    await tester.pumpAndSettle();
    expect(rows.map((r) => r.values['label']), ['Satu', 'Dua']);
  });

  testWidgets('repeater dengan satu kartu tidak menampilkan kontrol urutan', (tester) async {
    final c = DynamicFormController(defs, {
      'items': [
        {'label': 'Satu'},
      ],
    });
    await tester.pumpWidget(_wrap(c));
    expect(find.text('Urutan 1 dari 1'), findsNothing);
    expect(find.text('Naik'), findsNothing);
  });
}
