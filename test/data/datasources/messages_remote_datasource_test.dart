import 'dart:convert';

import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/datasources/messages_remote_datasource.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _msg(int id, {bool read = false}) => {
  'id': id,
  'name': 'Budi',
  'email': 'budi@x.com',
  'phone': '0812',
  'message': 'Halo',
  'read': read,
  'created_at': '2026-11-07T07:00:00+00:00',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final datasource = MessagesRemoteDatasource();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
    ApiHelper.sessionExpired.value = 0;
  });

  tearDown(() => ApiHelper.client = http.Client());

  group('list', () {
    test(
      'membaca data + meta{page,last_page,total} dan mengirim query',
      () async {
        late http.Request captured;
        ApiHelper.client = MockClient((req) async {
          captured = req;
          return http.Response(
            jsonEncode({
              'data': [_msg(1), _msg(2, read: true)],
              'meta': {'page': 1, 'last_page': 2, 'total': 21},
            }),
            200,
          );
        });
        final page = (await datasource.list(
          'toko',
          page: 1,
          perPage: 20,
        )).getOrElse(() => throw StateError('Left'));
        expect(captured.url.queryParameters, {'page': '1', 'per_page': '20'});
        expect(captured.url.path, endsWith('/toko/manage/messages'));
        expect(page.items.map((m) => m.isRead), [false, true]);
        expect(page.total, 21);
        expect(page.hasMore, isTrue);
      },
    );

    test(
      'halaman terakhir yang penuh: hasMore false (bukan tebakan jumlah item)',
      () async {
        ApiHelper.client = MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': List.generate(20, (i) => _msg(i + 1)),
              'meta': {'page': 2, 'last_page': 2, 'total': 40},
            }),
            200,
          ),
        );
        final page = (await datasource.list(
          'toko',
          page: 2,
          perPage: 20,
        )).getOrElse(() => throw StateError('Left'));
        expect(page.hasMore, isFalse);
      },
    );

    test('403 paket tanpa form kontak -> isForbidden + pesan server', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Form kontak tersedia mulai paket Medium.'}),
          403,
        ),
      );
      final r = await datasource.list('toko', page: 1, perPage: 20);
      r.fold((f) {
        expect(f.isForbidden, isTrue);
        expect(f.message, 'Form kontak tersedia mulai paket Medium.');
      }, (_) => fail('harus Left'));
    });

    test('401 -> sessionExpired naik', () async {
      ApiHelper.client = MockClient((_) async => http.Response('{}', 401));
      await datasource.list('toko', page: 1, perPage: 20);
      expect(ApiHelper.sessionExpired.value, 1);
    });
  });

  group('toggleRead / delete', () {
    test('toggleRead membaca {data:{id,read}} (status BARU)', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response(
          jsonEncode({
            'data': {'id': 5, 'read': true},
          }),
          200,
        );
      });
      final r = await datasource.toggleRead('toko', 5);
      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/messages/5/read'));
      expect(r, const Right<dynamic, bool>(true));
    });

    test(
      'toggleRead dengan respons tak dikenal -> Left (bukan crash)',
      () async {
        ApiHelper.client = MockClient((_) async => http.Response('{}', 200));
        expect((await datasource.toggleRead('toko', 5)).isLeft(), isTrue);
      },
    );

    test('delete 204 -> Right(unit)', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response('', 204);
      });
      final r = await datasource.delete('toko', 5);
      expect(captured.method, 'DELETE');
      expect(r, const Right<dynamic, Unit>(unit));
    });

    test('delete 404 -> Left', () async {
      ApiHelper.client = MockClient((_) async => http.Response('{}', 404));
      final r = await datasource.delete('toko', 5);
      r.fold((f) => expect(f.statusCode, 404), (_) => fail('harus Left'));
    });
  });
}
