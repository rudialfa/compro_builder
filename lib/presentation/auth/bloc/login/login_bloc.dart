import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/auth_local_datasource.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/data/model/request/login_request_model.dart';
import 'package:compro_builder/data/model/response/auth_response_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_event.dart';
part 'login_state.dart';
part 'login_bloc.freezed.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRemoteDatasource remoteDatasource;
  final AuthLocalDatasource localDatasource;

  LoginBloc(this.remoteDatasource, this.localDatasource)
      : super(const LoginState.initial()) {
    on<_Login>(_onLogin);
  }

  Future<void> _onLogin(_Login event, Emitter<LoginState> emit) async {
    emit(const LoginState.loading());
    final result = await remoteDatasource.login(event.request);
    await result.fold<Future<void>>(
      (failure) async => emit(LoginState.error(failure)),
      (data) async {
        if (data.token.isEmpty) {
          emit(const LoginState.error(
              ApiFailure('Gagal masuk. Token tidak diterima.')));
          return;
        }
        await localDatasource.saveToken(data.token);
        emit(LoginState.success(data));
      },
    );
  }
}
