part of 'reset_password_bloc.dart';

@blocFreezed
sealed class ResetPasswordState with _$ResetPasswordState {
  const factory ResetPasswordState.initial() = _Initial;
  const factory ResetPasswordState.loading() = _Loading;

  /// Pesan sukses dari server. Semua token login lama dicabut server, jadi
  /// pengguna kembali ke layar masuk.
  const factory ResetPasswordState.success(String message) = _Success;
  const factory ResetPasswordState.error(ApiFailure failure) = _Error;
}
