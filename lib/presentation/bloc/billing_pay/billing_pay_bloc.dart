import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/billing_remote_datasource.dart';
import 'package:compro_builder/data/model/response/billing_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'billing_pay_event.dart';
part 'billing_pay_state.dart';
part 'billing_pay_bloc.freezed.dart';

/// Pembayaran SATU order: memilih metode (charge) dan memantau status sampai
/// lunas. Dibuat per halaman bayar dari order yang sudah ada (hasil checkout,
/// `pending_order`, atau baris riwayat). Webhook server tetap sumber utama;
/// polling ([BillingPayEvent.poll]) hanya mempercepat tampilan.
class BillingPayBloc extends Bloc<BillingPayEvent, BillingPayState> {
  final String slug;
  final BillingRemoteDatasource remoteDatasource;

  /// Satu polling saja yang boleh berjalan (batas server 40/menit).
  bool _polling = false;

  BillingPayBloc(
    this.remoteDatasource, {
    required this.slug,
    required BillingOrderModel order,
  }) : super(BillingPayState.ready(BillingPayData(order: order))) {
    on<_Charge>(_onCharge);
    on<_Poll>(_onPoll);
  }

  BillingPayData get _data => state.when(ready: (d) => d);

  Future<void> _onCharge(_Charge event, Emitter<BillingPayState> emit) async {
    final start = _data;
    if (start.isCharging || !start.order.isPayable) return;
    emit(BillingPayState.ready(start.copyWith(isCharging: true)));

    final result = await remoteDatasource.charge(
      slug,
      start.order.id,
      event.method,
    );
    // Baca ulang state: polling bisa mengubah order selama charge berjalan.
    final now = _data;
    final failure = result.fold<ApiFailure?>((f) => f, (_) => null);
    if (failure != null) {
      emit(
        BillingPayState.ready(
          now.copyWith(isCharging: false, chargeFailure: failure),
        ),
      );
      // Server membatalkan tagihan lama sebelum memanggil gateway: bila gateway
      // menolak, order bisa sudah kembali ke `choose`. Sinkronkan tampilan.
      add(const BillingPayEvent.poll());
      return;
    }
    result.fold(
      (_) {},
      (order) => emit(
        BillingPayState.ready(now.copyWith(isCharging: false, order: order)),
      ),
    );
  }

  Future<void> _onPoll(_Poll event, Emitter<BillingPayState> emit) async {
    final start = _data;
    if (_polling || start.isCharging || !start.order.isPayable) return;
    _polling = true;
    try {
      final result = await remoteDatasource.status(slug, start.order.id);
      // Galat polling diabaikan: percobaan berikutnya menyusul, dan 401 sudah
      // ditangani ApiHelper.guard.
      final status = result.fold<BillingStatusModel?>((_) => null, (s) => s);
      if (status == null) return;

      final now = _data;
      final wasPaid = now.order.isPaid;
      final next = now.order.applyStatus(status);
      final changed =
          next.step != now.order.step ||
          next.timedOut != now.order.timedOut ||
          next.status != now.order.status;
      if (!changed) return;

      emit(
        BillingPayState.ready(
          now.copyWith(
            order: next,
            paidNow: status.paid && !wasPaid,
            paidTenant: status.paid && !wasPaid ? status.tenant : null,
          ),
        ),
      );
    } finally {
      _polling = false;
    }
  }
}
