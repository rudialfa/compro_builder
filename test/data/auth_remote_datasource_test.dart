import 'dart:convert';

import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/datasources/auth_local_datasource.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/data/model/request/login_request_model.dart';
import 'package:compro_builder/data/model/request/register_request_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(int status, Object body, {Map<String, String>? headers}) =>
    http.Response(jsonEncode(body), status, headers: {
      'content-type': 'application/json',
      ...?headers,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final remote = AuthRemoteDatasource();
  final local = AuthLocalDatasource();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiHelper.sessionExpired.value = 0;
  });

  group('login', () {
    test('200 -> Right(AuthResponseModel) dan tanpa header Authorization',
        () async {
      late http.Request sent;
      ApiHelper.client = MockClient((req) async {
        sent = req;
        return _json(200, {
          'user': {'id': 1, 'name': 'Demo', 'email': 'demo@test.com'},
          'token': '1|tok',
        });
      });

      final result = await remote
          .login(LoginRequestModel(email: 'demo@test.com', password: 'password'));

      final data = result.getOrElse(() => throw StateError('harus Right'));
      expect(data.token, '1|tok');
      expect(sent.url.path, '/api/auth/login');
      expect(sent.headers['Accept'], 'application/json');
      expect(sent.headers.containsKey('Authorization'), isFalse);
      expect(jsonDecode(sent.body)['device_name'], 'mobile');
    });

    test('422 -> Left dengan fieldErrors per field', () async {
      ApiHelper.client = MockClient((_) async => _json(422, {
            'message': 'The given data was invalid.',
            'errors': {
              'email': ['Email atau password salah.'],
            },
          }));

      final result = await remote
          .login(LoginRequestModel(email: 'x@y.com', password: 'salah'));

      final failure = result.fold((l) => l, (_) => throw StateError('harus Left'));
      expect(failure.isValidation, isTrue);
      expect(failure.errorFor('email'), 'Email atau password salah.');
      expect(failure.errorFor('password'), isNull);
      expect(failure.message, 'Email atau password salah.');
    });

    test('429 -> Left isRateLimited dengan retryAfter dari header', () async {
      ApiHelper.client = MockClient((_) async => _json(
            429,
            {'message': 'Too Many Attempts.'},
            headers: {'retry-after': '30'},
          ));

      final result = await remote
          .login(LoginRequestModel(email: 'x@y.com', password: 'p'));

      final failure = result.fold((l) => l, (_) => throw StateError('harus Left'));
      expect(failure.isRateLimited, isTrue);
      expect(failure.retryAfter, 30);
      expect(failure.message, contains('Terlalu banyak'));
    });

    test('galat jaringan -> Left berpesan Indonesia, bukan exception',
        () async {
      ApiHelper.client =
          MockClient((_) async => throw http.ClientException('putus'));

      final result = await remote
          .login(LoginRequestModel(email: 'x@y.com', password: 'p'));

      final failure = result.fold((l) => l, (_) => throw StateError('harus Left'));
      expect(failure.message, contains('Tidak dapat terhubung'));
    });
  });

  group('register', () {
    test('201 -> Right dan mengirim password_confirmation', () async {
      late http.Request sent;
      ApiHelper.client = MockClient((req) async {
        sent = req;
        return _json(201, {
          'user': {'id': 2, 'name': 'Baru', 'email': 'baru@test.com'},
          'token': '2|tok',
        });
      });

      final result = await remote.register(RegisterRequestModel(
        name: 'Baru',
        email: 'baru@test.com',
        password: 'password1',
        passwordConfirmation: 'password1',
      ));

      expect(result.isRight(), isTrue);
      expect(sent.url.path, '/api/auth/register');
      expect(jsonDecode(sent.body)['password_confirmation'], 'password1');
    });
  });

  group('me', () {
    test('mengirim Bearer token dan mem-parse user', () async {
      await local.saveToken('1|tok');
      late http.Request sent;
      ApiHelper.client = MockClient((req) async {
        sent = req;
        return _json(200, {'id': 1, 'name': 'Demo', 'email': 'demo@test.com'});
      });

      final result = await remote.me();

      expect(result.isRight(), isTrue);
      expect(sent.headers['Authorization'], 'Bearer 1|tok');
    });

    test('401 -> token dihapus dan sessionExpired naik', () async {
      await local.saveToken('1|kadaluarsa');
      ApiHelper.client = MockClient(
          (_) async => _json(401, {'message': 'Unauthenticated.'}));

      final result = await remote.me();

      final failure = result.fold((l) => l, (_) => throw StateError('harus Left'));
      expect(failure.isUnauthorized, isTrue);
      expect(await local.getToken(), isNull);
      expect(ApiHelper.sessionExpired.value, 1);
    });
  });

  group('logout', () {
    test('204 -> Right', () async {
      await local.saveToken('1|tok');
      ApiHelper.client = MockClient((_) async => http.Response('', 204));

      final result = await remote.logout();

      expect(result.isRight(), isTrue);
    });

    test('401 dianggap sukses dan tidak memicu sessionExpired', () async {
      await local.saveToken('1|tok');
      ApiHelper.client = MockClient(
          (_) async => _json(401, {'message': 'Unauthenticated.'}));

      final result = await remote.logout();

      expect(result.isRight(), isTrue);
      expect(ApiHelper.sessionExpired.value, 0);
    });
  });
}
