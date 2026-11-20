part of 'theme_bloc.dart';

@blocFreezed
sealed class ThemeEvent with _$ThemeEvent {

  /// Muat daftar warna + warna yang sedang dipakai.
  const factory ThemeEvent.load() = _Load;

  /// Pilih warna (belum disimpan). Diabaikan saat menyimpan.
  const factory ThemeEvent.select(String code) = _Select;

  /// Simpan warna terpilih. Diabaikan bila tidak berubah / sedang menyimpan.
  const factory ThemeEvent.save() = _Save;
}
