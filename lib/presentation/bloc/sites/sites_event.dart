part of 'sites_bloc.dart';

@blocFreezed
sealed class SitesEvent with _$SitesEvent {

  /// Muat awal (menampilkan layar memuat). Dipanggil shell saat dibuka.
  const factory SitesEvent.fetch() = _Fetch;

  /// Tarik-untuk-muat-ulang: data lama dipertahankan bila gagal.
  const factory SitesEvent.refresh() = _Refresh;

  /// Pilih situs aktif (disimpan lokal).
  const factory SitesEvent.select(String slug) = _Select;

  /// Gabungkan situs yang baru diubah (mis. status Publish) tanpa menimpa
  /// `unreadMessages` dengan null.
  const factory SitesEvent.tenantUpdated(TenantModel tenant) = _TenantUpdated;

  /// Keluar / sesi berakhir: kosongkan state + cache, tolak respons yang masih jalan.
  const factory SitesEvent.reset() = _Reset;
}
