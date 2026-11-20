import 'dart:convert';

import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/datasources/checklist_remote_datasource.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final datasource = ChecklistRemoteDatasource();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
    ApiHelper.sessionExpired.value = 0;
  });

  tearDown(() => ApiHelper.client = http.Client());

  test('GET /{slug}/manage/checklist dengan Bearer -> Right', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({
          'data': {
            'percent': 100,
            'total': 1,
            'counts': {'lengkap': 1, 'sebagian': 0, 'kosong': 0},
            'items': [],
            'publish': {'status': 'published', 'blockers': [], 'can_publish': true},
          },
        }),
        200,
      );
    });

    final r = await datasource.get('kopi kita');
    final m = r.getOrElse(() => throw StateError('harus Right'));

    expect(captured.method, 'GET');
    expect(captured.url.path, endsWith('/kopi%20kita/manage/checklist'));
    expect(captured.headers['Authorization'], 'Bearer tok');
    expect(m.percent, 100);
  });

  test('403 -> Left dengan pesan server', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(jsonEncode({'message': 'Tidak diizinkan.'}), 403),
    );
    final r = await datasource.get('toko');
    final f = r.fold((l) => l, (_) => null);
    expect(f?.isForbidden, isTrue);
    expect(f?.message, 'Tidak diizinkan.');
  });

  test('401 -> sessionExpired naik', () async {
    ApiHelper.client = MockClient((_) async => http.Response('{}', 401));
    await datasource.get('toko');
    expect(ApiHelper.sessionExpired.value, 1);
  });

  test('galat 500 memakai pesan cadangan Indonesia', () async {
    ApiHelper.client = MockClient((_) async => http.Response('boom', 500));
    final r = await datasource.get('toko');
    expect(r.fold((l) => l.message, (_) => ''), 'Gagal memuat kelengkapan situs.');
  });
}
