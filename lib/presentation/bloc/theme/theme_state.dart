part of 'theme_bloc.dart';

class ThemeViewData {
  final List<ThemeOptionModel> themes;

  /// Kode warna yang tersimpan di server.
  final String current;

  /// Kode warna yang sedang dipilih di layar (bisa belum disimpan).
  final String selected;
  final bool isSaving;

  /// Galat simpan sesaat; pilihan tetap dipertahankan.
  final ApiFailure? saveFailure;

  /// Situs terbaru dari server setelah simpan sukses (satu emisi); halaman
  /// meneruskannya ke SitesBloc.
  final TenantModel? savedTenant;

  const ThemeViewData({
    required this.themes,
    required this.current,
    required this.selected,
    this.isSaving = false,
    this.saveFailure,
    this.savedTenant,
  });

  bool get isDirty => selected != current;

  /// [saveFailure] dan [savedTenant] sengaja tidak dibawa (satu emisi).
  ThemeViewData copyWith({
    String? current,
    String? selected,
    bool? isSaving,
    ApiFailure? saveFailure,
    TenantModel? savedTenant,
  }) => ThemeViewData(
    themes: themes,
    current: current ?? this.current,
    selected: selected ?? this.selected,
    isSaving: isSaving ?? this.isSaving,
    saveFailure: saveFailure,
    savedTenant: savedTenant,
  );
}

@blocFreezed
sealed class ThemeState with _$ThemeState {
  const factory ThemeState.initial() = _Initial;
  const factory ThemeState.loading() = _Loading;
  const factory ThemeState.loaded(ThemeViewData data) = _Loaded;
  const factory ThemeState.error(ApiFailure failure) = _Error;
}
