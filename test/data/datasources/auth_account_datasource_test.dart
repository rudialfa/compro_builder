import 'dart:convert';

import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/data/model/request/reset_password_request_model.dart';
import 'package:compro_builder/data/model/response/account_message_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final remote = AuthRemoteDatasource();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
    ApiHelper.sessionExpired.value = 0;
  });

  tearDown(() => ApiHelper.client = http.Client());

  group('AccountMessageModel', () {
    test('message + verified', () {
      final m = AccountMessageModel.fromJson(
        jsonEncode({'message': ' Terkirim. ', 'verified': false}),
      );
      expect(m.message, 'Terkirim.');
      expect(m.verified, isFalse);
    });

    test('tanpa verified -> null; tanpa message -> kosong', () {
      final m = AccountMessageModel.fromJson('{}');
      expect(m.message, '');
      expect(m.verified, isNull);
    });

    test('bukan objek -> FormatException', () {
      expect(() => AccountMessageModel.fromJson('[]'), throwsFormatException);
    });
  });

  group('forgotPassword', () {
    test('POST /auth/forgot-password {email}, tanpa Authorization', () async {
      late http.Request sent;
      ApiHelper.client = MockClient((req) async {
        sent = req;
        return http.Response(jsonEncode({'message': 'Cek email.'}), 200);
      });

      final r = await remote.forgotPassword('a@b.com');
      final m = r.getOrElse(() => throw StateError('harus Right'));

      expect(sent.method, 'POST');
      expect(sent.url.path, '/api/auth/forgot-password');
      expect(jsonDecode(sent.body), {'email': 'a@b.com'});
      expect(sent.headers.containsKey('Authorization'), isFalse);
      expect(m.message, 'Cek email.');
    });

    test('422 email tidak valid -> galat field', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'x',
            'errors': {
              'email': ['Format email salah.'],
            },
          }),
          422,
        ),
      );
      final f = (await remote.forgotPassword('x')).fold((l) => l, (_) => null);
      expect(f?.errorFor('email'), 'Format email salah.');
    });

    test('429 -> rate limited dan 401 tidak memicu sessionExpired', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response('{}', 429, headers: {'retry-after': '40'}),
      );
      final f = (await remote.forgotPassword('a@b.com')).fold((l) => l, (_) => null);
      expect(f?.isRateLimited, isTrue);
      expect(f?.retryAfter, 40);

      ApiHelper.client = MockClient((_) async => http.Response('{}', 401));
      await remote.forgotPassword('a@b.com');
      expect(ApiHelper.sessionExpired.value, 0);
    });
  });

  group('resetPassword', () {
    const request = ResetPasswordRequestModel(
      token: 'tok123',
      email: 'a@b.com',
      password: 'password-baru',
      passwordConfirmation: 'password-baru',
    );

    test('POST /auth/reset-password dengan 4 field kontrak', () async {
      late http.Request sent;
      ApiHelper.client = MockClient((req) async {
        sent = req;
        return http.Response(
          jsonEncode({'message': 'Password berhasil diganti. Silakan masuk.'}),
          200,
        );
      });

      final r = await remote.resetPassword(request);
      final m = r.getOrElse(() => throw StateError('harus Right'));

      expect(sent.url.path, '/api/auth/reset-password');
      expect(jsonDecode(sent.body), {
        'token': 'tok123',
        'email': 'a@b.com',
        'password': 'password-baru',
        'password_confirmation': 'password-baru',
      });
      expect(sent.headers.containsKey('Authorization'), isFalse);
      expect(m.message, contains('berhasil'));
    });

    test('422 token salah: pesan server pada kunci email', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'Tautan tidak valid atau sudah kedaluwarsa. Minta tautan baru.',
            'errors': {
              'email': ['Tautan tidak valid atau sudah kedaluwarsa. Minta tautan baru.'],
            },
          }),
          422,
        ),
      );
      final f = (await remote.resetPassword(request)).fold((l) => l, (_) => null);
      expect(f?.isValidation, isTrue);
      expect(
        f?.errorFor('email'),
        'Tautan tidak valid atau sudah kedaluwarsa. Minta tautan baru.',
      );
    });
  });

  group('resendVerification', () {
    test('POST /auth/email/verification-notification dengan Bearer', () async {
      late http.Request sent;
      ApiHelper.client = MockClient((req) async {
        sent = req;
        return http.Response(
          jsonEncode({'message': 'Tautan baru terkirim.', 'verified': false}),
          200,
        );
      });

      final r = await remote.resendVerification();
      final m = r.getOrElse(() => throw StateError('harus Right'));

      expect(sent.method, 'POST');
      expect(sent.url.path, '/api/auth/email/verification-notification');
      expect(sent.headers['Authorization'], 'Bearer tok');
      expect(m.verified, isFalse);
    });

    test('sudah terverifikasi -> verified true', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Email sudah terverifikasi.', 'verified': true}),
          200,
        ),
      );
      final m = (await remote.resendVerification()).getOrElse(
        () => throw StateError('harus Right'),
      );
      expect(m.verified, isTrue);
    });

    test('503 memakai pesan cadangan Indonesia', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Email belum bisa dikirim. Coba lagi sebentar lagi.'}),
          503,
        ),
      );
      final f = (await remote.resendVerification()).fold((l) => l, (_) => null);
      expect(f?.statusCode, 503);
      expect(f?.message, 'Email belum bisa dikirim. Coba lagi sebentar lagi.');
    });

    test('429 -> rate limited dengan retryAfter', () async {
      ApiHelper.client = MockClient(
        (_) async => http.Response('{}', 429, headers: {'retry-after': '25'}),
      );
      final f = (await remote.resendVerification()).fold((l) => l, (_) => null);
      expect(f?.isRateLimited, isTrue);
      expect(f?.retryAfter, 25);
    });

    test('401 -> sessionExpired naik', () async {
      ApiHelper.client = MockClient((_) async => http.Response('{}', 401));
      await remote.resendVerification();
      expect(ApiHelper.sessionExpired.value, 1);
    });
  });
}
