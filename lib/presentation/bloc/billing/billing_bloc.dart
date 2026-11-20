import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/billing_remote_datasource.dart';
import 'package:compro_builder/data/model/response/billing_response_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'billing_event.dart';
part 'billing_state.dart';
part 'billing_bloc.freezed.dart';

/// Daftar paket + harga, order pending, dan pembuatan order (checkout) untuk
/// SATU situs; dibuat per halaman. Pemilihan metode, menampilkan nomor bayar,
/// dan polling status ada di [BillingPayBloc].
class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final String slug;
  final BillingRemoteDatasource remoteDatasource;

  /// Menolak respons basi bila dua muat tumpang tindih.
  int _requestId = 0;

  BillingBloc(this.remoteDatasource, {required this.slug})
    : super(const BillingState.initial()) {
    on<_Load>(_onLoad);
    on<_Refresh>(_onRefresh);
    on<_Checkout>(_onCheckout);
  }

  Future<void> _onLoad(_Load event, Emitter<BillingState> emit) async {
    final id = ++_requestId;
    emit(const BillingState.loading());
    final result = await remoteDatasource.overview(slug);
    if (id != _requestId) return;
    result.fold(
      (failure) => emit(BillingState.error(failure)),
      (overview) => emit(BillingState.loaded(BillingViewData(overview: overview))),
    );
  }

  Future<void> _onRefresh(_Refresh event, Emitter<BillingState> emit) async {
    final s = state;
    final previous = s is _Loaded ? s.data : null;
    // Jangan menimpa tampilan saat order sedang dibuat.
    if (previous != null && previous.isCheckingOut) return;
    final id = ++_requestId;
    if (previous == null) emit(const BillingState.loading());

    final result = await remoteDatasource.overview(slug);
    if (id != _requestId) return;
    result.fold(
      (failure) => emit(
        previous == null
            ? BillingState.error(failure)
            : BillingState.loaded(previous.copyWith(refreshFailure: failure)),
      ),
      (overview) => emit(
        BillingState.loaded(
          previous == null
              ? BillingViewData(overview: overview)
              : previous.copyWith(overview: overview),
        ),
      ),
    );
  }

  Future<void> _onCheckout(_Checkout event, Emitter<BillingState> emit) async {
    final s = state;
    if (s is! _Loaded || s.data.isCheckingOut) return;
    final current = s.data;
    emit(BillingState.loaded(current.copyWith(isCheckingOut: true)));

    final result = await remoteDatasource.checkout(
      slug,
      plan: event.plan,
      months: event.months,
    );
    result.fold(
      (failure) => emit(
        BillingState.loaded(
          current.copyWith(isCheckingOut: false, checkoutFailure: failure),
        ),
      ),
      (order) => emit(
        BillingState.loaded(
          current.copyWith(isCheckingOut: false, createdOrder: order),
        ),
      ),
    );
  }
}
