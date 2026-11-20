import 'dart:convert';
import 'dart:typed_data';

import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/datasources/plan_remote_datasource.dart';
import 'package:compro_builder/data/datasources/settings_remote_datasource.dart';
import 'package:compro_builder/data/model/request/settings_changes_model.dart';
import 'package:compro_builder/data/model/response/site_settings_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _settingsBody = {
  'data': {
    'name': 'Toko',
    'slug': 'toko',
    'url': 'http://toko.test',
    'logo': null,
    'favicon': 'http://x/f.png',
    'plan': 'medium',
    'theme': {
      'code': 'brand',
      'brand': '#112233',
      'bright': '#445566',
      'soft': '#778899',
    },
    'seo': {'title': 'T', 'description': null},
    'socials': {
      'instagram': {'label': 'Instagram', 'url': 'https://instagram.com/a'},
    },
    'notify_email': 'a@b.c',
  },
};

SiteSettingsModel _model() =>
    SiteSettingsModel.fromJson(jsonEncode(_settingsBody));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
    ApiHelper.sessionExpired.value = 0;
  });

  tearDown(() => ApiHelper.client = http.Client());

  group('settings get', () {
    test('membaca bentuk backend: seo bersarang, socials {code:{label,url}}, theme objek', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode(_settingsBody), 200);
      });
      final s = (await SettingsRemoteDatasource().get('toko'))
          .getOrElse(() => throw StateError('Left'));
      expect(captured.url.path, endsWith('/toko/manage/settings'));
      expect(s.seoTitle, 'T');
      expect(s.seoDescription, '');
      expect(s.socials, {'instagram': 'https://instagram.com/a'});
      expect(s.theme.brand, '#112233');
      expect(s.logo, isNull);
      expect(s.favicon, 'http://x/f.png');
      expect(s.notifyEmail, 'a@b.c');
    });

    test('403 (situs disuspend) -> Left dengan pesan server', () async {
      ApiHelper.client = MockClient(
        (_) async =>
            http.Response(jsonEncode({'message': 'Situs disuspend.'}), 403),
      );
      final r = await SettingsRemoteDatasource().get('toko');
      r.fold(
        (f) => expect(f.message, 'Situs disuspend.'),
        (_) => fail('harus Left'),
      );
    });
  });

  group('settings save', () {
    test('tanpa berkas: PUT JSON dengan kunci seo_title datar', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode(_settingsBody), 200);
      });
      final changes = SettingsChangesModel.diff(_model(), {
        'seo_title': 'Baru',
      });
      final result = await SettingsRemoteDatasource().save('toko', changes);
      expect(captured.method, 'PUT');
      expect(jsonDecode(captured.body), {'seo_title': 'Baru'});
      expect(result.isRight(), isTrue);
    });

    test('logo baru: POST multipart + favicon_remove', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode(_settingsBody), 200);
      });
      final changes = SettingsChangesModel.diff(
        _model(),
        {},
        logo: Uint8List.fromList([1, 2]),
        removeFavicon: true,
      );
      await SettingsRemoteDatasource().save('toko', changes);
      expect(captured.method, 'POST');
      expect(
        captured.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      expect(captured.body, contains('name="logo"'));
      expect(captured.body, contains('name="favicon_remove"'));
    });

    test('422 membawa fieldErrors (socials.x, notify_email)', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'x',
            'errors': {
              'socials.x': ['Tempel link lengkap yang diawali https://'],
              'notify_email': ['Format email belum benar.'],
            },
          }),
          422,
        ),
      );
      final r = await SettingsRemoteDatasource().save(
        'toko',
        SettingsChangesModel.diff(_model(), {'notify_email': 'x'}),
      );
      r.fold((f) {
        expect(f.errorFor('socials.x'), startsWith('Tempel link'));
        expect(f.errorFor('notify_email'), 'Format email belum benar.');
      }, (_) => fail('harus Left'));
    });
  });

  test('plan get membaca {data: {...}} dengan harga string', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'data': {
            'code': 'medium',
            'name': 'Medium',
            'level': 2,
            'expires_at': '2026-12-01T00:00:00+00:00',
            'price': '49000.00',
            'limits': {
              'max_sections': 9,
              'max_products': null,
              'contact_form': true,
            },
            'upgrade_url': 'http://x/dashboard/tenants/1/billing',
          },
        }),
        200,
      ),
    );
    final plan = (await PlanRemoteDatasource().get('toko'))
        .getOrElse(() => throw StateError('Left'));
    expect(plan.name, 'Medium');
    expect(plan.price, 49000);
    expect(plan.upgradeUrl, contains('/billing'));
    final rows = {for (final r in plan.limitRows) r.key: r.value};
    expect(rows['max_sections'], '9');
    expect(rows['max_products'], isNull); // tanpa batas
    expect(rows['contact_form'], 'Ya');
  });
}
