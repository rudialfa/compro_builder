part of 'billing_pay_bloc.dart';

@blocFreezed
sealed class BillingPayEvent with _$BillingPayEvent {

  /// Pilih metode bayar (kode dari `methods` server) -> buat tagihan di gateway.
  /// Diabaikan bila sedang membuat tagihan atau order tidak bisa dibayar lagi.
  const factory BillingPayEvent.charge(String method) = _Charge;

  /// Tanyakan status ke server (dipanggil berkala oleh halaman). Diabaikan bila
  /// satu pemanggilan masih berjalan, sedang charge, atau order sudah selesai.
  const factory BillingPayEvent.poll() = _Poll;
}
