import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/sections_local_datasource.dart';
import 'package:compro_builder/data/datasources/sections_remote_datasource.dart';
import 'package:compro_builder/data/model/response/section_model.dart';
import 'package:compro_builder/presentation/bloc/sections/sections_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements SectionsRemoteDatasource {}

class MockLocal extends Mock implements SectionsLocalDatasource {}

SectionModel _s(
  int id, {
  bool enabled = true,
  int order = 0,
  bool locked = false,
}) => SectionModel(
  id: id,
  type: 'about',
  name: 'S$id',
  order: order,
  isEnabled: enabled,
  locked: locked,
);

SectionsDataModel _data(
  List<SectionModel> sections, {
  int? used,
  int? limit = 5,
}) => SectionsDataModel(
  sections: sections,
  used: used ?? sections.length,
  limit: limit,
);

const _offline = ApiFailure('Tidak dapat terhubung ke server.');
const _forbidden = ApiFailure('Situs disuspend.', statusCode: 403);

/// Cocokkan state `loaded` dengan syarat pada view-nya.
Matcher _loaded(bool Function(SectionsViewData v) test) =>
    predicate<SectionsState>(
      (s) => s.maybeWhen(loaded: test, orElse: () => false),
      'loaded yang memenuhi syarat',
    );

void main() {
  late MockRemote remote;
  late MockLocal local;

  setUpAll(() {
    registerFallbackValue(_data(const []));
    registerFallbackValue(const SectionTypeModel(type: 't', name: 't'));
  });

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    when(() => local.write(any(), any())).thenAnswer((_) async {});
    when(() => local.read(any())).thenAnswer((_) async => null);
  });

  SectionsBloc build() => SectionsBloc(remote, local, slug: 'toko');
  SectionsState seeded(SectionsDataModel d) =>
      SectionsState.loaded(SectionsViewData(data: d));

  group('fetch', () {
    blocTest<SectionsBloc, SectionsState>(
      'sukses: loading -> loaded dan menulis cache',
      setUp: () =>
          when(() => remote.list('toko'))
              .thenAnswer((_) async => Right(_data([_s(1)]))),
      build: build,
      act: (b) => b.add(const SectionsEvent.fetch()),
      expect: () => [
        predicate<SectionsState>(
          (s) => s.maybeWhen(loading: () => true, orElse: () => false),
        ),
        _loaded((v) => v.data.sections.length == 1 && !v.fromCache),
      ],
      verify: (_) => verify(() => local.write('toko', any())).called(1),
    );

    blocTest<SectionsBloc, SectionsState>(
      'offline + ada cache: loaded fromCache',
      setUp: () {
        when(() => remote.list('toko'))
            .thenAnswer((_) async => const Left(_offline));
        when(() => local.read('toko')).thenAnswer((_) async => _data([_s(1)]));
      },
      build: build,
      act: (b) => b.add(const SectionsEvent.fetch()),
      expect: () => [
        isA<SectionsState>(),
        _loaded((v) => v.fromCache && v.data.sections.length == 1),
      ],
    );

    blocTest<SectionsBloc, SectionsState>(
      '403 tanpa cache: error (cache tidak dipakai untuk galat server)',
      setUp: () =>
          when(() => remote.list('toko'))
              .thenAnswer((_) async => const Left(_forbidden)),
      build: build,
      act: (b) => b.add(const SectionsEvent.fetch()),
      expect: () => [
        isA<SectionsState>(),
        predicate<SectionsState>(
          (s) => s.maybeWhen(
            error: (f) => f.statusCode == 403,
            orElse: () => false,
          ),
        ),
      ],
      verify: (_) => verifyNever(() => local.read(any())),
    );
  });

  group('toggle', () {
    blocTest<SectionsBloc, SectionsState>(
      'optimistic lalu diganti section dari server',
      setUp: () =>
          when(() => remote.toggle('toko', 1))
              .thenAnswer((_) async => Right(_s(1, enabled: false))),
      build: build,
      seed: () => seeded(_data([_s(1), _s(2)])),
      act: (b) => b.add(const SectionsEvent.toggle(1)),
      expect: () => [
        _loaded((v) => !v.data.sections.first.isEnabled),
        _loaded(
          (v) => !v.data.sections.first.isEnabled && v.actionFailure == null,
        ),
      ],
      verify: (_) => verify(() => local.write('toko', any())).called(1),
    );

    blocTest<SectionsBloc, SectionsState>(
      'gagal: rollback + actionFailure',
      setUp: () =>
          when(() => remote.toggle('toko', 1))
              .thenAnswer((_) async => const Left(_forbidden)),
      build: build,
      seed: () => seeded(_data([_s(1)])),
      act: (b) => b.add(const SectionsEvent.toggle(1)),
      expect: () => [
        _loaded((v) => !v.data.sections.first.isEnabled),
        _loaded(
          (v) =>
              v.data.sections.first.isEnabled && v.actionFailure == _forbidden,
        ),
      ],
    );

    blocTest<SectionsBloc, SectionsState>(
      'section terkunci diabaikan (tanpa panggilan jaringan)',
      build: build,
      seed: () => seeded(_data([_s(1, locked: true)])),
      act: (b) => b.add(const SectionsEvent.toggle(1)),
      expect: () => <SectionsState>[],
      verify: (_) => verifyNever(() => remote.toggle(any(), any())),
    );
  });

  group('move', () {
    blocTest<SectionsBloc, SectionsState>(
      'urutan akhir mengikuti balasan server',
      setUp: () => when(() => remote.move('toko', 2, up: true)).thenAnswer(
        (_) async => Right(_data([_s(2, order: 1), _s(1, order: 2)])),
      ),
      build: build,
      seed: () => seeded(_data([_s(1, order: 1), _s(2, order: 2)])),
      act: (b) => b.add(const SectionsEvent.move(2, up: true)),
      expect: () => [
        _loaded(
          (v) =>
              v.data.sections.map((s) => s.id).toList().toString() == '[2, 1]',
        ),
        _loaded(
          (v) =>
              v.data.sections.map((s) => s.id).toList().toString() == '[2, 1]',
        ),
      ],
    );

    blocTest<SectionsBloc, SectionsState>(
      'gagal: urutan dikembalikan',
      setUp: () =>
          when(() => remote.move('toko', 2, up: true))
              .thenAnswer((_) async => const Left(_offline)),
      build: build,
      seed: () => seeded(_data([_s(1), _s(2)])),
      act: (b) => b.add(const SectionsEvent.move(2, up: true)),
      expect: () => [
        _loaded((v) => v.data.sections.first.id == 2),
        _loaded(
          (v) => v.data.sections.first.id == 1 && v.actionFailure != null,
        ),
      ],
    );

    blocTest<SectionsBloc, SectionsState>(
      'paling atas tidak bisa naik lagi',
      build: build,
      seed: () => seeded(_data([_s(1), _s(2)])),
      act: (b) => b.add(const SectionsEvent.move(1, up: true)),
      expect: () => <SectionsState>[],
    );
  });

  group('delete', () {
    blocTest<SectionsBloc, SectionsState>(
      'optimistic: hapus + kuota turun',
      setUp: () =>
          when(() => remote.delete('toko', 1))
              .thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => seeded(_data([_s(1), _s(2)])),
      act: (b) => b.add(const SectionsEvent.delete(1)),
      expect: () => [
        _loaded((v) => v.data.sections.length == 1 && v.data.used == 1),
      ],
      verify: (_) => verify(() => local.write('toko', any())).called(1),
    );

    blocTest<SectionsBloc, SectionsState>(
      'gagal: section kembali + actionFailure',
      setUp: () =>
          when(() => remote.delete('toko', 1))
              .thenAnswer((_) async => const Left(_forbidden)),
      build: build,
      seed: () => seeded(_data([_s(1), _s(2)])),
      act: (b) => b.add(const SectionsEvent.delete(1)),
      expect: () => [
        _loaded((v) => v.data.sections.length == 1),
        _loaded(
          (v) =>
              v.data.sections.length == 2 &&
              v.data.used == 2 &&
              v.actionFailure != null,
        ),
      ],
    );
  });

  group('add', () {
    const type = SectionTypeModel(type: 'faq', name: 'FAQ', sectionTypeId: 7);

    blocTest<SectionsBloc, SectionsState>(
      'sukses: isAdding lalu daftar dimuat ulang + notice',
      setUp: () {
        when(() => remote.add('toko', any()))
            .thenAnswer((_) async => Right(_s(9)));
        when(() => remote.list('toko'))
            .thenAnswer((_) async => Right(_data([_s(1), _s(9)])));
      },
      build: build,
      seed: () => seeded(_data([_s(1)])),
      act: (b) => b.add(const SectionsEvent.add(type)),
      expect: () => [
        _loaded((v) => v.isAdding),
        _loaded(
          (v) =>
              !v.isAdding &&
              v.data.sections.length == 2 &&
              v.notice == SectionsNotice.sectionAdded,
        ),
      ],
    );

    blocTest<SectionsBloc, SectionsState>(
      'gagal (403 batas paket): isAdding mati + actionFailure',
      setUp: () =>
          when(() => remote.add('toko', any()))
              .thenAnswer((_) async => const Left(_forbidden)),
      build: build,
      seed: () => seeded(_data([_s(1)])),
      act: (b) => b.add(const SectionsEvent.add(type)),
      expect: () => [
        _loaded((v) => v.isAdding),
        _loaded(
          (v) =>
              !v.isAdding &&
              v.actionFailure != null &&
              v.data.sections.length == 1,
        ),
      ],
      verify: (_) => verifyNever(() => remote.list(any())),
    );

    blocTest<SectionsBloc, SectionsState>(
      'tambah sukses tetapi muat ulang gagal: section baru tetap ditambahkan lokal',
      setUp: () {
        when(() => remote.add('toko', any()))
            .thenAnswer((_) async => Right(_s(9)));
        when(() => remote.list('toko'))
            .thenAnswer((_) async => const Left(_offline));
      },
      build: build,
      seed: () => seeded(_data([_s(1)])),
      act: (b) => b.add(const SectionsEvent.add(type)),
      expect: () => [
        _loaded((v) => v.isAdding),
        _loaded(
          (v) => !v.isAdding && v.data.sections.length == 2 && v.data.used == 2,
        ),
      ],
    );
  });

  blocTest<SectionsBloc, SectionsState>(
    'sectionReplaced mengganti satu section tanpa muat ulang',
    build: build,
    seed: () => seeded(_data([_s(1), _s(2)])),
    act: (b) => b.add(
      SectionsEvent.sectionReplaced(
        const SectionModel(id: 2, type: 'about', name: 'Baru'),
      ),
    ),
    expect: () => [
      _loaded(
        (v) =>
            v.data.sections[1].name == 'Baru' &&
            v.data.sections[0].name == 'S1',
      ),
    ],
    verify: (_) => verifyNever(() => remote.list(any())),
  );
}
