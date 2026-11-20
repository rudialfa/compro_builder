import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/template_remote_datasource.dart';
import 'package:compro_builder/data/model/response/template_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'template_event.dart';
part 'template_state.dart';
part 'template_bloc.freezed.dart';

/// Template tampilan SATU situs; dibuat per halaman lewat BlocProvider(create:).
/// Tanpa cache offline. Aturan kunci per paket ada di server: aplikasi memakai
/// `locked`/`active` dari server dan hanya menolak lebih awal yang sudah pasti
/// ditolak server.
class TemplateBloc extends Bloc<TemplateEvent, TemplateState> {
  final String slug;
  final TemplateRemoteDatasource remoteDatasource;

  TemplateBloc(this.remoteDatasource, {required this.slug})
    : super(const TemplateState.initial()) {
    on<_Load>(_onLoad);
    on<_Apply>(_onApply);
    on<_Preview>(_onPreview);
  }

  Future<void> _onLoad(_Load event, Emitter<TemplateState> emit) async {
    final s = state;
    final previous = s is _Loaded ? s.data : null;
    if (previous == null) emit(const TemplateState.loading());

    final result = await remoteDatasource.list(slug);
    result.fold(
      (failure) => emit(
        previous == null
            ? TemplateState.error(failure)
            // Data lama tetap tampil; galat hanya untuk snackbar.
            : TemplateState.loaded(previous.copyWith(failure: failure)),
      ),
      (data) => emit(
        TemplateState.loaded(
          TemplateViewData(
            templates: data.templates,
            active: data.active,
            chosen: data.chosen,
          ),
        ),
      ),
    );
  }

  Future<void> _onApply(_Apply event, Emitter<TemplateState> emit) async {
    final s = state;
    if (s is! _Loaded || s.data.isBusy) return;
    final current = s.data;
    final target = current.byCode(event.code);
    if (target == null || target.locked || target.code == current.active) {
      return;
    }

    emit(TemplateState.loaded(current.copyWith(applyingCode: event.code)));
    final result = await remoteDatasource.update(slug, event.code);
    result.fold(
      (failure) => emit(
        TemplateState.loaded(
          current.copyWith(clearApplying: true, failure: failure),
        ),
      ),
      (res) => emit(
        TemplateState.loaded(
          TemplateViewData(
            templates: res.templates.templates,
            active: res.templates.active,
            chosen: res.templates.chosen,
            appliedTenant: res.tenant,
          ),
        ),
      ),
    );
  }

  Future<void> _onPreview(_Preview event, Emitter<TemplateState> emit) async {
    final s = state;
    if (s is! _Loaded || s.data.isBusy) return;
    final current = s.data;
    final target = current.byCode(event.code);
    if (target == null) return;

    emit(TemplateState.loaded(current.copyWith(previewingCode: event.code)));
    final result = await remoteDatasource.previewLink(slug, event.code);
    result.fold(
      (failure) => emit(
        TemplateState.loaded(
          current.copyWith(clearPreviewing: true, failure: failure),
        ),
      ),
      (link) => emit(
        TemplateState.loaded(
          current.copyWith(
            clearPreviewing: true,
            previewTarget: TemplatePreviewTarget(
              name: target.name,
              url: link.url,
            ),
          ),
        ),
      ),
    );
  }
}
