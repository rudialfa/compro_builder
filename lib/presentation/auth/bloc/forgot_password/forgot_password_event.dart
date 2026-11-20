part of 'forgot_password_bloc.dart';

@blocFreezed
sealed class ForgotPasswordEvent with _$ForgotPasswordEvent {

  /// Minta tautan atur ulang ke [email]. Diabaikan bila permintaan sebelumnya masih berjalan.
  const factory ForgotPasswordEvent.submit(String email) = _Submit;
}
