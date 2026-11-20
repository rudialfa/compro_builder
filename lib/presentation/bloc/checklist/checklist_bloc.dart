import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/checklist_remote_datasource.dart';
import 'package:compro_builder/data/model/response/checklist_response_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist_event.dart';
part 'checklist_state.dart';
part 'checklist_bloc.freezed.dart';

/// Kelengkapan + syarat tayang SATU situs; dibuat per halaman (Beranda dan
/// Publikasi masing-masing punya instans sendiri). Aturan dihitung server
/// (SectionCompleteness), aplikasi hanya menampilkan.
class ChecklistBloc extends Bloc<ChecklistEvent, ChecklistState> {
  final String slug;
  final ChecklistRemoteDatasource remoteDatasource;

  /// Menolak respons basi bila dua muat ulang tumpang tindih.
  int _requestId = 0;

  ChecklistBloc(this.remoteDatasource, {required this.slug})
    : super(const ChecklistState.initial()) {
    on<_Load>(_onLoad);
    on<_Refresh>(_onRefresh);
  }

  Future<void> _onLoad(_Load event, Emitter<ChecklistState> emit) async {
    final id = ++_requestId;
    emit(const ChecklistState.loading());
    final result = await remoteDatasource.get(slug);
    if (id != _requestId) return;
    result.fold(
      (failure) => emit(ChecklistState.error(failure)),
      (data) => emit(ChecklistState.loaded(ChecklistViewData(data: data))),
    );
  }

  Future<void> _onRefresh(_Refresh event, Emitter<ChecklistState> emit) async {
    final s = state;
    final previous = s is _Loaded ? s.data : null;
    final id = ++_requestId;
    if (previous == null) emit(const ChecklistState.loading());

    final result = await remoteDatasource.get(slug);
    if (id != _requestId) return;
    result.fold(
      (failure) => emit(
        previous == null
            ? ChecklistState.error(failure)
            : ChecklistState.loaded(
                ChecklistViewData(data: previous.data, refreshFailure: failure),
              ),
      ),
      (data) => emit(ChecklistState.loaded(ChecklistViewData(data: data))),
    );
  }
}
