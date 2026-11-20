import 'dart:convert';

import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/datasources/sections_remote_datasource.dart';
import 'package:compro_builder/data/model/response/section_model.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _section(int id, {bool enabled = true, int order = 1}) => {
  'id': id,
  'type': 'about',
  'name': 'Tentang',
  'order': order,
  'enabled': enabled,
  'is_sample': false,
  'locked': false,
  'content': {'title': 'Halo'},
  'fields': [
    {
      'key': 'title',
      'label': 'Judul',
      'type': 'text',
      'required': true,
      'max': 80,
    },
  ],
};

String _listBody() => jsonEncode({
  'data': {
    'sections': [_section(2, order: 2), _section(1, enabled: false, order: 1)],
    'usage': {'used': 2, 'limit': 5},
    'addable': [
      {'id': 7, 'code': 'faq', 'name': 'FAQ'},
    ],
    'locked': [
      {'code': 'map', 'name': 'Peta', 'min_level': 2},
    ],
  },
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final datasource = SectionsRemoteDatasource();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
    ApiHelper.sessionExpired.value = 0;
  });

  tearDown(() => ApiHelper.client = http.Client());

  group('list', () {
    test('membaca {data:{...}}, mengurutkan, membaca kunci enabled', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response(_listBody(), 200);
      });

      final result = await datasource.list('toko-saya');
      final data = result.getOrElse(() => throw StateError('Left'));

      expect(captured.url.path, endsWith('/toko-saya/manage/sections'));
      expect(captured.headers['Authorization'], 'Bearer tok');
      expect(data.sections.map((s) => s.id), [1, 2]);
      expect(data.sections.first.isEnabled, isFalse);
      expect(data.used, 2);
      expect(data.limit, 5);
      expect(data.addable.single.sectionTypeId, 7);
      expect(data.addable.single.type, 'faq');
      expect(data.locked.single.locked, isTrue);
      expect(data.sections.first.fields.single.required, isTrue);
    });

    test('round-trip toJson -> fromJson (cache offline)', () async {
      final data = SectionsDataModel.fromJson(_listBody());
      final again = SectionsDataModel.fromJson(data.toJson());
      expect(again.sections.map((s) => s.id), [1, 2]);
      expect(again.sections.first.isEnabled, isFalse);
      expect(again.limit, 5);
      expect(again.addable.single.sectionTypeId, 7);
      expect(again.locked.single.minLevel, 2);
    });

    test('401 -> Left + sessionExpired naik', () async {
      ApiHelper.client = MockClient((_) async => http.Response('{}', 401));
      final result = await datasource.list('x');
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f.statusCode, 401), (_) => fail('harus Left'));
      expect(ApiHelper.sessionExpired.value, 1);
    });

    test(
      '403 membawa pesan server (section terkunci / situs disuspend)',
      () async {
        ApiHelper.client = MockClient(
          (_) async =>
              http.Response(jsonEncode({'message': 'Situs disuspend.'}), 403),
        );
        final result = await datasource.list('x');
        result.fold((f) {
          expect(f.statusCode, 403);
          expect(f.message, 'Situs disuspend.');
        }, (_) => fail('harus Left'));
      },
    );

    test('jaringan putus -> Left tanpa statusCode', () async {
      ApiHelper.client = MockClient(
        (_) async => throw http.ClientException('x'),
      );
      final result = await datasource.list('x');
      result.fold(
        (f) => expect(f.statusCode, isNull),
        (_) => fail('harus Left'),
      );
    });

    test('JSON rusak -> Left format tidak sesuai', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response('bukan json', 200),
      );
      final result = await datasource.list('x');
      expect(result.isLeft(), isTrue);
    });
  });

  group('add', () {
    test('mengirim section_type_id bila ada, membaca 201', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode({'data': _section(9)}), 201);
      });
      final result = await datasource.add(
        'x',
        const SectionTypeModel(type: 'faq', name: 'FAQ', sectionTypeId: 7),
      );
      expect(jsonDecode(captured.body), {'section_type_id': 7});
      expect(result.getOrElse(() => throw StateError('Left')).id, 9);
    });

    test('tanpa id -> mengirim type', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode({'data': _section(9)}), 201);
      });
      await datasource.add(
        'x',
        const SectionTypeModel(type: 'faq', name: 'FAQ'),
      );
      expect(jsonDecode(captured.body), {'type': 'faq'});
    });

    test('422 membawa fieldErrors', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'x',
            'errors': {
              'type': ['Tipe tidak valid.'],
            },
          }),
          422,
        ),
      );
      final result = await datasource.add(
        'x',
        const SectionTypeModel(type: 'zzz', name: 'zzz'),
      );
      result.fold((f) {
        expect(f.isValidation, isTrue);
        expect(f.errorFor('type'), 'Tipe tidak valid.');
      }, (_) => fail('harus Left'));
    });
  });

  group('toggle / move / delete', () {
    test('toggle membaca {data: section}', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response(
          jsonEncode({'data': _section(3, enabled: false)}),
          200,
        );
      });
      final result = await datasource.toggle('x', 3);
      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/sections/3/toggle'));
      expect(
        result.getOrElse(() => throw StateError('Left')).isEnabled,
        isFalse,
      );
    });

    test('move mengirim direction dan membaca daftar lengkap', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response(_listBody(), 200);
      });
      final result = await datasource.move('x', 2, up: true);
      expect(jsonDecode(captured.body), {'direction': 'up'});
      expect(
        result.getOrElse(() => throw StateError('Left')).sections,
        hasLength(2),
      );
    });

    test('delete 204 -> Right(unit)', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response('', 204);
      });
      final result = await datasource.delete('x', 4);
      expect(captured.method, 'DELETE');
      expect(result, const Right<dynamic, Unit>(unit));
    });

    test('429 membawa retryAfter', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response('{}', 429, headers: {'retry-after': '12'}),
      );
      final result = await datasource.toggle('x', 1);
      result.fold((f) {
        expect(f.isRateLimited, isTrue);
        expect(f.retryAfter, 12);
      }, (_) => fail('harus Left'));
    });
  });
}
