import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/plan_remote_datasource.dart';
import 'package:compro_builder/data/model/response/plan_info_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_event.dart';
part 'plan_state.dart';
part 'plan_bloc.freezed.dart';

/// Paket SATU situs; dibuat per halaman. Pembayaran terjadi di web, jadi
/// halaman memuat ulang saat aplikasi kembali aktif.
class PlanBloc extends Bloc<PlanEvent, PlanState> {
  final String slug;
  final PlanRemoteDatasource remoteDatasource;

  /// Menolak respons basi bila dua muat ulang tumpang tindih.
  int _requestId = 0;

  PlanBloc(this.remoteDatasource, {required this.slug})
    : super(const PlanState.initial()) {
    on<_Load>(_onLoad);
    on<_Refresh>(_onRefresh);
  }

  Future<void> _onLoad(_Load event, Emitter<PlanState> emit) async {
    final id = ++_requestId;
    emit(const PlanState.loading());
    final result = await remoteDatasource.get(slug);
    if (id != _requestId) return;
    result.fold(
      (failure) => emit(PlanState.error(failure)),
      (plan) => emit(PlanState.loaded(PlanViewData(plan: plan))),
    );
  }

  Future<void> _onRefresh(_Refresh event, Emitter<PlanState> emit) async {
    final s = state;
    final previous = s is _Loaded ? s.data : null;
    final id = ++_requestId;
    if (previous == null) emit(const PlanState.loading());

    final result = await remoteDatasource.get(slug);
    if (id != _requestId) return;
    result.fold(
      (failure) => emit(
        previous == null
            ? PlanState.error(failure)
            : PlanState.loaded(
                PlanViewData(plan: previous.plan, refreshFailure: failure),
              ),
      ),
      (plan) => emit(
        PlanState.loaded(PlanViewData(plan: plan, refreshed: event.announce)),
      ),
    );
  }
}
