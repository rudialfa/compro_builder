import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/settings_remote_datasource.dart';
import 'package:compro_builder/data/model/request/settings_changes_model.dart';
import 'package:compro_builder/data/model/response/site_settings_model.dart';
import 'package:compro_builder/presentation/bloc/settings/settings_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements SettingsRemoteDatasource {}

const _s = SiteSettingsModel(name: 'Toko');
const _s2 = SiteSettingsModel(name: 'Baru');

Matcher _loaded(bool Function(SettingsViewData d) test) =>
    predicate<SettingsState>(
      (s) => s.maybeWhen(loaded: test, orElse: () => false),
      'loaded yang memenuhi syarat',
    );

void main() {
  late MockRemote remote;

  setUpAll(() => registerFallbackValue(const SettingsChangesModel()));
  setUp(() => remote = MockRemote());

  SettingsBloc build() => SettingsBloc(remote, slug: 'toko');
  SettingsState seeded() =>
      const SettingsState.loaded(SettingsViewData(settings: _s));

  blocTest<SettingsBloc, SettingsState>(
    'load sukses',
    setUp: () =>
        when(() => remote.get('toko')).thenAnswer((_) async => const Right(_s)),
    build: build,
    act: (b) => b.add(const SettingsEvent.load()),
    expect: () => [
      isA<SettingsState>(),
      _loaded((d) => d.settings.name == 'Toko' && !d.saved),
    ],
  );

  blocTest<SettingsBloc, SettingsState>(
    'load gagal -> error',
    setUp: () =>
        when(() => remote.get('toko'))
            .thenAnswer((_) async => const Left(ApiFailure('offline'))),
    build: build,
    act: (b) => b.add(const SettingsEvent.load()),
    expect: () => [
      isA<SettingsState>(),
      predicate<SettingsState>(
        (s) => s.maybeWhen(error: (_) => true, orElse: () => false),
      ),
    ],
  );

  blocTest<SettingsBloc, SettingsState>(
    'save sukses: data baru dari server + saved sesaat',
    setUp: () =>
        when(() => remote.save('toko', any()))
            .thenAnswer((_) async => const Right(_s2)),
    build: build,
    seed: seeded,
    act: (b) => b.add(
      const SettingsEvent.save(SettingsChangesModel(texts: {'name': 'Baru'})),
    ),
    expect: () => [
      _loaded((d) => d.isSaving),
      _loaded((d) => !d.isSaving && d.saved && d.settings.name == 'Baru'),
    ],
  );

  blocTest<SettingsBloc, SettingsState>(
    'save 422: data lama tetap, saveFailure membawa fieldErrors',
    setUp: () => when(() => remote.save('toko', any())).thenAnswer(
      (_) async => const Left(
        ApiFailure(
          'x',
          statusCode: 422,
          fieldErrors: {
            'notify_email': ['Format email belum benar.'],
          },
        ),
      ),
    ),
    build: build,
    seed: seeded,
    act: (b) => b.add(
      const SettingsEvent.save(
        SettingsChangesModel(texts: {'notify_email': 'x'}),
      ),
    ),
    expect: () => [
      _loaded((d) => d.isSaving),
      _loaded(
        (d) =>
            !d.isSaving &&
            !d.saved &&
            d.settings.name == 'Toko' &&
            d.saveFailure?.errorFor('notify_email') != null,
      ),
    ],
  );

  blocTest<SettingsBloc, SettingsState>(
    'save saat sedang menyimpan diabaikan',
    setUp: () => when(() => remote.save('toko', any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return const Right(_s2);
    }),
    build: build,
    seed: seeded,
    act: (b) {
      b.add(
        const SettingsEvent.save(SettingsChangesModel(texts: {'name': 'Baru'})),
      );
      b.add(
        const SettingsEvent.save(SettingsChangesModel(texts: {'name': 'Baru'})),
      );
    },
    wait: const Duration(milliseconds: 60),
    verify: (_) => verify(() => remote.save('toko', any())).called(1),
  );
}
