import 'dart:convert';
import 'dart:io';

import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/datasources/sites_remote_datasource.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, int status, {Map<String, String>? headers}) =>
    http.Response(jsonEncode(body), status, headers: {
      'content-type': 'application/json',
      ...?headers,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => ApiHelper.client = http.Client());

  group('SitesRemoteDatasource.tenants', () {
    test('200 -> Right, memetakan tenantSummary dari backend', () async {
      ApiHelper.client = MockClient((req) async {
        expect(req.method, 'GET');
        expect(req.url.path, '/api/me/tenants');
        expect(req.headers['Accept'], 'application/json');
        return _json({
          'data': [
            {
              'id': 3,
              'name': 'Kopi Senja',
              'slug': 'kopi-senja',
              'status': 'published',
              'url': 'https://x.test/kopi-senja',
              'plan': {
                'code': 'standar',
                'name': 'Standar',
                'level': 1,
                'expires_at': '2026-12-01T00:00:00+00:00',
              },
              'unread_messages': 4,
            },
            // tanpa slug: dilewati, tidak menggagalkan seluruh daftar
            {'id': 4, 'name': 'Rusak'},
          ],
        }, 200);
      });

      final result = await SitesRemoteDatasource().tenants();
      final list = result.getOrElse(() => throw StateError('harus Right')).data;

      expect(list, hasLength(1));
      final t = list.single;
      expect(t.id, 3);
      expect(t.slug, 'kopi-senja');
      expect(t.status, SiteStatus.published);
      expect(t.url, 'https://x.test/kopi-senja');
      expect(t.plan?.code, 'standar');
      expect(t.plan?.level, 1);
      expect(t.plan?.expiresAt, isNotNull);
      expect(t.unreadMessages, 4);
    });

    test('unread_messages null tetap null (bukan 0)', () async {
      ApiHelper.client = MockClient((_) async => _json({
            'data': [
              {
                'id': 1,
                'name': 'A',
                'slug': 'a',
                'status': 'draft',
                'plan': {'code': 'standar', 'name': 'Standar', 'level': 1},
                'unread_messages': null,
              }
            ]
          }, 200));
      final list = (await SitesRemoteDatasource().tenants())
          .getOrElse(() => throw StateError('harus Right'))
          .data;
      expect(list.single.unreadMessages, isNull);
      expect(list.single.status, SiteStatus.draft);
    });

    test('daftar kosong -> Right([])', () async {
      ApiHelper.client = MockClient((_) async => _json({'data': []}, 200));
      final list = (await SitesRemoteDatasource().tenants())
          .getOrElse(() => throw StateError('harus Right'))
          .data;
      expect(list, isEmpty);
    });

    test('401 -> Left isUnauthorized dan sessionExpired naik', () async {
      final before = ApiHelper.sessionExpired.value;
      ApiHelper.client = MockClient((_) async => _json({'message': 'x'}, 401));
      final result = await SitesRemoteDatasource().tenants();
      result.fold(
        (f) => expect(f.isUnauthorized, isTrue),
        (_) => fail('harus Left'),
      );
      expect(ApiHelper.sessionExpired.value, before + 1);
    });

    test('403 -> pesan server dipakai', () async {
      ApiHelper.client = MockClient(
          (_) async => _json({'message': 'Situs ini dinonaktifkan.'}, 403));
      (await SitesRemoteDatasource().tenants()).fold(
        (f) {
          expect(f.isForbidden, isTrue);
          expect(f.message, 'Situs ini dinonaktifkan.');
        },
        (_) => fail('harus Left'),
      );
    });

    test('429 -> retryAfter terbaca', () async {
      ApiHelper.client = MockClient((_) async =>
          _json({}, 429, headers: {'retry-after': '12'}));
      (await SitesRemoteDatasource().tenants()).fold(
        (f) {
          expect(f.isRateLimited, isTrue);
          expect(f.retryAfter, 12);
        },
        (_) => fail('harus Left'),
      );
    });

    test('500 -> pesan fallback Indonesia, statusCode terisi', () async {
      ApiHelper.client =
          MockClient((_) async => http.Response('Server Error', 500));
      (await SitesRemoteDatasource().tenants()).fold(
        (f) {
          expect(f.statusCode, 500);
          expect(f.message, 'Gagal memuat daftar situs.');
        },
        (_) => fail('harus Left'),
      );
    });

    test('jaringan putus -> Left tanpa statusCode', () async {
      ApiHelper.client =
          MockClient((_) async => throw const SocketException('offline'));
      (await SitesRemoteDatasource().tenants()).fold(
        (f) {
          expect(f.statusCode, isNull);
          expect(f.message, contains('Tidak dapat terhubung'));
        },
        (_) => fail('harus Left'),
      );
    });

    test('body bukan JSON -> Left format tidak sesuai', () async {
      ApiHelper.client = MockClient((_) async => http.Response('<html>', 200));
      (await SitesRemoteDatasource().tenants()).fold(
        (f) => expect(f.message, 'Format data dari server tidak sesuai.'),
        (_) => fail('harus Left'),
      );
    });
  });

  group('TenantModel', () {
    test('cache lama: plan string + unread_count tetap terbaca', () {
      final t = TenantModel.fromMap({
        'id': 1,
        'name': 'Lama',
        'slug': 'lama',
        'plan': 'Standar',
        'status': 'published',
        'unread_count': 2,
      });
      expect(t.plan?.name, 'Standar');
      expect(t.unreadMessages, 2);
    });

    test('nama kosong -> memakai slug', () {
      expect(TenantModel.fromMap({'slug': 'abc'}).name, 'abc');
    });

    test('toMap -> fromMap bolak-balik', () {
      final src = TenantModel(
        id: 5,
        name: 'N',
        slug: 'n',
        status: SiteStatus.draft,
        url: 'https://x.test/n',
        plan: PlanSummaryModel(code: 'pro', name: 'Pro', level: 3),
        unreadMessages: 1,
      );
      final back = TenantModel.fromJson(src.toJson());
      expect(back.id, 5);
      expect(back.status, SiteStatus.draft);
      expect(back.plan?.code, 'pro');
      expect(back.unreadMessages, 1);
    });
  });
}
