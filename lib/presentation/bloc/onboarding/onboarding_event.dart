part of 'onboarding_bloc.dart';

@blocFreezed
sealed class OnboardingEvent with _$OnboardingEvent {

  /// Muat nilai awal formulir + daftar warna.
  const factory OnboardingEvent.load() = _Load;

  /// Kirim isian wizard (hero + kontak + warna dalam satu transaksi di server).
  const factory OnboardingEvent.submit(OnboardingRequestModel request) = _Submit;

  /// Lewati pengaturan awal (server menandai `skipped`).
  const factory OnboardingEvent.skip() = _Skip;
}
