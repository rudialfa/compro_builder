part of 'domain_bloc.dart';

class DomainViewData {
  final DomainStatusModel status;

  /// Galat muat ulang sesaat (satu emisi); [status] lama tetap tampil.
  final ApiFailure? failure;

  const DomainViewData({required this.status, this.failure});
}

@blocFreezed
sealed class DomainState with _$DomainState {
  const factory DomainState.initial() = _Initial;
  const factory DomainState.loading() = _Loading;
  const factory DomainState.loaded(DomainViewData data) = _Loaded;
  const factory DomainState.error(ApiFailure failure) = _Error;
}
