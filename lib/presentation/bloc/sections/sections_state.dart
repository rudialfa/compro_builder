part of 'sections_bloc.dart';

/// Pesan sukses sesaat; teksnya diambil dari l10n di lapisan UI.
enum SectionsNotice { sectionAdded }

/// Data daftar section + penanda tampilan.
class SectionsViewData {
  final SectionsDataModel data;

  /// True bila data berasal dari cache (offline-first).
  final bool fromCache;

  /// True selama POST tambah section berjalan (menonaktifkan tombol tambah).
  final bool isAdding;

  /// Galat sesaat untuk snackbar (data lama tetap tampil).
  final ApiFailure? actionFailure;

  /// Pesan sukses sesaat untuk snackbar.
  final SectionsNotice? notice;

  const SectionsViewData({
    required this.data,
    this.fromCache = false,
    this.isAdding = false,
    this.actionFailure,
    this.notice,
  });

  /// [actionFailure] dan [notice] sengaja tidak dibawa: keduanya hanya
  /// berlaku untuk satu emisi.
  SectionsViewData copyWith({
    SectionsDataModel? data,
    bool? fromCache,
    bool? isAdding,
    ApiFailure? actionFailure,
    SectionsNotice? notice,
  }) => SectionsViewData(
    data: data ?? this.data,
    fromCache: fromCache ?? this.fromCache,
    isAdding: isAdding ?? this.isAdding,
    actionFailure: actionFailure,
    notice: notice,
  );
}

@blocFreezed
sealed class SectionsState with _$SectionsState {
  const factory SectionsState.initial() = _Initial;
  const factory SectionsState.loading() = _Loading;
  const factory SectionsState.loaded(SectionsViewData view) = _Loaded;
  const factory SectionsState.error(ApiFailure failure) = _Error;
}
