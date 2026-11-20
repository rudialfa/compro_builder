import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/template_remote_datasource.dart';
import 'package:compro_builder/data/model/response/template_response_model.dart';
import 'package:compro_builder/data/model/response/template_update_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/presentation/bloc/template/template_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements TemplateRemoteDatasource {}

const _classic = TemplateOptionModel(
  code: 'classic',
  name: 'Classic',
  tier: 'classic',
  minLevel: 1,
  active: true,
);
const _medium = TemplateOptionModel(
  code: 'modern',
  name: 'Modern',
  tier: 'medium',
  minLevel: 2,
);
const _pro = TemplateOptionModel(
  code: 'elegan',
  name: 'Elegan',
  tier: 'pro',
  minLevel: 3,
  requiredPlanName: 'Pro',
  locked: true,
);
const _all = [_classic, _medium, _pro];
const _list = TemplatesResponseModel(
  active: 'classic',
  chosen: 'classic',
  templates: _all,
);

const _tenant = TenantModel(
  id: 1,
  name: 'Kopi Kita',
  slug: 'toko',
  template: TemplateSummaryModel(
    code: 'modern',
    name: 'Modern',
    tier: 'medium',
    minLevel: 2,
  ),
);
const _updated = TemplateUpdateResponseModel(
  templates: TemplatesResponseModel(
    active: 'modern',
    chosen: 'modern',
    templates: [
      TemplateOptionModel(code: 'classic', name: 'Classic', tier: 'classic'),
      TemplateOptionModel(
        code: 'modern',
        name: 'Modern',
        tier: 'medium',
        active: true,
      ),
      _pro,
    ],
  ),
  tenant: _tenant,
);
const _fail = ApiFailure('Gagal.', statusCode: 500);

Matcher _loaded(bool Function(TemplateViewData v) check) =>
    predicate<TemplateState>(
      (s) => s.maybeWhen(loaded: check, orElse: () => false),
      'loaded',
    );

TemplateState _seed() => const TemplateState.loaded(
  TemplateViewData(templates: _all, active: 'classic', chosen: 'classic'),
);

