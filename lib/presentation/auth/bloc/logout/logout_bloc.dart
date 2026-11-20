import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/auth_local_datasource.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'logout_event.dart';
part 'logout_state.dart';
part 'logout_bloc.freezed.dart';

/// Keluar selalu menghapus token lokal, walau server tidak terjangkau
/// (pengguna harus tetap bisa keluar dari perangkatnya).
class LogoutBloc extends Bloc<LogoutEvent, LogoutState> {
  final AuthRemoteDatasource remoteDatasource;
  final AuthLocalDatasource localDatasource;

  LogoutBloc(this.remoteDatasource, this.localDatasource)
      : super(const LogoutState.initial()) {
    on<_Logout>(_onLogout);
  }

  Future<void> _onLogout(_Logout event, Emitter<LogoutState> emit) async {
    emit(const LogoutState.loading());
    await remoteDatasource.logout();
    await localDatasource.removeToken();
    emit(const LogoutState.success());
  }
}
