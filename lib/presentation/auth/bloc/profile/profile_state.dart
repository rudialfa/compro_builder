part of 'profile_bloc.dart';

@blocFreezed
sealed class ProfileState with _$ProfileState {
  const factory ProfileState.initial() = _Initial;
  const factory ProfileState.loading() = _Loading;
  const factory ProfileState.loaded(UserModel user) = _Loaded;
  const factory ProfileState.error(ApiFailure failure) = _Error;
}
