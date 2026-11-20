part of 'billing_bloc.dart';

@blocFreezed
sealed class BillingEvent with _$BillingEvent {

  /// Muat pertama (menampilkan loading).
  const factory BillingEvent.load() = _Load;

  /// Muat ulang tanpa menghapus data yang tampil (mis. setelah kembali dari
  /// halaman bayar atau dari web).
  const factory BillingEvent.refresh() = _Refresh;

  /// Buat order untuk [plan] (kode paket) selama [months] bulan. Diabaikan
  /// bila belum termuat atau sedang membuat order.
  const factory BillingEvent.checkout({
    required String plan,
    required int months,
  }) = _Checkout;
}
