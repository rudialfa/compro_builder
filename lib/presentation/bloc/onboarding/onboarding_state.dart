part of 'onboarding_bloc.dart';

class OnboardingViewData {
  final OnboardingResponseModel data;

  /// Sedang mengirim (submit atau skip).
  final bool isBusy;

  /// Galat sesaat; 422 membawa fieldErrors (name, subtitle, whatsapp, theme).
  final ApiFailure? failure;

  /// Situs terbaru dari server setelah submit/skip sukses (satu emisi);
  /// halaman meneruskannya ke SitesBloc lalu menutup diri.
  final TenantModel? doneTenant;

  /// True bila [doneTenant] berasal dari skip (bukan submit).
  final bool wasSkipped;

  const OnboardingViewData({
    required this.data,
    this.isBusy = false,
    this.failure,
    this.doneTenant,
    this.wasSkipped = false,
  });

  /// [failure], [doneTenant], dan [wasSkipped] sengaja tidak dibawa (satu emisi).
  OnboardingViewData copyWith({
    bool? isBusy,
    ApiFailure? failure,
    TenantModel? doneTenant,
    bool wasSkipped = false,
  }) => OnboardingViewData(
    data: data,
    isBusy: isBusy ?? this.isBusy,
    failure: failure,
    doneTenant: doneTenant,
    wasSkipped: wasSkipped,
  );
}

@blocFreezed
sealed class OnboardingState with _$OnboardingState {
  const factory OnboardingState.initial() = _Initial;
  const factory OnboardingState.loading() = _Loading;
  const factory OnboardingState.loaded(OnboardingViewData data) = _Loaded;
  const factory OnboardingState.error(ApiFailure failure) = _Error;
}
