import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/sections_local_datasource.dart';
import 'package:compro_builder/data/datasources/sections_remote_datasource.dart';
import 'package:compro_builder/data/model/response/section_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sections_event.dart';
part 'sections_state.dart';
part 'sections_bloc.freezed.dart';

/// Semua mutasi daftar (toggle/move/delete/add) diproses berurutan supaya
/// rollback optimistic tidak saling menimpa. Event lain ditangani handler
/// masing-masing.
bool _isMutation(SectionsEvent e) =>
    e is _Toggle || e is _Move || e is _Delete || e is _Add;

/// Antrean berurutan (tanpa menambah dependency bloc_concurrency) khusus mutasi.
EventTransformer<SectionsEvent> _sequentialMutations() =>
    (events, mapper) => events.where(_isMutation).asyncExpand(mapper);

/// Daftar section SATU situs. Dibuat per halaman lewat BlocProvider(create:)
/// supaya state tidak tertukar antar situs.
///
/// Offline-first: bila jaringan gagal (ApiFailure tanpa statusCode) dan ada
/// cache, tampilkan cache dengan `fromCache = true`.
/// toggle/move/delete bersifat optimistic dengan rollback bila gagal.
class SectionsBloc extends Bloc<SectionsEvent, SectionsState> {
  final String slug;
  final SectionsRemoteDatasource remoteDatasource;
  final SectionsLocalDatasource localDatasource;

  /// Menolak respons basi (muat ulang yang lebih baru sudah dimulai).
  int _requestId = 0;

  SectionsBloc(
    this.remoteDatasource,
    this.localDatasource, {
    required this.slug,
  }) : super(const SectionsState.initial()) {
    on<_Fetch>(_onFetch);
    on<_Refresh>(_onRefresh);
    on<_SectionReplaced>(_onSectionReplaced);
    on<SectionsEvent>(_onMutation, transformer: _sequentialMutations());
  }

  // ─── Muat ───────────────────────────────────────────────────────────────

  Future<void> _onFetch(_Fetch event, Emitter<SectionsState> emit) async {
    final requestId = ++_requestId;
    emit(const SectionsState.loading());
    await _load(requestId, emit, previous: null);
  }

  Future<void> _onRefresh(_Refresh event, Emitter<SectionsState> emit) async {
    final requestId = ++_requestId;
    final previous = _view;
    if (previous == null) emit(const SectionsState.loading());
    await _load(requestId, emit, previous: previous);
  }

  Future<void> _load(
    int requestId,
    Emitter<SectionsState> emit, {
    required SectionsViewData? previous,
  }) async {
    final result = await remoteDatasource.list(slug);
    if (requestId != _requestId) return;

    await result.fold<Future<void>>(
      (failure) async {
        if (previous != null) {
          // Data lama tetap tampil; galat hanya untuk snackbar.
          emit(SectionsState.loaded(previous.copyWith(actionFailure: failure)));
          return;
        }
        if (failure.statusCode == null) {
          final cached = await _readCache();
          if (requestId != _requestId) return;
          if (cached != null) {
            emit(
              SectionsState.loaded(
                SectionsViewData(data: cached, fromCache: true),
              ),
            );
            return;
          }
        }
        emit(SectionsState.error(failure));
      },
      (data) async {
        await _writeCache(data);
        emit(SectionsState.loaded(SectionsViewData(data: data)));
      },
    );
  }

  // ─── Mutasi (berurutan) ─────────────────────────────────────────────────

  Future<void> _onMutation(
    SectionsEvent event,
    Emitter<SectionsState> emit,
  ) {
    switch (event) {
      case _Toggle(:final id):
        return _toggle(id, emit);
      case _Move(:final id, :final up):
        return _move(id, up, emit);
      case _Delete(:final id):
        return _delete(id, emit);
      case _Add(:final type):
        return _add(type, emit);
      default:
        return Future<void>.value();
    }
  }

  Future<void> _toggle(int id, Emitter<SectionsState> emit) async {
    final current = _view;
    if (current == null) return;
    final sections = current.data.sections;
    final index = sections.indexWhere((s) => s.id == id);
    if (index < 0 || sections[index].locked) return;

    final requestId = _requestId;
    emit(
      SectionsState.loaded(
        current.copyWith(
          data: current.data.copyWith(
            sections: [
              for (final s in sections)
                s.id == id ? s.copyWith(isEnabled: !s.isEnabled) : s,
            ],
          ),
        ),
      ),
    );

    final result = await remoteDatasource.toggle(slug, id);
    if (requestId != _requestId) return;

    final now = _view ?? current;
    await result.fold<Future<void>>(
      (failure) async => emit(
        SectionsState.loaded(
          now.copyWith(data: current.data, actionFailure: failure),
        ),
      ),
      (server) async {
        final data = now.data.copyWith(
          sections: [
            for (final s in now.data.sections) s.id == server.id ? server : s,
          ],
        );
        emit(SectionsState.loaded(now.copyWith(data: data)));
        await _writeCache(data);
      },
    );
  }

