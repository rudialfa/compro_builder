import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/data/datasources/sites_local_datasource.dart';
import 'package:compro_builder/data/datasources/sites_remote_datasource.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements SitesRemoteDatasource {}

class MockLocal extends Mock implements SitesLocalDatasource {}

const _a = TenantModel(id: 1, name: 'Kopi A', slug: 'kopi-a');
const _b = TenantModel(id: 2, name: 'Kopi B', slug: 'kopi-b');

void main() {
  late MockLocal local;

  setUpAll(() => registerFallbackValue(<TenantModel>[]));

  setUp(() {
    local = MockLocal();
    when(() => local.writeTenants(any())).thenAnswer((_) async {});
    when(() => local.writeActiveSlug(any())).thenAnswer((_) async {});
  });

  SitesBloc build() => SitesBloc(MockRemote(), local);

  blocTest<SitesBloc, SitesState>(
    'slug situs aktif berganti: activeSlug ikut berpindah dan disimpan',
    build: build,
    seed: () => SitesState.loaded(
      const SitesData(tenants: [_a, _b], activeSlug: 'kopi-a'),
    ),
    act: (b) => b.add(
      const SitesEvent.tenantUpdated(
        TenantModel(id: 1, name: 'Kopi A', slug: 'kopi-baru'),
      ),
    ),
    expect: () => [
      predicate<SitesState>(
        (s) => s.maybeWhen(
          loaded: (d) =>
              d.activeSlug == 'kopi-baru' && d.tenants.first.slug == 'kopi-baru',
          orElse: () => false,
        ),
        'slug baru aktif',
      ),
    ],
    verify: (_) =>
        verify(() => local.writeActiveSlug('kopi-baru')).called(1),
  );

  blocTest<SitesBloc, SitesState>(
    'slug situs yang tidak aktif berganti: pilihan aktif tidak disimpan ulang',
    build: build,
    seed: () => SitesState.loaded(
      const SitesData(tenants: [_a, _b], activeSlug: 'kopi-a'),
    ),
    act: (b) => b.add(
      const SitesEvent.tenantUpdated(
        TenantModel(id: 2, name: 'Kopi B', slug: 'kopi-b-baru'),
      ),
    ),
    expect: () => [
      predicate<SitesState>(
        (s) => s.maybeWhen(
          loaded: (d) => d.activeSlug == 'kopi-a',
          orElse: () => false,
        ),
        'aktif tetap',
      ),
    ],
    verify: (_) => verifyNever(() => local.writeActiveSlug(any())),
  );
}
