part of 'template_bloc.dart';

@blocFreezed
sealed class TemplateEvent with _$TemplateEvent {

  /// Muat daftar template. Layar memuat hanya bila belum ada data; bila sudah
  /// ada (mis. kembali dari halaman Paket) data lama dipertahankan saat gagal.
  const factory TemplateEvent.load() = _Load;

  /// Pakai template [code]. Diabaikan bila terkunci, sudah aktif, atau ada
  /// proses lain yang berjalan.
  const factory TemplateEvent.apply(String code) = _Apply;

  /// Minta tautan pratinjau untuk template [code] (boleh yang terkunci).
  const factory TemplateEvent.preview(String code) = _Preview;
}
