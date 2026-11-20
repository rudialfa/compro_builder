import 'package:compro_builder/data/model/response/field_def_model.dart';
import 'package:compro_builder/data/model/response/section_model.dart';
import 'package:compro_builder/presentation/pages/publish/publish_checklist.dart';
import 'package:flutter_test/flutter_test.dart';

const _title = FieldDefModel(key: 'title', label: 'Judul', type: FieldType.text, required: true);
const _image = FieldDefModel(key: 'photo', label: 'Foto', type: FieldType.image, required: true);
const _optional = FieldDefModel(key: 'note', label: 'Catatan', type: FieldType.text);
const _toggle = FieldDefModel(key: 'on', label: 'Aktif', type: FieldType.toggle, required: true);

SectionModel _s(
  int id, {
  bool enabled = true,
  bool sample = false,
  bool locked = false,
  List<FieldDefModel> fields = const [_title],
  Map<String, dynamic> content = const {'title': 'Halo'},
}) => SectionModel(
  id: id,
  type: 'about',
  name: 'Section $id',
  isEnabled: enabled,
  isSample: sample,
  locked: locked,
  fields: fields,
  content: content,
);

void main() {
  test('tanpa section tampil -> noSections', () {
    expect(buildChecklist([]).single.kind, ChecklistKind.noSections);
    expect(buildChecklist([_s(1, enabled: false), _s(2, locked: true)]).single.kind, ChecklistKind.noSections);
  });

  test('semua terisi -> kosong', () {
    expect(buildChecklist([_s(1)]), isEmpty);
  });

  test('section contoh ditandai', () {
    final r = buildChecklist([_s(1, sample: true)]);
    expect(r.single.kind, ChecklistKind.sample);
    expect(r.single.section?.id, 1);
  });

  test('field wajib kosong (spasi saja dianggap kosong) dilaporkan dengan labelnya', () {
    final r = buildChecklist([_s(1, content: {'title': '   '})]);
    expect(r.single.kind, ChecklistKind.missingRequired);
    expect(r.single.fields, ['Judul']);
  });

  test('gambar wajib: kosong dilaporkan, URL lama dianggap terisi', () {
    final fields = [_title, _image];
    final missing = buildChecklist([_s(1, fields: fields)]);
    expect(missing.single.fields, ['Foto']);
    final filled = buildChecklist([
      _s(1, fields: fields, content: {'title': 'x', 'photo': '/storage/a.jpg'}),
    ]);
    expect(filled, isEmpty);
  });

  test('field opsional dan toggle tidak dihitung', () {
    expect(buildChecklist([_s(1, fields: [_optional, _toggle], content: const {})]), isEmpty);
  });

  test('section nonaktif atau terkunci dilewati; contoh + wajib kosong = dua butir', () {
    final r = buildChecklist([
      _s(1, enabled: false, content: const {}),
      _s(2, locked: true, content: const {}),
      _s(3, sample: true, content: const {}),
    ]);
    expect(r.map((e) => e.kind), [ChecklistKind.sample, ChecklistKind.missingRequired]);
    expect(r.every((e) => e.section?.id == 3), isTrue);
  });
}
