import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/onboarding_remote_datasource.dart';
import 'package:compro_builder/data/model/request/onboarding_request_model.dart';
import 'package:compro_builder/data/model/response/onboarding_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';
part 'onboarding_bloc.freezed.dart';

/// Pengaturan awal SATU situs; dibuat per halaman lewat BlocProvider(create:).
/// Tanpa cache offline. Aturan isian dan penyimpanan ada di server.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final String slug;
  final OnboardingRemoteDatasource remoteDatasource;

  OnboardingBloc(this.remoteDatasource, {required this.slug})
    : super(const OnboardingState.initial()) {
    on<_Load>(_onLoad);
    on<_Submit>(_onSubmit);
    on<_Skip>(_onSkip);
  }

  Future<void> _onLoad(_Load event, Emitter<OnboardingState> emit) async {
    emit(const OnboardingState.loading());
    final result = await remoteDatasource.show(slug);
    result.fold(
      (failure) => emit(OnboardingState.error(failure)),
      (data) => emit(OnboardingState.loaded(OnboardingViewData(data: data))),
    );
  }

  Future<void> _onSubmit(_Submit event, Emitter<OnboardingState> emit) async {
    final s = state;
    if (s is! _Loaded || s.data.isBusy) return;
    final current = s.data;
    emit(OnboardingState.loaded(current.copyWith(isBusy: true)));

    final result = await remoteDatasource.submit(slug, event.request);
    result.fold(
      (failure) => emit(
        OnboardingState.loaded(current.copyWith(isBusy: false, failure: failure)),
      ),
      (tenant) => emit(
        OnboardingState.loaded(
          current.copyWith(isBusy: false, doneTenant: tenant),
        ),
      ),
    );
  }

  Future<void> _onSkip(_Skip event, Emitter<OnboardingState> emit) async {
    final s = state;
    if (s is! _Loaded || s.data.isBusy) return;
    final current = s.data;
    emit(OnboardingState.loaded(current.copyWith(isBusy: true)));

    final result = await remoteDatasource.skip(slug);
    result.fold(
      (failure) => emit(
        OnboardingState.loaded(current.copyWith(isBusy: false, failure: failure)),
      ),
      (tenant) => emit(
        OnboardingState.loaded(
          current.copyWith(isBusy: false, doneTenant: tenant, wasSkipped: true),
        ),
      ),
    );
  }
}
