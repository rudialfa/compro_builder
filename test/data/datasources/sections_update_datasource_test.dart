import 'dart:convert';
import 'dart:typed_data';

import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/datasources/sections_remote_datasource.dart';
import 'package:compro_builder/data/model/request/section_payload.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _section({String name = 'Tentang'}) => jsonEncode({
  'data': {
    'id': 1,
    'type': 'about',
    'name': name,
    'order': 1,
    'enabled': true,
    'content': {'title': 'Halo'},
    'fields': [
      {'key': 'title', 'label': 'Judul', 'type': 'text'},
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

  test('detail membaca {data: section}', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response(_section(), 200);
    });
    final result = await datasource.detail('toko', 1);
    expect(captured.url.path, endsWith('/toko/manage/sections/1'));
    expect(result.getOrElse(() => throw StateError('Left')).name, 'Tentang');
  });

  test('detail 403 (section terkunci) membawa pesan server', () async {
    ApiHelper.client = MockClient(
      (_) async => http.Response(
        jsonEncode({'message': 'Section ini terkunci di paketmu.'}),
        403,
      ),
    );
    final result = await datasource.detail('toko', 1);
    result.fold((f) {
      expect(f.isForbidden, isTrue);
      expect(f.message, 'Section ini terkunci di paketmu.');
    }, (_) => fail('harus Left'));
  });

  group('update', () {
    test('tanpa gambar baru: PUT JSON', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response(_section(name: 'Baru'), 200);
      });
      final result = await datasource.update('toko', 1, {
        'title': 'Halo',
        'active': true,
        'photo_remove': 1,
      });
      expect(captured.method, 'PUT');
      expect(captured.headers['content-type'], contains('application/json'));
      expect(jsonDecode(captured.body), {
        'title': 'Halo',
        'active': true,
        'photo_remove': 1,
      });
      expect(result.getOrElse(() => throw StateError('Left')).name, 'Baru');
    });

    test('dengan gambar baru: POST multipart dengan kunci ala PHP', () async {
      late http.Request captured;
      ApiHelper.client = MockClient((req) async {
        captured = req;
        return http.Response(_section(), 200);
      });
      final result = await datasource.update('toko', 1, {
        'title': 'Halo',
        'items': [
          {
            'name': 'A',
            'img': UploadFile(Uint8List.fromList([1, 2, 3]), 'image.jpg'),
          },
        ],
      });
      expect(captured.method, 'POST');
      expect(
        captured.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      expect(captured.headers['Authorization'], 'Bearer tok');
      expect(captured.body, contains('name="title"'));
      expect(captured.body, contains('name="items[0][name]"'));
      expect(captured.body, contains('name="items[0][img]"'));
      expect(captured.body, contains('filename="image.jpg"'));
      expect(result.isRight(), isTrue);
    });

    test('422 membawa fieldErrors berkunci notasi titik', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'x',
            'errors': {
              'items.0.name': ['Nama wajib diisi.'],
            },
          }),
          422,
        ),
      );
      final result = await datasource.update('toko', 1, {'title': ''});
      result.fold((f) {
        expect(f.isValidation, isTrue);
        expect(f.errorFor('items.0.name'), 'Nama wajib diisi.');
      }, (_) => fail('harus Left'));
    });

    test('429 membawa retryAfter', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response('{}', 429, headers: {'retry-after': '30'}),
      );
      final result = await datasource.update('toko', 1, {'title': 'x'});
      result.fold((f) => expect(f.retryAfter, 30), (_) => fail('harus Left'));
    });
  });

  test('downloadBytes memakai request tanpa Authorization', () async {
    late http.Request captured;
    ApiHelper.client = MockClient((req) async {
      captured = req;
      return http.Response.bytes([1, 2, 3], 200);
    });
    final result = await datasource.downloadBytes('https://x.test/a.jpg');
    expect(captured.headers.containsKey('Authorization'), isFalse);
    expect(result.getOrElse(() => throw StateError('Left')), [1, 2, 3]);
  });

  test('flattenPayload: bool -> 1/0, null dilewati, file dipisah', () {
    final flat = flattenPayload({
      'a': true,
      'b': false,
      'c': null,
      'd': [
        {'e': 'x', 'f': UploadFile(Uint8List(1), 'image.jpg')},
      ],
    });
    expect(flat.fields.map((e) => '${e.key}=${e.value}'), [
      'a=1',
      'b=0',
      'd[0][e]=x',
    ]);
    expect(flat.files.single.key, 'd[0][f]');
  });
}
