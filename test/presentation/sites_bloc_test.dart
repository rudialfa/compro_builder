import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/sites_local_datasource.dart';
import 'package:compro_builder/data/datasources/sites_remote_datasource.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements SitesRemoteDatasource {}

class MockLocal extends Mock implements SitesLocalDatasource {}

const _a = TenantModel(id: 1, name: 'Kopi A', slug: 'kopi-a', unreadMessages: 3);
const _b = TenantModel(id: 2, name: 'Kopi B', slug: 'kopi-b', unreadMessages: 0);

const _network = ApiFailure('Tidak dapat terhubung ke server.');
const _server = ApiFailure('Gagal memuat daftar situs.', statusCode: 500);

Either<ApiFailure, TenantsResponseModel> _ok(List<TenantModel> list) =>
    Right(TenantsResponseModel(data: list));

Either<ApiFailure, TenantsResponseModel> _fail(ApiFailure failure) =>
    Left(failure);

// Matcher untuk state (subclass state bersifat privat).
Matcher _isLoading() => predicate<SitesState>(
    (s) => s.maybeWhen(loading: () => true, orElse: () => false), 'loading');
Matcher _isInitial() => predicate<SitesState>(
    (s) => s.maybeWhen(initial: () => true, orElse: () => false), 'initial');
Matcher _isError(String message) => predicate<SitesState>(
    (s) => s.maybeWhen(error: (f) => f.message == message, orElse: () => false),
    'error "$message"');
Matcher _isLoaded(bool Function(SitesData d) check, [String desc = 'loaded']) =>
    predicate<SitesState>(
        (s) => s.maybeWhen(loaded: check, orElse: () => false), desc);

