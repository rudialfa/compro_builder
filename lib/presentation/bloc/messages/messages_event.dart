part of 'messages_bloc.dart';

@blocFreezed
sealed class MessagesEvent with _$MessagesEvent {

  /// Muat halaman pertama (menampilkan loading).
  const factory MessagesEvent.load() = _Load;

  /// Muat ulang dari halaman pertama tanpa menghapus data yang tampil.
  const factory MessagesEvent.refresh() = _Refresh;

  /// Muat halaman berikutnya (infinite scroll / coba lagi).
  const factory MessagesEvent.loadMore() = _LoadMore;

  /// Balik status dibaca. Dengan [onlyIfUnread] hanya bila belum dibaca
  /// (dipakai saat membuka detail; endpoint bersifat toggle).
  const factory MessagesEvent.toggleRead(
    int id, {
    @Default(false) bool onlyIfUnread,
  }) = _ToggleRead;

  const factory MessagesEvent.delete(int id) = _Delete;
}
