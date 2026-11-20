part of 'register_bloc.dart';

@blocFreezed
sealed class RegisterEvent with _$RegisterEvent {
  const factory RegisterEvent.register(RegisterRequestModel request) =
      _Register;
}
