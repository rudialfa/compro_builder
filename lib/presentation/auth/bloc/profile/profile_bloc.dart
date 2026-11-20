import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/data/model/response/auth_response_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_event.dart';
part 'profile_state.dart';
part 'profile_bloc.freezed.dart';

/// GET /auth/me: memvalidasi token saat splash dan memuat data pengguna.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthRemoteDatasource remoteDatasource;

  ProfileBloc(this.remoteDatasource) : super(const ProfileState.initial()) {
    on<_Load>(_onLoad);
  }

  Future<void> _onLoad(_Load event, Emitter<ProfileState> emit) async {
    emit(const ProfileState.loading());
    final result = await remoteDatasource.me();
    result.fold(
      (failure) => emit(ProfileState.error(failure)),
      (user) => emit(ProfileState.loaded(user)),
    );
  }
}