  Future<void> _move(int id, bool up, Emitter<SectionsState> emit) async {
    final current = _view;
    if (current == null) return;
    final list = [...current.data.sections];
    final i = list.indexWhere((s) => s.id == id);
    final j = up ? i - 1 : i + 1;
    if (i < 0 || j < 0 || j >= list.length) return;
    if (list[i].locked || list[j].locked) return;

    final requestId = _requestId;
    final swapped = list[i];
    list[i] = list[j];
    list[j] = swapped;
    emit(
      SectionsState.loaded(
        current.copyWith(data: current.data.copyWith(sections: list)),
      ),
    );

    final result = await remoteDatasource.move(slug, id, up: up);
    if (requestId != _requestId) return;

    final now = _view ?? current;
    await result.fold<Future<void>>(
      (failure) async => emit(
        SectionsState.loaded(
          now.copyWith(data: current.data, actionFailure: failure),
        ),
      ),
      (server) async {
        // Backend membalas daftar lengkap yang sudah terurut: itu yang benar.
        emit(
          SectionsState.loaded(now.copyWith(data: server, fromCache: false)),
        );
        await _writeCache(server);
      },
    );
  }

  Future<void> _delete(int id, Emitter<SectionsState> emit) async {
    final current = _view;
    if (current == null) return;
    final sections = current.data.sections;
    if (!sections.any((s) => s.id == id)) return;

    final requestId = _requestId;
    final remaining = sections.where((s) => s.id != id).toList();
    final used = current.data.used - 1;
    final optimistic = current.data.copyWith(
      sections: remaining,
      used: used < 0 ? 0 : used,
    );
    emit(SectionsState.loaded(current.copyWith(data: optimistic)));

    final result = await remoteDatasource.delete(slug, id);
    if (requestId != _requestId) return;

    final now = _view ?? current;
    await result.fold<Future<void>>(
      (failure) async => emit(
        SectionsState.loaded(
          now.copyWith(data: current.data, actionFailure: failure),
        ),
      ),
      (_) async => _writeCache(optimistic),
    );
  }

  Future<void> _add(SectionTypeModel type, Emitter<SectionsState> emit) async {
    final current = _view;
    if (current == null || current.isAdding) return;

    final requestId = _requestId;
    emit(SectionsState.loaded(current.copyWith(isAdding: true)));

    final added = await remoteDatasource.add(slug, type);
    if (requestId != _requestId) return;

    final failure = added.fold<ApiFailure?>((l) => l, (_) => null);
    final section = added.fold<SectionModel?>((_) => null, (r) => r);
    if (failure != null || section == null) {
      final now = _view ?? current;
      emit(
        SectionsState.loaded(
          now.copyWith(
            isAdding: false,
            actionFailure:
                failure ?? const ApiFailure('Gagal menambahkan section.'),
          ),
        ),
      );
      return;
    }

    // Penggunaan kuota + daftar tipe yang bisa ditambah berubah: muat ulang.
    final refreshed = await remoteDatasource.list(slug);
    if (requestId != _requestId) return;

    final now = _view ?? current;
    await refreshed.fold<Future<void>>(
      (_) async {
        // Penambahan sudah berhasil; pakai hasilnya walau muat ulang gagal.
        final data = now.data.copyWith(
          sections: [...now.data.sections, section],
          used: now.data.used + 1,
        );
        emit(
          SectionsState.loaded(
            now.copyWith(
              data: data,
              isAdding: false,
              notice: SectionsNotice.sectionAdded,
            ),
          ),
        );
        await _writeCache(data);
      },
      (data) async {
        emit(
          SectionsState.loaded(
            SectionsViewData(data: data, notice: SectionsNotice.sectionAdded),
          ),
        );
        await _writeCache(data);
      },
    );
  }

  Future<void> _onSectionReplaced(
    _SectionReplaced event,
    Emitter<SectionsState> emit,
  ) async {
    final current = _view;
    if (current == null) return;
    final data = current.data.copyWith(
      sections: [
        for (final s in current.data.sections)
          s.id == event.section.id ? event.section : s,
      ],
    );
    emit(SectionsState.loaded(current.copyWith(data: data)));
    await _writeCache(data);
  }

  // ─── Util ───────────────────────────────────────────────────────────────

  SectionsViewData? get _view {
    final s = state;
    return s is _Loaded ? s.view : null;
  }

  Future<SectionsDataModel?> _readCache() async {
    try {
      return await localDatasource.read(slug);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(SectionsDataModel data) async {
    try {
      await localDatasource.write(slug, data);
    } catch (_) {
      // Cache bersifat tambahan; abaikan galat tulis.
    }
  }
}
