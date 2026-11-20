import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/data/model/request/reset_password_request_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reset_password_event.dart';
part 'reset_password_state.dart';
part 'reset_password_bloc.freezed.dart';

/// POST /auth/reset-password. Dibuat per halaman; tidak memakai token login.
class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final AuthRemoteDatasource remoteDatasource;

  ResetPasswordBloc(this.remoteDatasource)
    : super(const ResetPasswordState.initial()) {
    on<_Submit>(_onSubmit);
  }

  Future<void> _onSubmit(
    _Submit event,
    Emitter<ResetPasswordState> emit,
  ) async {
    if (state is _Loading) return;
    emit(const ResetPasswordState.loading());
    final result = await remoteDatasource.resetPassword(event.request);
    result.fold(
      (failure) => emit(ResetPasswordState.error(failure)),
      (data) => emit(ResetPasswordState.success(data.message)),
    );
  }
}
