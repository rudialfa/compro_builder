part of 'billing_bloc.dart';

class BillingViewData {
  final BillingOverviewModel overview;

  /// Sedang memanggil POST /checkout.
  final bool isCheckingOut;

  /// Galat checkout sesaat (403 email_unverified, 422 paket tidak boleh dibeli, dst).
  final ApiFailure? checkoutFailure;

  /// Order yang baru dibuat (satu emisi); halaman membuka layar bayar.
  final BillingOrderModel? createdOrder;

  /// Galat muat ulang sesaat (data lama tetap tampil).
  final ApiFailure? refreshFailure;

  const BillingViewData({
    required this.overview,
    this.isCheckingOut = false,
    this.checkoutFailure,
    this.createdOrder,
    this.refreshFailure,
  });

  /// Kolom satu emisi ([checkoutFailure], [createdOrder], [refreshFailure])
  /// sengaja tidak dibawa.
  BillingViewData copyWith({
    BillingOverviewModel? overview,
    bool? isCheckingOut,
    ApiFailure? checkoutFailure,
    BillingOrderModel? createdOrder,
    ApiFailure? refreshFailure,
  }) => BillingViewData(
    overview: overview ?? this.overview,
    isCheckingOut: isCheckingOut ?? this.isCheckingOut,
    checkoutFailure: checkoutFailure,
    createdOrder: createdOrder,
    refreshFailure: refreshFailure,
  );
}

@blocFreezed
sealed class BillingState with _$BillingState {
  const factory BillingState.initial() = _Initial;
  const factory BillingState.loading() = _Loading;
  const factory BillingState.loaded(BillingViewData data) = _Loaded;
  const factory BillingState.error(ApiFailure failure) = _Error;
}
