part of 'section_editor_bloc.dart';

/// Isi editor yang sedang tampil.
class SectionEditorData {
  final SectionModel section;

  /// True bila detail gagal dimuat karena jaringan dan yang tampil adalah
  /// salinan dari daftar (offline-first); menyimpan tetap bisa gagal.
  final bool fromList;

  final bool isSaving;

  /// Galat simpan sesaat (422 membawa fieldErrors, 429 membawa retryAfter).
  final ApiFailure? saveFailure;

  /// Terisi satu emisi saat simpan sukses; UI menutup halaman.
  final SectionModel? savedSection;

  const SectionEditorData({
    required this.section,
    this.fromList = false,
    this.isSaving = false,
    this.saveFailure,
    this.savedSection,
  });

  /// [saveFailure] dan [savedSection] sengaja tidak dibawa (satu emisi).
  SectionEditorData copyWith({
    SectionModel? section,
    bool? isSaving,
    ApiFailure? saveFailure,
    SectionModel? savedSection,
  }) => SectionEditorData(
    section: section ?? this.section,
    fromList: fromList,
    isSaving: isSaving ?? this.isSaving,
    saveFailure: saveFailure,
    savedSection: savedSection,
  );
}

@blocFreezed
sealed class SectionEditorState with _$SectionEditorState {
  const factory SectionEditorState.initial() = _Initial;
  const factory SectionEditorState.loading() = _Loading;
  const factory SectionEditorState.loaded(SectionEditorData data) = _Loaded;
  const factory SectionEditorState.error(ApiFailure failure) = _Error;
}
