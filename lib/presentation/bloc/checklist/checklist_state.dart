part of 'checklist_bloc.dart';

class ChecklistViewData {
  final ChecklistResponseModel data;

  /// Galat sesaat saat muat ulang (data lama tetap tampil).
  final ApiFailure? refreshFailure;

  const ChecklistViewData({required this.data, this.refreshFailure});
}

@blocFreezed
sealed class ChecklistState with _$ChecklistState {
  const factory ChecklistState.initial() = _Initial;
  const factory ChecklistState.loading() = _Loading;
  const factory ChecklistState.loaded(ChecklistViewData data) = _Loaded;
  const factory ChecklistState.error(ApiFailure failure) = _Error;
}
