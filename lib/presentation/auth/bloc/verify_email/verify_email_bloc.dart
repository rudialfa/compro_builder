import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/data/model/response/account_message_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_email_event.dart';
part 'verify_email_state.dart';
part 'verify_email_bloc.freezed.dart';

/// POST /auth/email/verification-notification (butuh token). Dibuat oleh
/// tombol kirim ulang di tiap tempat banner "email belum terverifikasi".
class VerifyEmailBloc extends Bloc<VerifyEmailEvent, VerifyEmailState> {
  final AuthRemoteDatasource remoteDatasource;

  VerifyEmailBloc(this.remoteDatasource) : super(const VerifyEmailState.initial()) {
    on<_Resend>(_onResend);
  }

  Future<void> _onResend(_Resend event, Emitter<VerifyEmailState> emit) async {
    if (state is _Loading) return;
    emit(const VerifyEmailState.loading());
    final result = await remoteDatasource.resendVerification();
    result.fold(
      (failure) => emit(VerifyEmailState.error(failure)),
      (data) => emit(VerifyEmailState.sent(data)),
    );
  }
}
