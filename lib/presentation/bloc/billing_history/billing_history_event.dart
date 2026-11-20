part of 'billing_history_bloc.dart';

@blocFreezed
sealed class BillingHistoryEvent with _$BillingHistoryEvent {

  /// Muat halaman pertama (menampilkan loading).
  const factory BillingHistoryEvent.load() = _Load;

  /// Muat ulang halaman pertama tanpa menghapus daftar yang tampil.
  const factory BillingHistoryEvent.refresh() = _Refresh;

  /// Tambah halaman berikutnya. Diabaikan bila tidak ada lagi / sedang memuat.
  const factory BillingHistoryEvent.loadMore() = _LoadMore;
}