void main() {
  late MockRemote remote;
  setUpAll(() => registerFallbackValue(''));
  setUp(() => remote = MockRemote());

  TemplateBloc build() => TemplateBloc(remote, slug: 'toko');

  blocTest<TemplateBloc, TemplateState>(
    'load sukses: loading lalu loaded',
    setUp: () => when(() => remote.list('toko'))
        .thenAnswer((_) async => const Right(_list)),
    build: build,
    act: (b) => b.add(const TemplateEvent.load()),
    expect: () => [
      predicate<TemplateState>(
        (s) => s.maybeWhen(loading: () => true, orElse: () => false),
      ),
      _loaded(
        (v) =>
            v.templates.length == 3 &&
            v.active == 'classic' &&
            !v.chosenInactive &&
            !v.isBusy,
      ),
    ],
  );

  blocTest<TemplateBloc, TemplateState>(
    'load gagal pertama kali: loading lalu error',
    setUp: () => when(() => remote.list('toko'))
        .thenAnswer((_) async => const Left(_fail)),
    build: build,
    act: (b) => b.add(const TemplateEvent.load()),
    expect: () => [
      isA<TemplateState>(),
      predicate<TemplateState>(
        (s) => s.maybeWhen(
          error: (f) => f.statusCode == 500,
          orElse: () => false,
        ),
      ),
    ],
  );

  blocTest<TemplateBloc, TemplateState>(
    'load ulang gagal: data lama dipertahankan, failure terisi',
    setUp: () => when(() => remote.list('toko'))
        .thenAnswer((_) async => const Left(_fail)),
    build: build,
    seed: _seed,
    act: (b) => b.add(const TemplateEvent.load()),
    expect: () => [
      _loaded((v) => v.templates.length == 3 && v.failure?.statusCode == 500),
    ],
  );

  blocTest<TemplateBloc, TemplateState>(
    'chosenInactive true bila pilihan tersimpan beda dari yang aktif',
    setUp: () => when(() => remote.list('toko')).thenAnswer(
      (_) async => const Right(
        TemplatesResponseModel(
          active: 'classic',
          chosen: 'elegan',
          templates: _all,
        ),
      ),
    ),
    build: build,
    act: (b) => b.add(const TemplateEvent.load()),
    skip: 1,
    expect: () => [_loaded((v) => v.chosenInactive)],
  );

  blocTest<TemplateBloc, TemplateState>(
    'apply sukses: applying lalu appliedTenant terisi dan daftar diperbarui',
    setUp: () => when(() => remote.update('toko', 'modern'))
        .thenAnswer((_) async => const Right(_updated)),
    build: build,
    seed: _seed,
    act: (b) => b.add(const TemplateEvent.apply('modern')),
    expect: () => [
      _loaded((v) => v.applyingCode == 'modern' && v.isBusy),
      _loaded(
        (v) =>
            !v.isBusy &&
            v.active == 'modern' &&
            v.appliedTenant?.template?.code == 'modern',
      ),
    ],
    verify: (_) => verify(() => remote.update('toko', 'modern')).called(1),
  );

  blocTest<TemplateBloc, TemplateState>(
    'apply gagal: failure terisi, penanda proses dibersihkan, aktif tetap',
    setUp: () => when(() => remote.update('toko', 'modern'))
        .thenAnswer((_) async => const Left(_fail)),
    build: build,
    seed: _seed,
    act: (b) => b.add(const TemplateEvent.apply('modern')),
    expect: () => [
      _loaded((v) => v.isBusy),
      _loaded(
        (v) =>
            !v.isBusy &&
            v.active == 'classic' &&
            v.failure?.statusCode == 500 &&
            v.appliedTenant == null,
      ),
    ],
  );

  blocTest<TemplateBloc, TemplateState>(
    'apply template terkunci diabaikan, server tidak dipanggil',
    build: build,
    seed: _seed,
    act: (b) => b.add(const TemplateEvent.apply('elegan')),
    expect: () => <Object>[],
    verify: (_) => verifyNever(() => remote.update(any(), any())),
  );

  blocTest<TemplateBloc, TemplateState>(
    'apply template yang sudah aktif diabaikan',
    build: build,
    seed: _seed,
    act: (b) => b.add(const TemplateEvent.apply('classic')),
    expect: () => <Object>[],
    verify: (_) => verifyNever(() => remote.update(any(), any())),
  );

  blocTest<TemplateBloc, TemplateState>(
    'apply kode yang tidak ada diabaikan',
    build: build,
    seed: _seed,
    act: (b) => b.add(const TemplateEvent.apply('ngawur')),
    expect: () => <Object>[],
    verify: (_) => verifyNever(() => remote.update(any(), any())),
  );

  blocTest<TemplateBloc, TemplateState>(
    'preview sukses: previewing lalu previewTarget terisi',
    setUp: () => when(() => remote.previewLink('toko', 'modern')).thenAnswer(
      (_) async => const Right(PreviewLinkModel(url: 'https://x.test/p?s=1')),
    ),
    build: build,
    seed: _seed,
    act: (b) => b.add(const TemplateEvent.preview('modern')),
    expect: () => [
      _loaded((v) => v.previewingCode == 'modern' && v.isBusy),
      _loaded(
        (v) =>
            !v.isBusy &&
            v.previewTarget?.name == 'Modern' &&
            v.previewTarget?.url == 'https://x.test/p?s=1',
      ),
    ],
  );

  blocTest<TemplateBloc, TemplateState>(
    'preview template terkunci tetap diminta ke server',
    setUp: () => when(() => remote.previewLink('toko', 'elegan')).thenAnswer(
      (_) async => const Right(PreviewLinkModel(url: 'https://x.test/p?s=2')),
    ),
    build: build,
    seed: _seed,
    act: (b) => b.add(const TemplateEvent.preview('elegan')),
    skip: 1,
    expect: () => [_loaded((v) => v.previewTarget?.name == 'Elegan')],
  );

  blocTest<TemplateBloc, TemplateState>(
    'preview gagal: failure terisi, tanpa previewTarget',
    setUp: () => when(() => remote.previewLink('toko', 'modern'))
        .thenAnswer((_) async => const Left(_fail)),
    build: build,
    seed: _seed,
    act: (b) => b.add(const TemplateEvent.preview('modern')),
    skip: 1,
    expect: () => [
      _loaded(
        (v) => !v.isBusy && v.failure != null && v.previewTarget == null,
      ),
    ],
  );
}
