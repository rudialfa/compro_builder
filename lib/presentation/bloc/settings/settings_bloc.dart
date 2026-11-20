import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/settings_remote_datasource.dart';
import 'package:compro_builder/data/model/request/settings_changes_model.dart';
import 'package:compro_builder/data/model/response/site_settings_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_event.dart';
part 'settings_state.dart';
part 'settings_bloc.freezed.dart';

/// Pengaturan SATU situs; dibuat per halaman lewat BlocProvider(create:).
/// Tanpa cache offline: pengaturan hanya bisa diubah saat online.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final String slug;
  final SettingsRemoteDatasource remoteDatasource;

  SettingsBloc(this.remoteDatasource, {required this.slug})
    : super(const SettingsState.initial()) {
    on<_Load>(_onLoad);
    on<_Save>(_onSave);
  }

  Future<void> _onLoad(_Load event, Emitter<SettingsState> emit) async {
    emit(const SettingsState.loading());
    final result = await remoteDatasource.get(slug);
    result.fold(
      (failure) => emit(SettingsState.error(failure)),
      (settings) =>
          emit(SettingsState.loaded(SettingsViewData(settings: settings))),
    );
  }

  Future<void> _onSave(_Save event, Emitter<SettingsState> emit) async {
    final s = state;
    if (s is! _Loaded || s.data.isSaving) return;
    final current = s.data;
    emit(SettingsState.loaded(current.copyWith(isSaving: true)));

    final result = await remoteDatasource.save(slug, event.changes);
    result.fold(
      (failure) => emit(
        SettingsState.loaded(
          current.copyWith(isSaving: false, saveFailure: failure),
        ),
      ),
      (settings) => emit(
        SettingsState.loaded(SettingsViewData(settings: settings, saved: true)),
      ),
    );
  }
}
