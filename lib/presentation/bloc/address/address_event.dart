part of 'address_bloc.dart';

@blocFreezed
sealed class AddressEvent with _$AddressEvent {

  /// Isian alamat berubah. Pemeriksaan ke server ditunda sebentar (debounce)
  /// dan hasil lama yang datang terlambat dibuang.
  const factory AddressEvent.changed(String input) = _Changed;

  /// Simpan alamat baru. Pemanggil (halaman) sudah meminta konfirmasi pengguna.
  /// Diabaikan bila hasil cek terakhir belum "tersedia" untuk isian saat ini.
  const factory AddressEvent.submit() = _Submit;
}
