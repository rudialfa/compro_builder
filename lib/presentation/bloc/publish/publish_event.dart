part of 'publish_bloc.dart';

@blocFreezed
sealed class PublishEvent with _$PublishEvent {

  /// Ubah status tayang situs. Diabaikan bila permintaan sebelumnya masih berjalan.
  const factory PublishEvent.setStatus(SiteStatus target) = _SetStatus;

  /// Singkirkan galat/blokir yang tampil (mis. setelah pengguna menutupnya).
  const factory PublishEvent.dismissed() = _Dismissed;
}
