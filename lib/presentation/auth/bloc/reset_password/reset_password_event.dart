part of 'reset_password_bloc.dart';

@blocFreezed
sealed class ResetPasswordEvent with _$ResetPasswordEvent {

  /// Atur ulang password dengan token dari email. Diabaikan bila masih berjalan.
  const factory ResetPasswordEvent.submit(ResetPasswordRequestModel request) =
      _Submit;
}
