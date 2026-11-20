part of 'settings_bloc.dart';

@blocFreezed
sealed class SettingsEvent with _$SettingsEvent {
  const factory SettingsEvent.load() = _Load;
  const factory SettingsEvent.save(SettingsChangesModel changes) = _Save;
}
