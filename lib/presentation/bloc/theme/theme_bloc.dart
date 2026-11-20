import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/theme_remote_datasource.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/data/model/response/theme_response_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme_event.dart';
part 'theme_state.dart';
part 'theme_bloc.freezed.dart';

/// Pilihan warna SATU situs; dibuat per halaman lewat BlocProvider(create:).
/// Tanpa cache offline: warna hanya bisa diubah saat online. Daftar warna dan
/// aturannya dari server; aplikasi hanya menampilkan dan mengirim kodenya.
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final String slug;
  final ThemeRemoteDatasource remoteDatasource;

  ThemeBloc(this.remoteDatasource, {required this.slug})
    : super(const ThemeState.initial()) {
    on<_Load>(_onLoad);
    on<_Select>(_onSelect);
    on<_Save>(_onSave);
  }

  Future<void> _onLoad(_Load event, Emitter<ThemeState> emit) async {
    emit(const ThemeState.loading());
    final result = await remoteDatasource.list(slug);
    result.fold(
      (failure) => emit(ThemeState.error(failure)),
      (data) => emit(
        ThemeState.loaded(
          ThemeViewData(
            themes: data.themes,
            current: data.current,
            selected: data.current,
          ),
        ),
      ),
    );
  }

  void _onSelect(_Select event, Emitter<ThemeState> emit) {
    final s = state;
    if (s is! _Loaded || s.data.isSaving) return;
    if (!s.data.themes.any((t) => t.code == event.code)) return;
    emit(ThemeState.loaded(s.data.copyWith(selected: event.code)));
  }

  Future<void> _onSave(_Save event, Emitter<ThemeState> emit) async {
    final s = state;
    if (s is! _Loaded || s.data.isSaving || !s.data.isDirty) return;
    final current = s.data;
    emit(ThemeState.loaded(current.copyWith(isSaving: true)));

    final result = await remoteDatasource.update(slug, current.selected);
    result.fold(
      (failure) => emit(
        ThemeState.loaded(
          current.copyWith(isSaving: false, saveFailure: failure),
        ),
      ),
      (tenant) => emit(
        ThemeState.loaded(
          current.copyWith(
            isSaving: false,
            current: current.selected,
            savedTenant: tenant,
          ),
        ),
      ),
    );
  }
}
