import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/messages_remote_datasource.dart';
import 'package:compro_builder/data/model/response/contact_message_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'messages_event.dart';
part 'messages_state.dart';
part 'messages_bloc.freezed.dart';

/// Mutasi (toggleRead/delete) diproses berurutan agar rollback tidak saling
/// menimpa. Event lain ditangani handler masing-masing.
bool _isMutation(MessagesEvent e) => e is _ToggleRead || e is _Delete;

/// Antrean berurutan (tanpa menambah dependency bloc_concurrency) khusus mutasi.
EventTransformer<MessagesEvent> _sequentialMutations() =>
    (events, mapper) => events.where(_isMutation).asyncExpand(mapper);

/// Pesan masuk SATU situs, berpaginasi. Dibuat per halaman; halaman detail
/// memakai bloc yang sama (BlocProvider.value) supaya hanya ada satu sumber
/// kebenaran untuk status dibaca/hapus. Tidak ada endpoint detail di backend.
///
/// toggleRead/delete bersifat optimistic dengan rollback bila gagal.
class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  static const perPage = 20;

  final String slug;
  final MessagesRemoteDatasource remoteDatasource;

  /// Menolak respons basi (muat ulang yang lebih baru sudah dimulai).
  int _requestId = 0;

  MessagesBloc(this.remoteDatasource, {required this.slug})
    : super(const MessagesState.initial()) {
    on<_Load>(_onLoad);
    on<_Refresh>(_onRefresh);
    on<_LoadMore>(_onLoadMore);
    on<MessagesEvent>(_onMutation, transformer: _sequentialMutations());
  }

  // ─── Muat ───────────────────────────────────────────────────────────────

  Future<void> _onLoad(_Load event, Emitter<MessagesState> emit) async {
    final id = ++_requestId;
    emit(const MessagesState.loading());
    final result = await remoteDatasource.list(slug, page: 1, perPage: perPage);
    if (id != _requestId) return;
    result.fold(
      (failure) => emit(MessagesState.error(failure)),
      (page) => emit(MessagesState.loaded(_fromPage(page))),
    );
  }

  Future<void> _onRefresh(_Refresh event, Emitter<MessagesState> emit) async {
    final id = ++_requestId;
    final previous = _view;
    if (previous == null) emit(const MessagesState.loading());
    final result = await remoteDatasource.list(slug, page: 1, perPage: perPage);
    if (id != _requestId) return;
    result.fold(
      (failure) => emit(
        previous == null
            ? MessagesState.error(failure)
            : MessagesState.loaded(previous.copyWith(actionFailure: failure)),
      ),
      (page) => emit(MessagesState.loaded(_fromPage(page))),
    );
  }

  Future<void> _onLoadMore(_LoadMore event, Emitter<MessagesState> emit) async {
    final current = _view;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    final id = _requestId;
    emit(
      MessagesState.loaded(
        current.copyWith(isLoadingMore: true, loadMoreFailure: null),
      ),
    );

    final result = await remoteDatasource.list(
      slug,
      page: current.page + 1,
      perPage: perPage,
    );
    if (id != _requestId) return;

    final now = _view ?? current;
    result.fold(
      (failure) => emit(
        MessagesState.loaded(
          now.copyWith(isLoadingMore: false, loadMoreFailure: failure),
        ),
      ),
      (page) {
        final known = now.items.map((m) => m.id).toSet();
        emit(
          MessagesState.loaded(
            now.copyWith(
              items: [
                ...now.items,
                ...page.items.where((m) => !known.contains(m.id)),
              ],
              page: current.page + 1,
              hasMore: page.hasMore && page.items.isNotEmpty,
              total: page.total,
              isLoadingMore: false,
            ),
          ),
        );
      },
    );
  }

  // ─── Mutasi (berurutan) ─────────────────────────────────────────────────

  Future<void> _onMutation(
    MessagesEvent event,
    Emitter<MessagesState> emit,
  ) {
    switch (event) {
      case _ToggleRead(:final id, :final onlyIfUnread):
        return _toggleRead(id, onlyIfUnread, emit);
      case _Delete(:final id):
        return _delete(id, emit);
      default:
        return Future<void>.value();
    }
  }

  Future<void> _toggleRead(
    int id,
    bool onlyIfUnread,
    Emitter<MessagesState> emit,
  ) async {
    final current = _view;
    if (current == null) return;
    final index = current.items.indexWhere((m) => m.id == id);
    if (index < 0) return;
    final before = current.items[index].isRead;
    if (onlyIfUnread && before) return;

    final requestId = _requestId;
    emit(
      MessagesState.loaded(
        current.copyWith(items: _setRead(current.items, id, !before)),
      ),
    );

    final result = await remoteDatasource.toggleRead(slug, id);
    if (requestId != _requestId) return;

    final now = _view;
    if (now == null) return;
    result.fold(
      (failure) => emit(
        MessagesState.loaded(
          now.copyWith(
            items: _setRead(now.items, id, before),
            actionFailure: failure,
          ),
        ),
      ),
      // Ikuti nilai dari server (sumber kebenaran).
      (read) => emit(
        MessagesState.loaded(
          now.copyWith(
            items: _setRead(now.items, id, read),
            unreadChanged: true,
          ),
        ),
      ),
    );
  }

  Future<void> _delete(int id, Emitter<MessagesState> emit) async {
    final current = _view;
    if (current == null) return;
    final index = current.items.indexWhere((m) => m.id == id);
    if (index < 0) return;
    final removed = current.items[index];

    final requestId = _requestId;
    emit(
      MessagesState.loaded(
        current.copyWith(
          items: [...current.items]..removeAt(index),
          total: current.total > 0 ? current.total - 1 : 0,
        ),
      ),
    );

    final result = await remoteDatasource.delete(slug, id);
    if (requestId != _requestId) return;

    final now = _view;
    if (now == null) return;
    result.fold(
      (failure) {
        final items = [...now.items]
          ..insert(index.clamp(0, now.items.length), removed);
        emit(
          MessagesState.loaded(
            now.copyWith(
              items: items,
              total: now.total + 1,
              actionFailure: failure,
            ),
          ),
        );
      },
      (_) => emit(
        MessagesState.loaded(
          now.copyWith(notice: MessagesNotice.deleted, unreadChanged: true),
        ),
      ),
    );
  }

  // ─── Util ───────────────────────────────────────────────────────────────

  MessagesViewData _fromPage(MessagesPageModel page) => MessagesViewData(
    items: page.items,
    page: page.page,
    hasMore: page.hasMore,
    total: page.total,
  );

  List<ContactMessageModel> _setRead(
    List<ContactMessageModel> items,
    int id,
    bool read,
  ) => [for (final m in items) m.id == id ? m.copyWith(isRead: read) : m];

  MessagesViewData? get _view {
    final s = state;
    return s is _Loaded ? s.view : null;
  }
}
