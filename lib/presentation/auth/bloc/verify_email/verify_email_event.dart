part of 'verify_email_bloc.dart';

@blocFreezed
sealed class VerifyEmailEvent with _$VerifyEmailEvent {

  /// Kirim ulang tautan verifikasi ke email akun yang sedang masuk.
  /// Diabaikan bila permintaan sebelumnya masih berjalan.
  const factory VerifyEmailEvent.resend() = _Resend;
}
