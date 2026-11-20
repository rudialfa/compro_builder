import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/address_remote_datasource.dart';
import 'package:compro_builder/data/model/response/address_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_event.dart';
part 'address_state.dart';
part 'address_bloc.freezed.dart';

/// Ganti alamat website (slug) SATU situs; dibuat per halaman lewat
/// BlocProvider(create:). Aturan alamat (panjang, karakter, dipakai/dicadangkan)
/// SEPENUHNYA dari server: aplikasi hanya mengirim isian dan menampilkan
/// jawabannya, tanpa menyalin aturannya.
class AddressBloc extends Bloc<AddressEvent, AddressState> {
  /// Jeda sebelum isian diperiksa; server membatasi cek 60/menit.
  static const debounce = Duration(milliseconds: 450);

  final String slug;
  final AddressRemoteDatasource remoteDatasource;
  final Duration debounceDuration;

  /// Penanda isian terbaru; hasil untuk isian yang sudah usang dibuang.
  int _seq = 0;

  AddressBloc(
    this.remoteDatasource, {
    required this.slug,
    this.debounceDuration = debounce,
  }) : super(const AddressState.ready(AddressViewData())) {
    on<_Changed>(_onChanged);
    on<_Submit>(_onSubmit);
  }

  AddressViewData get _data => (state as _Ready).data;

  Future<void> _onChanged(_Changed event, Emitter<AddressState> emit) async {
    final id = ++_seq;
    final value = event.input.trim().toLowerCase();

    if (value.isEmpty) {
      // Kosong tidak perlu ke server.
      emit(
        AddressState.ready(
          _data.copyWith(
            input: event.input,
            clearCheck: true,
            clearCheckFailure: true,
            checking: false,
          ),
        ),
      );
      return;
    }

    emit(
      AddressState.ready(
        _data.copyWith(
          input: event.input,
          clearCheck: true,
          clearCheckFailure: true,
          checking: true,
        ),
      ),
    );

    await Future<void>.delayed(debounceDuration);
    if (id != _seq || isClosed) return;

    final result = await remoteDatasource.check(slug, value);
    if (id != _seq || isClosed) return;

    result.fold(
      (failure) => emit(
        AddressState.ready(
          _data.copyWith(checking: false, checkFailure: failure),
        ),
      ),
      (check) => emit(
        AddressState.ready(_data.copyWith(checking: false, check: check)),
      ),
    );
  }

  Future<void> _onSubmit(_Submit event, Emitter<AddressState> emit) async {
    final current = _data;
    if (!current.canSubmit) return;
    final target = current.check!.slug;

    emit(AddressState.ready(current.copyWith(isSaving: true)));
    final result = await remoteDatasource.update(slug, target);
    result.fold(
      (failure) => emit(
        AddressState.ready(
          current.copyWith(isSaving: false, saveFailure: failure),
        ),
      ),
      (res) => emit(
        AddressState.ready(
          current.copyWith(
            isSaving: false,
            savedTenant: res.tenant,
            oldSlug: res.oldSlug,
          ),
        ),
      ),
    );
  }
}
