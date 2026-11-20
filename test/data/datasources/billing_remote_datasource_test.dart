import 'dart:convert';

import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/datasources/billing_remote_datasource.dart';
import 'package:compro_builder/data/model/response/billing_response_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _order({String state = 'choose'}) => {
  'id': 7,
  'number': 'CB-1',
  'status': 'pending',
  'state': state,
  'months': 12,
  'amount': 490000,
  'plan': {'code': 'medium', 'name': 'Medium', 'level': 2},
  'method': null,
  'method_label': null,
  'details': null,
  'expires_at': null,
  'timed_out': false,
  'paid_at': null,
  'created_at': null,
  'web_pay_url': 'https://x/pay/7',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final datasource = BillingRemoteDatasource();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
    ApiHelper.sessionExpired.value = 0;
  });

  tearDown(() => ApiHelper.client = http.Client());

  test('overview: GET /{slug}/manage/billing dengan Bearer', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({
          'data': {
            'current': {'code': 'standar', 'name': 'Standar', 'level': 1},
            'email_verified': true,
            'in_app_payment': true,
            'methods': [],
            'periods': [],
            'plans': [],
          },
        }),
        200,
      );
    });

    final r = await datasource.overview('kopi kita');
    final m = r.getOrElse(() => throw StateError('harus Right'));

    expect(captured.method, 'GET');
    expect(captured.url.path, endsWith('/kopi%20kita/manage/billing'));
    expect(captured.headers['Authorization'], 'Bearer tok');
    expect(m.current.code, 'standar');
    expect(m.inAppPayment, isTrue);
  });

  test('checkout: POST {plan, months}, 201 -> order', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(jsonEncode({'data': _order()}), 201);
    });

    final r = await datasource.checkout('toko', plan: 'medium', months: 12);
    final o = r.getOrElse(() => throw StateError('harus Right'));

    expect(captured.method, 'POST');
    expect(captured.url.path, endsWith('/toko/manage/billing/checkout'));
    expect(jsonDecode(captured.body), {'plan': 'medium', 'months': 12});
    expect(o.id, 7);
    expect(o.step, BillingOrderStep.choose);
  });

  test('checkout 403 email_unverified -> isEmailUnverified + pesan server', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(
        jsonEncode({'message': 'Verifikasi email dulu.', 'code': 'email_unverified'}),
        403,
      ),
    );
    final f = (await datasource.checkout('toko', plan: 'medium', months: 1))
        .fold((l) => l, (_) => null);
    expect(f?.isForbidden, isTrue);
    expect(f?.isEmailUnverified, isTrue);
    expect(f?.code, 'email_unverified');
    expect(f?.message, 'Verifikasi email dulu.');
  });

  test('403 tanpa code bukan email_unverified', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(jsonEncode({'message': 'Tidak boleh.'}), 403),
    );
    final f = (await datasource.checkout('toko', plan: 'medium', months: 1))
        .fold((l) => l, (_) => null);
    expect(f?.isEmailUnverified, isFalse);
    expect(f?.code, isNull);
  });

  test('checkout 422 pada plan -> pesan galat field', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'message': 'x',
          'errors': {
            'plan': ['Paket ini tidak bisa dibeli untuk situsmu.'],
          },
        }),
        422,
      ),
    );
    final f = (await datasource.checkout('toko', plan: 'standar', months: 1))
        .fold((l) => l, (_) => null);
    expect(f?.isValidation, isTrue);
    expect(f?.errorFor('plan'), 'Paket ini tidak bisa dibeli untuk situsmu.');
    expect(f?.message, 'Paket ini tidak bisa dibeli untuk situsmu.');
  });

  test('charge: POST /orders/{id}/charge {method} -> state instructions', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      final o = _order(state: 'instructions')
        ..['method'] = 'bca_va'
        ..['method_label'] = 'BCA Virtual Account'
        ..['details'] = {'type': 'va', 'bank': 'BCA', 'number': '123'}
        ..['expires_at'] = '2026-11-10T03:00:00+00:00';
      return http.Response(jsonEncode({'data': o}), 200);
    });

    final r = await datasource.charge('toko', 7, 'bca_va');
    final o = r.getOrElse(() => throw StateError('harus Right'));

    expect(captured.method, 'POST');
    expect(captured.url.path, endsWith('/toko/manage/billing/orders/7/charge'));
    expect(jsonDecode(captured.body), {'method': 'bca_va'});
    expect(o.step, BillingOrderStep.instructions);
    expect(o.details?.type, BillingDetailsType.va);
    expect(o.expiresAt, isNotNull);
  });

  test('charge 422 pada method', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'message': 'x',
          'errors': {
            'method': ['Metode pembayaran tidak tersedia.'],
          },
        }),
        422,
      ),
    );
    final f = (await datasource.charge('toko', 7, 'xx')).fold((l) => l, (_) => null);
    expect(f?.errorFor('method'), 'Metode pembayaran tidak tersedia.');
  });

  test('status: GET /orders/{id}/status lunas membawa tenant', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({
          'data': {
            'status': 'paid',
            'paid': true,
            'expired': false,
            'state': 'paid',
            'tenant': {'id': 1, 'name': 'K', 'slug': 'toko'},
          },
        }),
        200,
      );
    });

    final r = await datasource.status('toko', 7);
    final s = r.getOrElse(() => throw StateError('harus Right'));

    expect(captured.method, 'GET');
    expect(captured.url.path, endsWith('/toko/manage/billing/orders/7/status'));
    expect(s.paid, isTrue);
    expect(s.tenant?.slug, 'toko');
  });

  test('status 429 -> rate limited dengan retryAfter', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response('{}', 429, headers: {'retry-after': '12'}),
    );
    final f = (await datasource.status('toko', 7)).fold((l) => l, (_) => null);
    expect(f?.isRateLimited, isTrue);
    expect(f?.retryAfter, 12);
  });

  test('orders: query page & per_page, membaca meta', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({
          'data': [_order()],
          'meta': {'page': 2, 'last_page': 3, 'total': 41},
        }),
        200,
      );
    });

    final r = await datasource.orders('toko', page: 2, perPage: 20);
    final p = r.getOrElse(() => throw StateError('harus Right'));

    expect(captured.url.path, endsWith('/toko/manage/billing/orders'));
    expect(captured.url.queryParameters, {'page': '2', 'per_page': '20'});
    expect(p.page, 2);
    expect(p.hasMore, isTrue);
    expect(p.orders.single.id, 7);
  });

  test('401 -> sessionExpired naik', () async {
    ApiHelper.client = MockClient((_) async => http.Response('{}', 401));
    await datasource.overview('toko');
    expect(ApiHelper.sessionExpired.value, 1);
  });

  test('galat 500 memakai pesan cadangan Indonesia', () async {
    ApiHelper.client = MockClient((_) async => http.Response('boom', 500));
    final r = await datasource.overview('toko');
    expect(r.fold((l) => l.message, (_) => ''), 'Gagal memuat data tagihan.');
  });

  test('balasan 200 tidak valid -> pesan format, bukan exception', () async {
    ApiHelper.client = MockClient((_) async => http.Response('[]', 200));
    final r = await datasource.overview('toko');
    expect(r.isLeft(), isTrue);
  });
}