void main() {
  late MockRemote remote;
  late MockLocal local;

  setUpAll(() => registerFallbackValue(<TenantModel>[]));

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    when(() => local.writeTenants(any())).thenAnswer((_) async {});
    when(() => local.writeActiveSlug(any())).thenAnswer((_) async {});
    when(() => local.readActiveSlug()).thenAnswer((_) async => null);
    when(() => local.readTenants()).thenAnswer((_) async => null);
    when(() => local.clear()).thenAnswer((_) async {});
  });

  SitesBloc build() => SitesBloc(remote, local);

  group('fetch', () {
    blocTest<SitesBloc, SitesState>(
      'sukses: loading -> loaded, situs pertama aktif, cache ditulis',
      setUp: () => when(() => remote.tenants()).thenAnswer((_) async => _ok([_a, _b])),
      build: build,
      act: (b) => b.add(const SitesEvent.fetch()),
      expect: () => [
        _isLoading(),
        _isLoaded((d) =>
            d.tenants.length == 2 &&
            d.activeSlug == 'kopi-a' &&
            !d.fromCache &&
            d.refreshFailure == null),
      ],
      verify: (_) => verify(() => local.writeTenants(any())).called(1),
    );

    blocTest<SitesBloc, SitesState>(
      'slug aktif tersimpan dipakai bila masih ada di daftar',
      setUp: () {
        when(() => remote.tenants()).thenAnswer((_) async => _ok([_a, _b]));
        when(() => local.readActiveSlug()).thenAnswer((_) async => 'kopi-b');
      },
      build: build,
      act: (b) => b.add(const SitesEvent.fetch()),
      expect: () => [
        _isLoading(),
        _isLoaded((d) => d.activeSlug == 'kopi-b' && d.activeTenant?.name == 'Kopi B'),
      ],
    );

    blocTest<SitesBloc, SitesState>(
      'slug aktif tersimpan yang sudah tidak ada -> situs pertama',
      setUp: () {
        when(() => remote.tenants()).thenAnswer((_) async => _ok([_a]));
        when(() => local.readActiveSlug()).thenAnswer((_) async => 'hilang');
      },
      build: build,
      act: (b) => b.add(const SitesEvent.fetch()),
      expect: () => [_isLoading(), _isLoaded((d) => d.activeSlug == 'kopi-a')],
    );

    blocTest<SitesBloc, SitesState>(
      'daftar kosong -> loaded kosong tanpa situs aktif',
      setUp: () => when(() => remote.tenants()).thenAnswer((_) async => _ok([])),
      build: build,
      act: (b) => b.add(const SitesEvent.fetch()),
      expect: () => [
        _isLoading(),
        _isLoaded((d) => d.tenants.isEmpty && d.activeSlug == null),
      ],
    );

    blocTest<SitesBloc, SitesState>(
      'galat server (5xx): error, cache TIDAK dipakai',
      setUp: () => when(() => remote.tenants()).thenAnswer((_) async => _fail(_server)),
      build: build,
      act: (b) => b.add(const SitesEvent.fetch()),
      expect: () => [_isLoading(), _isError('Gagal memuat daftar situs.')],
      verify: (_) => verifyNever(() => local.readTenants()),
    );

    blocTest<SitesBloc, SitesState>(
      'offline + ada cache: loaded dengan fromCache = true',
      setUp: () {
        when(() => remote.tenants()).thenAnswer((_) async => _fail(_network));
        when(() => local.readTenants()).thenAnswer((_) async => [_a, _b]);
        when(() => local.readActiveSlug()).thenAnswer((_) async => 'kopi-b');
      },
      build: build,
      act: (b) => b.add(const SitesEvent.fetch()),
      expect: () => [
        _isLoading(),
        _isLoaded((d) => d.fromCache && d.activeSlug == 'kopi-b' && d.tenants.length == 2),
      ],
    );

    blocTest<SitesBloc, SitesState>(
      'offline tanpa cache: error',
      setUp: () => when(() => remote.tenants()).thenAnswer((_) async => _fail(_network)),
      build: build,
      act: (b) => b.add(const SitesEvent.fetch()),
      expect: () => [_isLoading(), _isError(_network.message)],
    );

    blocTest<SitesBloc, SitesState>(
      'respons basi ditolak: fetch lama selesai belakangan tidak menimpa yang baru',
      setUp: () {
        final first = Completer<Either<ApiFailure, TenantsResponseModel>>();
        final second = Completer<Either<ApiFailure, TenantsResponseModel>>();
        final completers = [first, second];
        var call = 0;
        when(() => remote.tenants()).thenAnswer((_) => completers[call++].future);
        // Diselesaikan dari act() lewat closure di bawah.
        _pending = completers;
      },
      build: build,
      act: (b) async {
        b.add(const SitesEvent.fetch());
        b.add(const SitesEvent.fetch());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        _pending[1].complete(_ok([_b])); // yang terbaru selesai dulu
        await Future<void>.delayed(const Duration(milliseconds: 10));
        _pending[0].complete(_ok([_a])); // yang lama datang terlambat
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      expect: () => [
        // Fetch kedua mengemit loading yang sama (const) -> bloc menyaringnya,
        // jadi hanya satu loading. Yang diuji: respons lama tidak menimpa yang baru.
        _isLoading(),
        _isLoaded((d) => d.tenants.single.slug == 'kopi-b'),
      ],
    );
  });

  group('refresh', () {
    final seeded = SitesState.loaded(
      const SitesData(tenants: [_a, _b], activeSlug: 'kopi-b'),
    );

    blocTest<SitesBloc, SitesState>(
      'sukses: tanpa layar memuat, data diperbarui, situs aktif dipertahankan',
      setUp: () {
        when(() => remote.tenants()).thenAnswer((_) async => _ok([_a, _b]));
        when(() => local.readActiveSlug()).thenAnswer((_) async => 'kopi-b');
      },
      build: build,
      seed: () => seeded,
      act: (b) => b.add(const SitesEvent.refresh()),
      expect: () => [_isLoaded((d) => d.activeSlug == 'kopi-b' && !d.fromCache)],
    );

    blocTest<SitesBloc, SitesState>(
      'gagal: data lama tetap, refreshFailure terisi',
      setUp: () => when(() => remote.tenants()).thenAnswer((_) async => _fail(_network)),
      build: build,
      seed: () => seeded,
      act: (b) => b.add(const SitesEvent.refresh()),
      expect: () => [
        _isLoaded((d) =>
            d.tenants.length == 2 && d.refreshFailure?.message == _network.message),
      ],
    );

    blocTest<SitesBloc, SitesState>(
      'dari cache lalu refresh sukses: fromCache menjadi false',
      setUp: () => when(() => remote.tenants()).thenAnswer((_) async => _ok([_a])),
      build: build,
      seed: () => SitesState.loaded(
        const SitesData(tenants: [_a], activeSlug: 'kopi-a', fromCache: true),
      ),
      act: (b) => b.add(const SitesEvent.refresh()),
      expect: () => [_isLoaded((d) => !d.fromCache)],
    );
  });

  group('select', () {
    blocTest<SitesBloc, SitesState>(
      'memilih situs: state berubah dan slug disimpan',
      build: build,
      seed: () => SitesState.loaded(
        const SitesData(tenants: [_a, _b], activeSlug: 'kopi-a'),
      ),
      act: (b) => b.add(const SitesEvent.select('kopi-b')),
      expect: () => [_isLoaded((d) => d.activeSlug == 'kopi-b')],
      verify: (_) => verify(() => local.writeActiveSlug('kopi-b')).called(1),
    );

    blocTest<SitesBloc, SitesState>(
      'slug yang tidak ada diabaikan',
      build: build,
      seed: () => SitesState.loaded(
        const SitesData(tenants: [_a], activeSlug: 'kopi-a'),
      ),
      act: (b) => b.add(const SitesEvent.select('tidak-ada')),
      expect: () => <Matcher>[],
      verify: (_) => verifyNever(() => local.writeActiveSlug(any())),
    );
  });

  group('tenantUpdated', () {
    blocTest<SitesBloc, SitesState>(
      'status berubah, unreadMessages lama tidak ditimpa null',
      build: build,
      seed: () => SitesState.loaded(
        const SitesData(tenants: [_a, _b], activeSlug: 'kopi-a'),
      ),
      act: (b) => b.add(const SitesEvent.tenantUpdated(
        TenantModel(
          id: 1,
          name: 'Kopi A',
          slug: 'kopi-a',
          status: SiteStatus.published,
          unreadMessages: null,
        ),
      )),
      expect: () => [
        _isLoaded((d) =>
            d.tenants.first.status == SiteStatus.published &&
            d.tenants.first.unreadMessages == 3 &&
            d.tenants.last.slug == 'kopi-b'),
      ],
      verify: (_) => verify(() => local.writeTenants(any())).called(1),
    );

    blocTest<SitesBloc, SitesState>(
      'situs yang tidak dikenal diabaikan',
      build: build,
      seed: () => SitesState.loaded(
        const SitesData(tenants: [_a], activeSlug: 'kopi-a'),
      ),
      act: (b) => b.add(const SitesEvent.tenantUpdated(
        TenantModel(id: 99, name: 'Asing', slug: 'asing'),
      )),
      expect: () => <Matcher>[],
    );
  });

  group('reset', () {
    blocTest<SitesBloc, SitesState>(
      'kembali ke initial dan cache dihapus',
      build: build,
      seed: () => SitesState.loaded(
        const SitesData(tenants: [_a], activeSlug: 'kopi-a'),
      ),
      act: (b) => b.add(const SitesEvent.reset()),
      expect: () => [_isInitial()],
      verify: (_) => verify(() => local.clear()).called(1),
    );

    blocTest<SitesBloc, SitesState>(
      'respons yang masih berjalan saat reset diabaikan',
      setUp: () {
        final pending = Completer<Either<ApiFailure, TenantsResponseModel>>();
        _pending = [pending];
        when(() => remote.tenants()).thenAnswer((_) => pending.future);
      },
      build: build,
      act: (b) async {
        b.add(const SitesEvent.fetch());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        b.add(const SitesEvent.reset());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        _pending[0].complete(_ok([_a])); // data pengguna lama datang terlambat
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      expect: () => [_isLoading(), _isInitial()],
    );
  });
}

/// Completer yang dibagikan antara setUp dan act pada tes respons basi.
List<Completer<Either<ApiFailure, TenantsResponseModel>>> _pending = [];
