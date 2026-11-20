import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/sections_remote_datasource.dart';
import 'package:compro_builder/data/model/response/section_model.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'section_editor_event.dart';
part 'section_editor_state.dart';
part 'section_editor_bloc.freezed.dart';

/// Gagal mengunduh gambar lama saat membangun payload.
class _FetchFailed implements Exception {
  final ApiFailure failure;
  const _FetchFailed(this.failure);
}

/// Editor SATU section. Dibuat per halaman lewat BlocProvider(create:) supaya
/// state tidak tertukar saat halaman ditumpuk.
///
/// [initial] = salinan dari daftar: dipakai bila detail gagal dimuat karena
/// jaringan (offline-first).
class SectionEditorBloc extends Bloc<SectionEditorEvent, SectionEditorState> {
  final String slug;
  final int sectionId;
  final SectionModel? initial;
  final SectionsRemoteDatasource remoteDatasource;

  SectionEditorBloc(
    this.remoteDatasource, {
    required this.slug,
    required this.sectionId,
    this.initial,
  }) : super(const SectionEditorState.initial()) {
    on<_Load>(_onLoad);
    on<_Save>(_onSave);
  }

  Future<void> _onLoad(_Load event, Emitter<SectionEditorState> emit) async {
    emit(const SectionEditorState.loading());
    final result = await remoteDatasource.detail(slug, sectionId);
    result.fold(
      (failure) {
        final fallback = initial;
        if (failure.statusCode == null &&
            fallback != null &&
            !fallback.locked) {
          emit(
            SectionEditorState.loaded(
              SectionEditorData(section: fallback, fromList: true),
            ),
          );
          return;
        }
        emit(SectionEditorState.error(failure));
      },
      (section) =>
          emit(SectionEditorState.loaded(SectionEditorData(section: section))),
    );
  }

  Future<void> _onSave(_Save event, Emitter<SectionEditorState> emit) async {
    final current = _data;
    if (current == null || current.isSaving) return;
    emit(SectionEditorState.loaded(current.copyWith(isSaving: true)));

    Map<String, dynamic> payload;
    try {
      payload = await event.build((url) async {
        final bytes = await remoteDatasource.downloadBytes(url);
        return bytes.fold(
          (failure) => throw _FetchFailed(failure),
          (data) => data,
        );
      });
    } on _FetchFailed catch (e) {
      _failSave(emit, current, e.failure);
      return;
    } catch (_) {
      _failSave(
        emit,
        current,
        const ApiFailure('Gagal menyiapkan data. Silakan coba lagi.'),
      );
      return;
    }

    final result = await remoteDatasource.update(slug, sectionId, payload);
    result.fold(
      (failure) => _failSave(emit, current, failure),
      (section) => emit(
        SectionEditorState.loaded(
          SectionEditorData(section: section, savedSection: section),
        ),
      ),
    );
  }

  void _failSave(
    Emitter<SectionEditorState> emit,
    SectionEditorData current,
    ApiFailure failure,
  ) {
    emit(
      SectionEditorState.loaded(
        current.copyWith(isSaving: false, saveFailure: failure),
      ),
    );
  }

  SectionEditorData? get _data {
    final s = state;
    return s is _Loaded ? s.data : null;
  }
}
