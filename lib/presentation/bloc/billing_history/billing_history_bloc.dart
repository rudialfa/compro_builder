import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/billing_remote_datasource.dart';
import 'package:compro_builder/data/model/response/billing_response_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'billing_history_event.dart';
part 'billing_history_state.dart';
part 'billing_history_bloc.freezed.dart';

/// Riwayat order SATU situs (terbaru dulu), berpaginasi. Dibuat per halaman.
class BillingHistoryBloc
    extends Bloc<BillingHistoryEvent, BillingHistoryState> {
  static const perPage = 20;

  final String slug;
  final BillingRemoteDatasource remoteDatasource;

  /// Menolak respons basi (muat ulang yang lebih baru sudah dimulai).
  int _requestId = 0;

  BillingHistoryBloc(this.remoteDatasource, {required this.slug})
    : super(const BillingHistoryState.initial()) {
    on<_Load>(_onLoad);
    on<_Refresh>(_onRefresh);
    on<_LoadMore>(_onLoadMore);
  }

  BillingHistoryData _fromPage(BillingOrdersPageModel p) => BillingHistoryData(
    orders: p.orders,
    page: p.page,
    hasMore: p.hasMore,
    total: p.total,
  );

  Future<void> _onLoad(_Load event, Emitter<BillingHistoryState> emit) async {
    final id = ++_requestId;
    emit(const BillingHistoryState.loading());
    final result = await remoteDatasource.orders(slug, page: 1, perPage: perPage);
    if (id != _requestId) return;
    result.fold(
      (failure) => emit(BillingHistoryState.error(failure)),
      (page) => emit(BillingHistoryState.loaded(_fromPage(page))),
    );
  }

  Future<void> _onRefresh(
    _Refresh event,
    Emitter<BillingHistoryState> emit,
  ) async {
    final s = state;
    final previous = s is _Loaded ? s.data : null;
    final id = ++_requestId;
    if (previous == null) emit(const BillingHistoryState.loading());

    final result = await remoteDatasource.orders(slug, page: 1, perPage: perPage);
    if (id != _requestId) return;
    result.fold(
      (failure) => emit(
        previous == null
            ? BillingHistoryState.error(failure)
            : BillingHistoryState.loaded(
                previous.copyWith(refreshFailure: failure),
              ),
      ),
      (page) => emit(BillingHistoryState.loaded(_fromPage(page))),
    );
  }

  Future<void> _onLoadMore(
    _LoadMore event,
    Emitter<BillingHistoryState> emit,
  ) async {
    final s = state;
    if (s is! _Loaded) return;
    final current = s.data;
    if (!current.hasMore || current.isLoadingMore) return;
    final id = _requestId;
    emit(BillingHistoryState.loaded(current.copyWith(isLoadingMore: true)));

    final result = await remoteDatasource.orders(
      slug,
      page: current.page + 1,
      perPage: perPage,
    );
    if (id != _requestId) return;
    result.fold(
      (failure) => emit(
        BillingHistoryState.loaded(
          current.copyWith(isLoadingMore: false, loadMoreFailure: failure),
        ),
      ),
      (page) {
        // Buang duplikat bila ada order baru yang menggeser halaman.
        final known = current.orders.map((o) => o.id).toSet();
        emit(
          BillingHistoryState.loaded(
            current.copyWith(
              orders: [
                ...current.orders,
                ...page.orders.where((o) => !known.contains(o.id)),
              ],
              page: page.page,
              hasMore: page.hasMore,
              total: page.total,
              isLoadingMore: false,
            ),
          ),
        );
      },
    );
  }
}
