import 'dart:convert';

import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/datasources/template_remote_datasource.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _listing({String active = 'classic'}) => {
  'active': active,
  'chosen': active,
  'templates': [
    {
      'code': 'classic',
      'name': 'Classic',
      'tier': 'classic',
      'min_level': 1,
      'locked': false,
      'active': active == 'classic',
    },
    {
      'code': 'elegan',
      'name': 'Elegan',
      'tier': 'pro',
      'min_level': 3,
      'locked': false,
      'active': active == 'elegan',
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final datasource = TemplateRemoteDatasource();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
    ApiHelper.sessionExpired.value = 0;
  });

  tearDown(() => ApiHelper.client = http.Client());

  test('GET /{slug}/manage/templates dengan Bearer -> Right', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(jsonEncode({'data': _listing()}), 200);
    });

    final r = await datasource.list('kopi kita');
    final m = r.getOrElse(() => throw StateError('harus Right'));

    expect(captured.method, 'GET');
    expect(captured.url.path, endsWith('/kopi%20kita/manage/templates'));
    expect(captured.headers['Authorization'], 'Bearer tok');
    expect(m.active, 'classic');
    expect(m.templates.length, 2);
  });

  test('PUT /{slug}/manage/template mengirim {template} dan membaca summary', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({
          'data': {
            ..._listing(active: 'elegan'),
            'summary': {
              'id': 1,
              'name': 'Kopi Kita',
              'slug': 'kopikita',
              'template': {
                'code': 'elegan',
                'name': 'Elegan',
                'tier': 'pro',
                'min_level': 3,
              },
            },
          },
          'message': 'Tampilan diganti ke Elegan.',
        }),
        200,
      );
    });

    final r = await datasource.update('kopikita', 'elegan');
    final m = r.getOrElse(() => throw StateError('harus Right'));

    expect(captured.method, 'PUT');
    expect(captured.url.path, endsWith('/kopikita/manage/template'));
    expect(jsonDecode(captured.body), {'template': 'elegan'});
    expect(m.templates.active, 'elegan');
    expect(m.tenant.template?.code, 'elegan');
  });

  test('403 template_locked -> Left membawa pesan server', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'message': 'Template Elegan tersedia di paket Pro.',
          'code': 'template_locked',
          'plan_required': {'level': 3, 'name': 'Pro'},
        }),
        403,
      ),
    );

    final r = await datasource.update('kopikita', 'elegan');
    final f = r.fold((l) => l, (_) => throw StateError('harus Left'));
    expect(f.statusCode, 403);
    expect(f.isForbidden, isTrue);
    expect(f.message, 'Template Elegan tersedia di paket Pro.');
  });

  test('422 kode tidak dikenal -> Left dengan fieldErrors', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'message': 'Template tidak dikenal.',
          'errors': {'template': ['Template tidak dikenal.']},
        }),
        422,
      ),
    );

    final r = await datasource.update('kopikita', 'ngawur');
    final f = r.fold((l) => l, (_) => throw StateError('harus Left'));
    expect(f.isValidation, isTrue);
    expect(f.errorFor('template'), 'Template tidak dikenal.');
  });

  test('200 tanpa summary -> Left format tidak sesuai', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(jsonEncode({'data': _listing()}), 200),
    );
    final r = await datasource.update('kopikita', 'classic');
    final f = r.fold((l) => l, (_) => throw StateError('harus Left'));
    expect(f.message, 'Format data dari server tidak sesuai.');
  });

  test('POST preview-link -> Right dengan url', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({
          'data': {
            'url': 'https://x.test/api/kopikita/manage/templates/elegan/preview?signature=s',
            'expires_at': '2026-11-09T10:00:00+00:00',
          },
        }),
        200,
      );
    });

    final r = await datasource.previewLink('kopikita', 'elegan');
    final m = r.getOrElse(() => throw StateError('harus Right'));

    expect(captured.method, 'POST');
    expect(
      captured.url.path,
      endsWith('/kopikita/manage/templates/elegan/preview-link'),
    );
    expect(captured.headers['Authorization'], 'Bearer tok');
    expect(m.url, contains('signature=s'));
  });

  test('401 menghapus token dan menaikkan sessionExpired', () async {
    ApiHelper.client = MockClient((_) async => http.Response('{}', 401));
    final r = await datasource.list('kopikita');
    expect(r.isLeft(), isTrue);
    expect(ApiHelper.sessionExpired.value, 1);
  });
}
