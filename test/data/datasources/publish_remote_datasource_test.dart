import 'dart:convert';

import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/datasources/publish_remote_datasource.dart';
import 'package:compro_builder/data/model/response/site_status_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _summary({String status = 'published'}) => {
  'id': 7,
  'name': 'Kopi Kita',
  'slug': 'kopi-kita',
  'status': status,
  'url': 'https://contoh.com/kopi-kita',
  'plan': {'code': 'medium', 'name': 'Medium', 'level': 2, 'expires_at': null},
  'unread_messages': null,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final datasource = PublishRemoteDatasource();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
    ApiHelper.sessionExpired.value = 0;
  });

  tearDown(() => ApiHelper.client = http.Client());

  group('setStatus', () {
    test('mengirim {status} ke /{slug}/manage/status dan membaca {data: tenantSummary}', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode({'data': _summary()}), 200);
      });
      final r = await datasource.setStatus('kopi-kita', SiteStatus.published);
      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/kopi-kita/manage/status'));
      expect(jsonDecode(captured.body), {'status': 'published'});
      expect(captured.headers['Authorization'], 'Bearer tok');
      final res = r.getOrElse(() => throw StateError('Left'));
      expect(res.status, SiteStatus.published);
      expect(res.tenant?.slug, 'kopi-kita');
      expect(res.tenant?.plan?.level, 2);
      // unread_messages null = tidak dikirim server; jangan dianggap 0.
      expect(res.tenant?.unreadMessages, isNull);
    });

    test('draft dikirim sebagai "draft"', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode({'data': _summary(status: 'draft')}), 200);
      });
      final r = await datasource.setStatus('kopi-kita', SiteStatus.draft);
      expect(jsonDecode(captured.body), {'status': 'draft'});
      expect(r.getOrElse(() => throw StateError('Left')).status, SiteStatus.draft);
    });

    test('slug di-encode pada path', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode({'data': _summary()}), 200);
      });
      await datasource.setStatus('a b', SiteStatus.draft);
      expect(captured.url.path, contains('/a%20b/manage/status'));
    });

    test('status unknown -> Left tanpa memanggil server', () async {
      var called = false;
      ApiHelper.client = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });
      final r = await datasource.setStatus('kopi-kita', SiteStatus.unknown);
      expect(r.isLeft(), isTrue);
      expect(called, isFalse);
    });

    test('403 dinonaktifkan admin -> isForbidden + pesan server', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Situs ini dinonaktifkan oleh admin.'}),
          403,
        ),
      );
      final r = await datasource.setStatus('kopi-kita', SiteStatus.published);
      r.fold((f) {
        expect(f.isForbidden, isTrue);
        expect(f.message, 'Situs ini dinonaktifkan oleh admin.');
      }, (_) => fail('harus Left'));
    });

    test('403 email belum terverifikasi -> pesan server', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Verifikasi email dulu sebelum menayangkan situs.'}),
          403,
        ),
      );
      final r = await datasource.setStatus('kopi-kita', SiteStatus.published);
      r.fold(
        (f) => expect(f.message, contains('Verifikasi email')),
        (_) => fail('harus Left'),
      );
    });

    test('422 -> isValidation', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'x',
            'errors': {'status': ['Status tidak valid.']},
          }),
          422,
        ),
      );
      final r = await datasource.setStatus('kopi-kita', SiteStatus.published);
      r.fold((f) {
        expect(f.isValidation, isTrue);
        expect(f.errorFor('status'), 'Status tidak valid.');
      }, (_) => fail('harus Left'));
    });

    test('429 -> retryAfter dari header', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response('{}', 429, headers: {'retry-after': '42'}),
      );
      final r = await datasource.setStatus('kopi-kita', SiteStatus.published);
      r.fold((f) {
        expect(f.isRateLimited, isTrue);
        expect(f.retryAfter, 42);
      }, (_) => fail('harus Left'));
    });

    test('401 -> sessionExpired naik', () async {
      ApiHelper.client = MockClient((_) async => http.Response('{}', 401));
      await datasource.setStatus('kopi-kita', SiteStatus.published);
      expect(ApiHelper.sessionExpired.value, 1);
    });

    test('jaringan putus -> Left tanpa statusCode', () async {
      ApiHelper.client = MockClient((_) async => throw http.ClientException('x'));
      final r = await datasource.setStatus('kopi-kita', SiteStatus.published);
      r.fold((f) => expect(f.statusCode, isNull), (_) => fail('harus Left'));
    });
  });

  group('SiteStatusResponseModel', () {
    test('objek situs langsung (tanpa pembungkus) tetap terbaca', () {
      final m = SiteStatusResponseModel.fromJson(jsonEncode(_summary()));
      expect(m.status, SiteStatus.published);
      expect(m.tenant?.name, 'Kopi Kita');
    });

    test('pembungkus tenant', () {
      final m = SiteStatusResponseModel.fromJson(jsonEncode({'tenant': _summary(status: 'draft')}));
      expect(m.status, SiteStatus.draft);
    });

    test('tanpa status/situs -> unknown dan tenant null', () {
      final m = SiteStatusResponseModel.fromJson('{"ok": true}');
      expect(m.status, SiteStatus.unknown);
      expect(m.tenant, isNull);
    });

    test('bukan objek -> FormatException', () {
      expect(() => SiteStatusResponseModel.fromJson('[]'), throwsFormatException);
    });

    test('toJson bisa dibaca ulang', () {
      final m = SiteStatusResponseModel.fromJson(jsonEncode({'data': _summary()}));
      final again = SiteStatusResponseModel.fromJson(m.toJson());
      expect(again.status, SiteStatus.published);
      expect(again.tenant?.slug, 'kopi-kita');
    });
  });
}
