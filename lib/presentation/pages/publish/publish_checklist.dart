import 'package:compro_builder/data/model/response/field_def_model.dart';
import 'package:compro_builder/data/model/response/section_model.dart';
import 'package:compro_builder/presentation/pages/sections/dynamic_form/form_values.dart';

enum ChecklistKind { noSections, sample, missingRequired }

class ChecklistItem {
  final ChecklistKind kind;
  final SectionModel? section;

  /// Label field wajib yang masih kosong (hanya untuk [ChecklistKind.missingRequired]).
  final List<String> fields;

  const ChecklistItem(this.kind, {this.section, this.fields = const []});
}

/// Checklist sebelum menayangkan, dari section yang tampil dan tidak terkunci:
/// penanda `is_sample` dan field wajib tingkat atas yang masih kosong.
/// Hanya peringatan: pengguna tetap boleh menayangkan.
List<ChecklistItem> buildChecklist(List<SectionModel> sections) {
  final active = sections.where((s) => s.isEnabled && !s.locked).toList();
  if (active.isEmpty) return const [ChecklistItem(ChecklistKind.noSections)];

  final out = <ChecklistItem>[];
  for (final s in active) {
    if (s.isSample) out.add(ChecklistItem(ChecklistKind.sample, section: s));
    final values = DynamicFormController.initValues(s.fields, s.content);
    final missing = [
      for (final d in s.fields)
        if (d.required &&
            d.type != FieldType.toggle &&
            d.type != FieldType.unknown &&
            isRowEmpty([d], values))
          d.label,
    ];
    if (missing.isNotEmpty) {
      out.add(
        ChecklistItem(
          ChecklistKind.missingRequired,
          section: s,
          fields: missing,
        ),
      );
    }
  }
  return out;
}
