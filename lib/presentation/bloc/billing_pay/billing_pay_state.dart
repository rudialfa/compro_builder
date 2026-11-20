part of 'billing_pay_bloc.dart';

class BillingPayData {
  final BillingOrderModel order;

  /// Sedang memanggil POST /orders/{id}/charge.
  final bool isCharging;

  /// Galat charge sesaat (422 metode ditolak, 403 email_unverified, dst).
  final ApiFailure? chargeFailure;

  /// True satu emisi saat polling baru saja menemukan order lunas.
  final bool paidNow;

  /// Ringkasan situs terbaru (paket + masa berlaku) yang menyertai `paidNow`;
  /// halaman meneruskannya ke SitesBloc. Null bila server tidak menyertakannya.
  final TenantModel? paidTenant;

  const BillingPayData({
    required this.order,
    this.isCharging = false,
    this.chargeFailure,
    this.paidNow = false,
    this.paidTenant,
  });

  /// [chargeFailure], [paidNow], dan [paidTenant] sengaja tidak dibawa (satu emisi).
  BillingPayData copyWith({
    BillingOrderModel? order,
    bool? isCharging,
    ApiFailure? chargeFailure,
    bool paidNow = false,
    TenantModel? paidTenant,
  }) => BillingPayData(
    order: order ?? this.order,
    isCharging: isCharging ?? this.isCharging,
    chargeFailure: chargeFailure,
    paidNow: paidNow,
    paidTenant: paidTenant,
  );
}

@blocFreezed
sealed class BillingPayState with _$BillingPayState {
  const factory BillingPayState.ready(BillingPayData data) = _Ready;
}
