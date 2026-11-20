part of 'profile_bloc.dart';

@blocFreezed
sealed class ProfileEvent with _$ProfileEvent {
  const factory ProfileEvent.load() = _Load;
}
