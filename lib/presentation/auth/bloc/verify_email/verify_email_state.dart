part of 'verify_email_bloc.dart';

@blocFreezed
sealed class VerifyEmailState with _$VerifyEmailState {
  const factory VerifyEmailState.initial() = _Initial;
  const factory VerifyEmailState.loading() = _Loading;

  /// Balasan server: `message` + `verified` (true bila email ternyata sudah terverifikasi).
  const factory VerifyEmailState.sent(AccountMessageModel result) = _Sent;
  const factory VerifyEmailState.error(ApiFailure failure) = _Error;
}
