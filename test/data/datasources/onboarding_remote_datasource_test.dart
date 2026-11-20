import 'dart:convert';

import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/datasources/onboarding_remote_datasource.dart';
import 'package:compro_builder/data/model/request/onboarding_request_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _summary({bool needs = false}) => jsonEncode({
  'data': {
    'id': 1,
    'name': 'Kopi Kita',
    'slug': 'kopikita',
    'status': 'draft',
    'needs_onboarding': needs,
  },
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final datasource = OnboardingRemoteDatasource();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
    ApiHelper.sessionExpired.value = 0;
  });

  tearDown(() => ApiHelper.client = http.Client());

  test('GET /{slug}/manage/onboarding -> Right', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({
          'data': {
            'needed': true,
            'state': null,
            'values': {'name': 'Kopi Kita', 'subtitle': '', 'whatsapp': '', 'theme': 'indigo'},
            'themes': [
              {'code': 'indigo', 'name': 'Indigo'},
            ],
          },
        }),
        200,
      );
    });

    final m = (await datasource.show('kopikita')).getOrElse(
      () => throw StateError('harus Right'),
    );

    expect(captured.method, 'GET');
    expect(captured.url.path, endsWith('/kopikita/manage/onboarding'));
    expect(captured.headers['Authorization'], 'Bearer tok');
    expect(m.needed, isTrue);
    expect(m.values.theme, 'indigo');
  });

  test('POST onboarding mengirim isian (tanpa nilai kosong) -> tenantSummary', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(_summary(), 200);
    });

    final r = await datasource.submit(
      'kopikita',
      const OnboardingRequestModel(name: 'Kopi Kita', theme: 'hutan'),
    );
    final t = r.getOrElse(() => throw StateError('harus Right'));

    expect(captured.method, 'POST');
    expect(captured.url.path, endsWith('/kopikita/manage/onboarding'));
    expect(jsonDecode(captured.body), {'name': 'Kopi Kita', 'theme': 'hutan'});
    expect(t.slug, 'kopikita');
    expect(t.needsOnboarding, isFalse);
  });

  test('POST onboarding 422 -> Left dengan fieldErrors', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'message': 'The given data was invalid.',
          'errors': {
            'name': ['Nama usaha wajib diisi.'],
          },
        }),
        422,
      ),
    );
    final f = (await datasource.submit(
      'toko',
      const OnboardingRequestModel(name: ' ', theme: 'indigo'),
    )).fold((l) => l, (_) => null);
    expect(f?.isValidation, isTrue);
    expect(f?.errorFor('name'), 'Nama usaha wajib diisi.');
  });

  test('POST onboarding/skip -> Right', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(_summary(), 200);
    });
    final t = (await datasource.skip('kopikita')).getOrElse(
      () => throw StateError('harus Right'),
    );
    expect(captured.method, 'POST');
    expect(captured.url.path, endsWith('/kopikita/manage/onboarding/skip'));
    expect(t.name, 'Kopi Kita');
  });

  test('403 -> Left dengan pesan server', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(jsonEncode({'message': 'Tidak diizinkan.'}), 403),
    );
    final f = (await datasource.skip('toko')).fold((l) => l, (_) => null);
    expect(f?.isForbidden, isTrue);
    expect(f?.message, 'Tidak diizinkan.');
  });

  test('401 -> sessionExpired naik', () async {
    ApiHelper.client = MockClient((_) async => http.Response('{}', 401));
    await datasource.show('toko');
    expect(ApiHelper.sessionExpired.value, 1);
  });
}
