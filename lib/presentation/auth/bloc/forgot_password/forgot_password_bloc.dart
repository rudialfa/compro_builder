import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';
part 'forgot_password_bloc.freezed.dart';

/// POST /auth/forgot-password. Dibuat per halaman; tidak memakai token login.
class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRemoteDatasource remoteDatasource;

  ForgotPasswordBloc(this.remoteDatasource)
    : super(const ForgotPasswordState.initial()) {
    on<_Submit>(_onSubmit);
  }

  Future<void> _onSubmit(
    _Submit event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (state is _Loading) return;
    emit(const ForgotPasswordState.loading());
    final result = await remoteDatasource.forgotPassword(event.email);
    result.fold(
      (failure) => emit(ForgotPasswordState.error(failure)),
      (data) => emit(ForgotPasswordState.sent(data.message)),
    );
  }
}
