import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/theme_remote_datasource.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/data/model/response/theme_response_model.dart';
import 'package:compro_builder/presentation/bloc/theme/theme_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements ThemeRemoteDatasource {}

const _themes = [
  ThemeOptionModel(code: 'indigo', name: 'Indigo'),
  ThemeOptionModel(code: 'hutan', name: 'Hutan'),
];
const _list = ThemesResponseModel(current: 'indigo', themes: _themes);
const _tenant = TenantModel(
  id: 1,
  name: 'Kopi Kita',
  slug: 'toko',
  theme: ThemeOptionModel(code: 'hutan', name: 'Hutan'),
);
const _fail = ApiFailure('Gagal mengubah warna situs.', statusCode: 500);

Matcher _loaded(bool Function(ThemeViewData v) check) => predicate<ThemeState>(
  (s) => s.maybeWhen(loaded: check, orElse: () => false),
  'loaded',
);

ThemeState _seed({String selected = 'indigo'}) => ThemeState.loaded(
  ThemeViewData(themes: _themes, current: 'indigo', selected: selected),
);

void main() {
  late MockRemote remote;
  setUpAll(() => registerFallbackValue(''));
  setUp(() => remote = MockRemote());

  ThemeBloc build() => ThemeBloc(remote, slug: 'toko');

  blocTest<ThemeBloc, ThemeState>(
    'load sukses: loading lalu loaded (terpilih = tersimpan)',
    setUp: () =>
        when(() => remote.list('toko')).thenAnswer((_) async => const Right(_list)),
    build: build,
    act: (b) => b.add(const ThemeEvent.load()),
    expect: () => [
      predicate<ThemeState>(
        (s) => s.maybeWhen(loading: () => true, orElse: () => false),
      ),
      _loaded(
        (v) =>
            v.themes.length == 2 &&
            v.current == 'indigo' &&
            v.selected == 'indigo' &&
            !v.isDirty,
      ),
    ],
  );

  blocTest<ThemeBloc, ThemeState>(
    'load gagal: loading lalu error',
    setUp: () =>
        when(() => remote.list('toko')).thenAnswer((_) async => const Left(_fail)),
    build: build,
    act: (b) => b.add(const ThemeEvent.load()),
    expect: () => [
      isA<ThemeState>(),
      predicate<ThemeState>(
        (s) => s.maybeWhen(error: (f) => f.statusCode == 500, orElse: () => false),
      ),
    ],
  );

  blocTest<ThemeBloc, ThemeState>(
    'select kode yang ada: selected berubah, isDirty true',
    build: build,
    seed: _seed,
    act: (b) => b.add(const ThemeEvent.select('hutan')),
    expect: () => [_loaded((v) => v.selected == 'hutan' && v.isDirty)],
  );

  blocTest<ThemeBloc, ThemeState>(
    'select kode yang tidak ada diabaikan',
    build: build,
    seed: _seed,
    act: (b) => b.add(const ThemeEvent.select('ngawur')),
    expect: () => <Object>[],
  );

  blocTest<ThemeBloc, ThemeState>(
    'save sukses: isSaving lalu savedTenant terisi dan current ikut berubah',
    setUp: () => when(
      () => remote.update('toko', 'hutan'),
    ).thenAnswer((_) async => const Right(_tenant)),
    build: build,
    seed: () => _seed(selected: 'hutan'),
    act: (b) => b.add(const ThemeEvent.save()),
    expect: () => [
      _loaded((v) => v.isSaving),
      _loaded(
        (v) =>
            !v.isSaving &&
            v.current == 'hutan' &&
            !v.isDirty &&
            v.savedTenant?.theme?.code == 'hutan',
      ),
    ],
    verify: (_) => verify(() => remote.update('toko', 'hutan')).called(1),
  );

  blocTest<ThemeBloc, ThemeState>(
    'save gagal: pilihan dipertahankan, saveFailure terisi',
    setUp: () => when(
      () => remote.update('toko', 'hutan'),
    ).thenAnswer((_) async => const Left(_fail)),
    build: build,
    seed: () => _seed(selected: 'hutan'),
    act: (b) => b.add(const ThemeEvent.save()),
    expect: () => [
      _loaded((v) => v.isSaving),
      _loaded(
        (v) =>
            !v.isSaving &&
            v.selected == 'hutan' &&
            v.current == 'indigo' &&
            v.saveFailure?.statusCode == 500 &&
            v.savedTenant == null,
      ),
    ],
  );

  blocTest<ThemeBloc, ThemeState>(
    'save tanpa perubahan tidak memanggil server',
    build: build,
    seed: _seed,
    act: (b) => b.add(const ThemeEvent.save()),
    expect: () => <Object>[],
    verify: (_) => verifyNever(() => remote.update(any(), any())),
  );
}
