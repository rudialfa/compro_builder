part of 'sections_bloc.dart';

@blocFreezed
sealed class SectionsEvent with _$SectionsEvent {

  /// Muat pertama (menampilkan loading).
  const factory SectionsEvent.fetch() = _Fetch;

  /// Muat ulang tanpa menghapus data yang sedang tampil (pull-to-refresh).
  const factory SectionsEvent.refresh() = _Refresh;

  const factory SectionsEvent.toggle(int id) = _Toggle;
  const factory SectionsEvent.move(int id, {required bool up}) = _Move;
  const factory SectionsEvent.delete(int id) = _Delete;
  const factory SectionsEvent.add(SectionTypeModel type) = _Add;

  /// Dipakai editor (Fase 3b) setelah simpan sukses, tanpa muat ulang daftar.
  const factory SectionsEvent.sectionReplaced(SectionModel section) =
      _SectionReplaced;
}
