part of 'publish_bloc.dart';

/// Penyebab 403 saat mengubah status (kontrak backend hanya mengirim pesan).
enum PublishBlock { emailUnverified, siteDisabled, other }

/// Hasil sesaat yang ditampilkan sekali (snackbar), lalu hilang pada emisi berikutnya.
enum PublishNotice { published, drafted }

/// Satu kelas data (bukan sealed): halaman Publish tidak punya fase memuat/galat
/// sendiri karena status awal datang dari [SitesBloc] dan checklist dari
/// [SectionsBloc]; yang diubah bloc ini hanya status tayang.
class PublishState {
  final SiteStatus status;
  final bool isChanging;

  /// Galat selain 403 (jaringan, 422, 429, 5xx). `retryAfter` terisi pada 429.
  final ApiFailure? failure;

  /// 403 dengan penyebabnya; tetap tampil sampai percobaan berikutnya/ditutup.
  final PublishBlock? block;
  final String? blockMessage;

  final PublishNotice? notice;

  /// Situs terbaru dari server setelah sukses; halaman meneruskannya ke SitesBloc.
  final TenantModel? updatedTenant;

  const PublishState({
    required this.status,
    this.isChanging = false,
    this.failure,
    this.block,
    this.blockMessage,
    this.notice,
    this.updatedTenant,
  });

  bool get isPublished => status == SiteStatus.published;

  /// Selalu menghapus `notice`/`updatedTenant` (hanya berlaku satu emisi);
  /// `failure` dan `block` ikut terhapus kecuali dikirim ulang.
  PublishState next({
    SiteStatus? status,
    bool? isChanging,
    ApiFailure? failure,
    PublishBlock? block,
    String? blockMessage,
    PublishNotice? notice,
    TenantModel? updatedTenant,
  }) => PublishState(
    status: status ?? this.status,
    isChanging: isChanging ?? this.isChanging,
    failure: failure,
    block: block,
    blockMessage: blockMessage,
    notice: notice,
    updatedTenant: updatedTenant,
  );
}
