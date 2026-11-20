import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/publish_remote_datasource.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'publish_event.dart';
part 'publish_state.dart';
part 'publish_bloc.freezed.dart';

/// Penyebab 403 dari pesan server. Backend (ManageController@status) memakai
/// "Situs ini dinonaktifkan oleh admin." dan "Verifikasi email dulu ...".
PublishBlock classifyForbidden(ApiFailure failure) {
  final text = failure.message.toLowerCase();
  if (text.contains('nonaktif') || text.contains('suspend')) {
    return PublishBlock.siteDisabled;
  }
  if (text.contains('verifikasi') || text.contains('verified')) {
    return PublishBlock.emailUnverified;
  }
  return PublishBlock.other;
}

/// Status tayang SATU situs; dibuat per halaman. Status awal dari daftar situs.
/// Checklist kelengkapan dihitung halaman dari [SectionsBloc] (bukan di sini).
class PublishBloc extends Bloc<PublishEvent, PublishState> {
  final String slug;
  final PublishRemoteDatasource remoteDatasource;

  /// Menolak respons yang datang setelah bloc ditutup/diganti permintaan lain.
  int _requestId = 0;

  PublishBloc(
    this.remoteDatasource, {
    required this.slug,
    required SiteStatus initialStatus,
  }) : super(PublishState(status: initialStatus)) {
    on<_SetStatus>(_onSetStatus);
    on<_Dismissed>((event, emit) => emit(state.next()));
  }

  Future<void> _onSetStatus(
    _SetStatus event,
    Emitter<PublishState> emit,
  ) async {
    if (state.isChanging || event.target == SiteStatus.unknown) return;
    final id = ++_requestId;
    emit(state.next(isChanging: true));

    final result = await remoteDatasource.setStatus(slug, event.target);
    if (id != _requestId) return;

    result.fold(
      (failure) => emit(
        failure.isForbidden
            ? state.next(
                isChanging: false,
                block: classifyForbidden(failure),
                blockMessage: failure.message,
              )
            : state.next(isChanging: false, failure: failure),
      ),
      (response) {
        // Server kadang tidak menyebut status: pakai yang diminta.
        final status = response.status == SiteStatus.unknown
            ? event.target
            : response.status;
        emit(
          state.next(
            status: status,
            isChanging: false,
            notice: status == SiteStatus.published
                ? PublishNotice.published
                : PublishNotice.drafted,
            updatedTenant: response.tenant,
          ),
        );
      },
    );
  }
}
