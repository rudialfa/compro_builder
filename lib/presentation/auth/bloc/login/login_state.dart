part of 'login_bloc.dart';

@blocFreezed
sealed class LoginState with _$LoginState {
  const factory LoginState.initial() = _Initial;
  const factory LoginState.loading() = _Loading;
  const factory LoginState.success(AuthResponseModel data) = _Success;
  const factory LoginState.error(ApiFailure failure) = _Error;
}
