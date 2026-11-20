import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/address_remote_datasource.dart';
import 'package:compro_builder/data/model/response/domain_response_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'domain_event.dart';
part 'domain_state.dart';
part 'domain_bloc.freezed.dart';

/// Status domain sendiri SATU situs (hanya baca). Menyetel, memverifikasi, dan
/// melepas domain dilakukan di web; app memuat ulang saat pengguna kembali.
class DomainBloc extends Bloc<DomainEvent, DomainState> {
  final String slug;
  final AddressRemoteDatasource remoteDatasource;

  DomainBloc(this.remoteDatasource, {required this.slug})
    : super(const DomainState.initial()) {
    on<_Load>(_onLoad);
  }

  Future<void> _onLoad(_Load event, Emitter<DomainState> emit) async {
    final s = state;
    final previous = s is _Loaded ? s.data : null;
    if (previous == null) emit(const DomainState.loading());

    final result = await remoteDatasource.domain(slug);
    result.fold(
      (failure) => emit(
        previous == null
            ? DomainState.error(failure)
            : DomainState.loaded(
                DomainViewData(status: previous.status, failure: failure),
              ),
      ),
      (status) => emit(DomainState.loaded(DomainViewData(status: status))),
    );
  }
}
