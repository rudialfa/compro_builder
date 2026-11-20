part of 'settings_bloc.dart';

class SettingsViewData {
  final SiteSettingsModel settings;
  final bool isSaving;

  /// Galat simpan sesaat (422 membawa fieldErrors, 429 membawa retryAfter).
  final ApiFailure? saveFailure;

  /// True selama satu emisi setelah simpan sukses.
  final bool saved;

  const SettingsViewData({
    required this.settings,
    this.isSaving = false,
    this.saveFailure,
    this.saved = false,
  });

  /// [saveFailure] dan [saved] sengaja tidak dibawa (satu emisi).
  SettingsViewData copyWith({
    SiteSettingsModel? settings,
    bool? isSaving,
    ApiFailure? saveFailure,
    bool saved = false,
  }) => SettingsViewData(
    settings: settings ?? this.settings,
    isSaving: isSaving ?? this.isSaving,
    saveFailure: saveFailure,
    saved: saved,
  );
}

@blocFreezed
sealed class SettingsState with _$SettingsState {
  const factory SettingsState.initial() = _Initial;
  const factory SettingsState.loading() = _Loading;
  const factory SettingsState.loaded(SettingsViewData data) = _Loaded;
  const factory SettingsState.error(ApiFailure failure) = _Error;
}
