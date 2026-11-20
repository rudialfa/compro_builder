part of 'billing_history_bloc.dart';

class BillingHistoryData {
  final List<BillingOrderModel> orders;
  final int page;
  final bool hasMore;
  final int total;
  final bool isLoadingMore;

  /// Galat muat halaman berikutnya; bertahan sampai dicoba lagi.
  final ApiFailure? loadMoreFailure;

  /// Galat muat ulang sesaat (daftar lama tetap tampil).
  final ApiFailure? refreshFailure;

  const BillingHistoryData({
    required this.orders,
    required this.page,
    required this.hasMore,
    required this.total,
    this.isLoadingMore = false,
    this.loadMoreFailure,
    this.refreshFailure,
  });

  /// [refreshFailure] sengaja tidak dibawa (satu emisi); [loadMoreFailure]
  /// diganti setiap kali (null = terhapus).
  BillingHistoryData copyWith({
    List<BillingOrderModel>? orders,
    int? page,
    bool? hasMore,
    int? total,
    bool? isLoadingMore,
    ApiFailure? loadMoreFailure,
    ApiFailure? refreshFailure,
  }) => BillingHistoryData(
    orders: orders ?? this.orders,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    total: total ?? this.total,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailure: loadMoreFailure,
    refreshFailure: refreshFailure,
  );
}

@blocFreezed
sealed class BillingHistoryState with _$BillingHistoryState {
  const factory BillingHistoryState.initial() = _Initial;
  const factory BillingHistoryState.loading() = _Loading;
  const factory BillingHistoryState.loaded(BillingHistoryData data) = _Loaded;
  const factory BillingHistoryState.error(ApiFailure failure) = _Error;
}
