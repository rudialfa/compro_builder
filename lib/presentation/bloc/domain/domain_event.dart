part of 'domain_bloc.dart';

@blocFreezed
sealed class DomainEvent with _$DomainEvent {

  /// Muat status domain. Layar memuat hanya bila belum ada data; bila sudah ada
  /// (mis. kembali dari web) data lama dipertahankan saat gagal.
  const factory DomainEvent.load() = _Load;
}
