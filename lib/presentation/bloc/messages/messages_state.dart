part of 'messages_bloc.dart';

enum MessagesNotice { deleted }

class MessagesViewData {
  final List<ContactMessageModel> items;
  final int page;
  final bool hasMore;
  final int total;
  final bool isLoadingMore;

  /// Galat muat halaman berikutnya; bertahan sampai dicoba lagi.
  final ApiFailure? loadMoreFailure;

  /// Galat mutasi/refresh sesaat untuk snackbar (data lama tetap tampil).
  final ApiFailure? actionFailure;

  /// Pesan sukses sesaat.
  final MessagesNotice? notice;

  /// True satu emisi saat jumlah pesan belum dibaca berubah (badge situs).
  final bool unreadChanged;

  const MessagesViewData({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.total,
    this.isLoadingMore = false,
    this.loadMoreFailure,
    this.actionFailure,
    this.notice,
    this.unreadChanged = false,
  });

  static const _keep = Object();

  /// [actionFailure], [notice], dan [unreadChanged] tidak dibawa (satu emisi).
  MessagesViewData copyWith({
    List<ContactMessageModel>? items,
    int? page,
    bool? hasMore,
    int? total,
    bool? isLoadingMore,
    Object? loadMoreFailure = _keep,
    ApiFailure? actionFailure,
    MessagesNotice? notice,
    bool unreadChanged = false,
  }) => MessagesViewData(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    total: total ?? this.total,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailure: identical(loadMoreFailure, _keep)
        ? this.loadMoreFailure
        : loadMoreFailure as ApiFailure?,
    actionFailure: actionFailure,
    notice: notice,
    unreadChanged: unreadChanged,
  );
}

@blocFreezed
sealed class MessagesState with _$MessagesState {
  const factory MessagesState.initial() = _Initial;
  const factory MessagesState.loading() = _Loading;
  const factory MessagesState.loaded(MessagesViewData view) = _Loaded;
  const factory MessagesState.error(ApiFailure failure) = _Error;
}
