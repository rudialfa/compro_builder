part of 'forgot_password_bloc.dart';

@blocFreezed
sealed class ForgotPasswordState with _$ForgotPasswordState {
  const factory ForgotPasswordState.initial() = _Initial;
  const factory ForgotPasswordState.loading() = _Loading;

  /// Pesan dari server (jawabannya selalu sama, ada atau tidaknya akun).
  const factory ForgotPasswordState.sent(String message) = _Sent;
  const factory ForgotPasswordState.error(ApiFailure failure) = _Error;
}
