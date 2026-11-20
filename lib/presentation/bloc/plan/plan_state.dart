part of 'plan_bloc.dart';

class PlanViewData {
  final PlanInfoModel plan;

  /// Galat sesaat saat muat ulang (data lama tetap tampil).
  final ApiFailure? refreshFailure;

  /// True selama satu emisi setelah muat ulang yang diminta [PlanEvent.refresh] announce.
  final bool refreshed;

  const PlanViewData({
    required this.plan,
    this.refreshFailure,
    this.refreshed = false,
  });
}

@blocFreezed
sealed class PlanState with _$PlanState {
  const factory PlanState.initial() = _Initial;
  const factory PlanState.loading() = _Loading;
  const factory PlanState.loaded(PlanViewData data) = _Loaded;
  const factory PlanState.error(ApiFailure failure) = _Error;
}
