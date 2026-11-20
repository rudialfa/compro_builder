import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/auth_local_datasource.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/data/model/request/register_request_model.dart';
import 'package:compro_builder/data/model/response/auth_response_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_event.dart';
part 'register_state.dart';
part 'register_bloc.freezed.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRemoteDatasource remoteDatasource;
  final AuthLocalDatasource localDatasource;

  RegisterBloc(this.remoteDatasource, this.localDatasource)
      : super(const RegisterState.initial()) {
    on<_Register>(_onRegister);
  }

  Future<void> _onRegister(
    _Register event,
    Emitter<RegisterState> emit,
  ) async {
    emit(const RegisterState.loading());
    final result = await remoteDatasource.register(event.request);
    await result.fold<Future<void>>(
      (failure) async => emit(RegisterState.error(failure)),
      (data) async {
        if (data.token.isEmpty) {
          emit(const RegisterState.error(
              ApiFailure('Pendaftaran gagal. Token tidak diterima.')));
          return;
        }
        await localDatasource.saveToken(data.token);
        emit(RegisterState.success(data));
      },
    );
  }
}
