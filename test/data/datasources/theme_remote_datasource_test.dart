import 'dart:convert';

import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/datasources/theme_remote_datasource.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final datasource = ThemeRemoteDatasource();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
    ApiHelper.sessionExpired.value = 0;
  });

  tearDown(() => ApiHelper.client = http.Client());

  test('GET /{slug}/manage/themes dengan Bearer -> Right', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({
          'data': {
            'current': 'indigo',
            'themes': [
              {'code': 'indigo', 'name': 'Indigo'},
              {'code': 'hutan', 'name': 'Hutan'},
            ],
          },
        }),
        200,
      );
    });

    final r = await datasource.list('kopi kita');
    final m = r.getOrElse(() => throw StateError('harus Right'));

    expect(captured.method, 'GET');
    expect(captured.url.path, endsWith('/kopi%20kita/manage/themes'));
    expect(captured.headers['Authorization'], 'Bearer tok');
    expect(m.current, 'indigo');
    expect(m.themes.length, 2);
  });

  test('PUT /{slug}/manage/theme mengirim {theme} dan membaca tenantSummary', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({
          'data': {
            'id': 1,
            'name': 'Kopi Kita',
            'slug': 'kopikita',
            'status': 'draft',
            'theme': {'code': 'hutan', 'name': 'Hutan', 'brand': '#14402f'},
          },
        }),
        200,
      );
    });

    final r = await datasource.update('kopikita', 'hutan');
    final t = r.getOrElse(() => throw StateError('harus Right'));

    expect(captured.method, 'PUT');
    expect(captured.url.path, endsWith('/kopikita/manage/theme'));
    expect(jsonDecode(captured.body), {'theme': 'hutan'});
    expect(t.theme?.code, 'hutan');
  });

  test('422 kode tema tidak dikenal -> Left dengan fieldErrors', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'message': 'The given data was invalid.',
          'errors': {
            'theme': ['Pilihan warna tidak dikenal.'],
          },
        }),
        422,
      ),
    );
    final f = (await datasource.update('toko', 'ngawur')).fold((l) => l, (_) => null);
    expect(f?.isValidation, isTrue);
    expect(f?.errorFor('theme'), 'Pilihan warna tidak dikenal.');
  });

  test('200 tanpa situs yang bisa dibaca -> Left (format tidak sesuai)', () async {
    ApiHelper.client = MockClient((_) async => http.Response('{"data":{}}', 200));
    final f = (await datasource.update('toko', 'hutan')).fold((l) => l, (_) => null);
    expect(f, isNotNull);
    expect(f?.statusCode, isNull);
  });

  test('401 -> sessionExpired naik', () async {
    ApiHelper.client = MockClient((_) async => http.Response('{}', 401));
    await datasource.list('toko');
    expect(ApiHelper.sessionExpired.value, 1);
  });
}
