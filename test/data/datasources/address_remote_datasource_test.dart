import 'dart:convert';

import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/datasources/address_remote_datasource.dart';
import 'package:compro_builder/data/model/response/address_response_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final datasource = AddressRemoteDatasource();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
    ApiHelper.sessionExpired.value = 0;
  });

  tearDown(() => ApiHelper.client = http.Client());

  test('GET slug/check mengirim ?slug= dengan Bearer', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({
          'data': {
            'ok': true,
            'state': 'available',
            'message': 'Alamat ini tersedia.',
            'slug': 'toko-baru',
          },
        }),
        200,
      );
    });

    final r = await datasource.check('kopikita', 'toko-baru');
    final m = r.getOrElse(() => throw StateError('harus Right'));

    expect(captured.method, 'GET');
    expect(captured.url.path, endsWith('/kopikita/manage/slug/check'));
    expect(captured.url.queryParameters['slug'], 'toko-baru');
    expect(captured.headers['Authorization'], 'Bearer tok');
    expect(m.status, SlugCheckStatus.available);
  });

  test('check 429 -> Left isRateLimited', () async {
    ApiHelper.client = MockClient((_) async => http.Response('{}', 429));
    final r = await datasource.check('kopikita', 'x');
    final f = r.fold((l) => l, (_) => throw StateError('harus Left'));
    expect(f.isRateLimited, isTrue);
  });

  test('PUT slug mengirim {slug, confirm: true} dan membaca slug baru', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({
          'data': {'id': 1, 'name': 'Kopi Kita', 'slug': 'toko-baru'},
          'old_slug': 'kopikita',
        }),
        200,
      );
    });

    final r = await datasource.update('kopikita', 'toko-baru');
    final m = r.getOrElse(() => throw StateError('harus Right'));

    expect(captured.method, 'PUT');
    expect(captured.url.path, endsWith('/kopikita/manage/slug'));
    expect(jsonDecode(captured.body), {'slug': 'toko-baru', 'confirm': true});
    expect(m.tenant.slug, 'toko-baru');
    expect(m.oldSlug, 'kopikita');
  });

  test('PUT slug 422 -> Left dengan fieldErrors[slug]', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'message': 'Alamat ini sudah dipakai orang lain.',
          'errors': {'slug': ['Alamat ini sudah dipakai orang lain.']},
        }),
        422,
      ),
    );
    final r = await datasource.update('kopikita', 'toko');
    final f = r.fold((l) => l, (_) => throw StateError('harus Left'));
    expect(f.isValidation, isTrue);
    expect(f.errorFor('slug'), 'Alamat ini sudah dipakai orang lain.');
  });

  test('GET domain -> Right', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({
          'data': {'allowed': true, 'feature_ready': true, 'host': 'a.com'},
        }),
        200,
      );
    });
    final r = await datasource.domain('kopi kita');
    final m = r.getOrElse(() => throw StateError('harus Right'));
    expect(captured.url.path, endsWith('/kopi%20kita/manage/domain'));
    expect(m.host, 'a.com');
  });

  test('domain 403 -> Left', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(jsonEncode({'message': 'Bukan pemilik.'}), 403),
    );
    final r = await datasource.domain('kopikita');
    final f = r.fold((l) => l, (_) => throw StateError('harus Left'));
    expect(f.isForbidden, isTrue);
  });
}
