part of 'logout_bloc.dart';

@blocFreezed
sealed class LogoutEvent with _$LogoutEvent {
  const factory LogoutEvent.logout() = _Logout;
}
