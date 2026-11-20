import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/onboarding_remote_datasource.dart';
import 'package:compro_builder/data/model/request/onboarding_request_model.dart';
import 'package:compro_builder/data/model/response/onboarding_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/data/model/response/theme_response_model.dart';
import 'package:compro_builder/presentation/bloc/onboarding/onboarding_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements OnboardingRemoteDatasource {}

const _data = OnboardingResponseModel(
  needed: true,
  values: OnboardingValuesModel(name: 'Kopi Kita', theme: 'indigo'),
  themes: [ThemeOptionModel(code: 'indigo', name: 'Indigo')],
);
const _request = OnboardingRequestModel(name: 'Kopi Kita', theme: 'indigo');
const _tenant = TenantModel(id: 1, name: 'Kopi Kita', slug: 'toko');
const _fail = ApiFailure('Gagal memuat pengaturan awal.', statusCode: 500);
const _invalid = ApiFailure(
  'Nama usaha wajib diisi.',
  statusCode: 422,
  fieldErrors: {
    'name': ['Nama usaha wajib diisi.'],
  },
);

Matcher _loaded(bool Function(OnboardingViewData v) check) =>
    predicate<OnboardingState>(
      (s) => s.maybeWhen(loaded: check, orElse: () => false),
      'loaded',
    );

OnboardingState _seed() =>
    const OnboardingState.loaded(OnboardingViewData(data: _data));

void main() {
  late MockRemote remote;
  setUpAll(() => registerFallbackValue(_request));
  setUp(() => remote = MockRemote());

  OnboardingBloc build() => OnboardingBloc(remote, slug: 'toko');

  blocTest<OnboardingBloc, OnboardingState>(
    'load sukses: loading lalu loaded',
    setUp: () => when(
      () => remote.show('toko'),
    ).thenAnswer((_) async => const Right(_data)),
    build: build,
    act: (b) => b.add(const OnboardingEvent.load()),
    expect: () => [
      predicate<OnboardingState>(
        (s) => s.maybeWhen(loading: () => true, orElse: () => false),
      ),
      _loaded(
        (v) => v.data.needed && v.data.values.name == 'Kopi Kita' && !v.isBusy,
      ),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'load gagal: loading lalu error',
    setUp: () =>
        when(() => remote.show('toko')).thenAnswer((_) async => const Left(_fail)),
    build: build,
    act: (b) => b.add(const OnboardingEvent.load()),
    expect: () => [
      isA<OnboardingState>(),
      predicate<OnboardingState>(
        (s) => s.maybeWhen(error: (f) => f.statusCode == 500, orElse: () => false),
      ),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'submit sukses: isBusy lalu doneTenant terisi (bukan skip)',
    setUp: () => when(
      () => remote.submit('toko', _request),
    ).thenAnswer((_) async => const Right(_tenant)),
    build: build,
    seed: _seed,
    act: (b) => b.add(const OnboardingEvent.submit(_request)),
    expect: () => [
      _loaded((v) => v.isBusy),
      _loaded((v) => !v.isBusy && v.doneTenant?.slug == 'toko' && !v.wasSkipped),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'submit 422: failure membawa fieldErrors, tidak ada doneTenant',
    setUp: () => when(
      () => remote.submit('toko', _request),
    ).thenAnswer((_) async => const Left(_invalid)),
    build: build,
    seed: _seed,
    act: (b) => b.add(const OnboardingEvent.submit(_request)),
    expect: () => [
      _loaded((v) => v.isBusy),
      _loaded(
        (v) =>
            !v.isBusy &&
            v.doneTenant == null &&
            v.failure?.errorFor('name') == 'Nama usaha wajib diisi.',
      ),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'skip sukses: doneTenant terisi dengan wasSkipped true',
    setUp: () =>
        when(() => remote.skip('toko')).thenAnswer((_) async => const Right(_tenant)),
    build: build,
    seed: _seed,
    act: (b) => b.add(const OnboardingEvent.skip()),
    expect: () => [
      _loaded((v) => v.isBusy),
      _loaded((v) => !v.isBusy && v.doneTenant != null && v.wasSkipped),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'skip gagal: failure terisi, tetap di wizard',
    setUp: () =>
        when(() => remote.skip('toko')).thenAnswer((_) async => const Left(_fail)),
    build: build,
    seed: _seed,
    act: (b) => b.add(const OnboardingEvent.skip()),
    expect: () => [
      _loaded((v) => v.isBusy),
      _loaded((v) => !v.isBusy && v.doneTenant == null && v.failure != null),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'submit sebelum data termuat diabaikan',
    build: build,
    act: (b) => b.add(const OnboardingEvent.submit(_request)),
    expect: () => <Object>[],
    verify: (_) => verifyNever(() => remote.submit(any(), any())),
  );
}
