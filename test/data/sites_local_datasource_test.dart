import 'dart:convert';

import 'package:compro_builder/data/datasources/sites_local_datasource.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('belum ada cache -> null', () async {
    expect(await SitesLocalDatasource().readTenants(), isNull);
    expect(await SitesLocalDatasource().readActiveSlug(), isNull);
  });

  test('tulis lalu baca daftar situs dan slug aktif', () async {
    final local = SitesLocalDatasource();
    await local.writeTenants([
      const TenantModel(
        id: 1,
        name: 'A',
        slug: 'a',
        status: SiteStatus.published,
        plan: PlanSummaryModel(code: 'standar', name: 'Standar', level: 1),
        unreadMessages: 2,
      ),
    ]);
    await local.writeActiveSlug('a');

    final read = await local.readTenants();
    expect(read, hasLength(1));
    expect(read!.single.plan?.name, 'Standar');
    expect(read.single.unreadMessages, 2);
    expect(await local.readActiveSlug(), 'a');
  });

  test('format cache versi lama (list di akar) tetap terbaca', () async {
    SharedPreferences.setMockInitialValues({
      'cache_tenants': jsonEncode([
        {
          'id': 1,
          'name': 'Lama',
          'slug': 'lama',
          'plan': 'Standar',
          'status': 'draft',
          'unread_count': 3,
        }
      ]),
    });
    final read = await SitesLocalDatasource().readTenants();
    expect(read!.single.slug, 'lama');
    expect(read.single.unreadMessages, 3);
  });

  test('cache rusak -> null, tidak melempar', () async {
    SharedPreferences.setMockInitialValues({'cache_tenants': '{rusak'});
    expect(await SitesLocalDatasource().readTenants(), isNull);
  });

  test('clear menghapus daftar dan slug aktif', () async {
    final local = SitesLocalDatasource();
    await local.writeTenants(const [TenantModel(name: 'A', slug: 'a')]);
    await local.writeActiveSlug('a');
    await local.clear();
    expect(await local.readTenants(), isNull);
    expect(await local.readActiveSlug(), isNull);
  });
}
