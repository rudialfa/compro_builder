import 'package:compro_builder/data/model/response/auth_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthResponseModel', () {
    test('mem-parse respons login {user, token}', () {
      const body = '''
      {
        "user": {
          "id": 7,
          "name": "Demo",
          "email": "demo@test.com",
          "email_verified_at": "2026-01-02T03:04:05.000000Z",
          "created_at": "2026-01-01T00:00:00.000000Z"
        },
        "token": "1|abcdef"
      }''';

      final model = AuthResponseModel.fromJson(body);

      expect(model.token, '1|abcdef');
      expect(model.user.id, 7);
      expect(model.user.name, 'Demo');
      expect(model.user.email, 'demo@test.com');
      expect(model.user.isEmailVerified, isTrue);
    });

    test('email belum diverifikasi bila email_verified_at null', () {
      const body =
          '{"user":{"id":1,"name":"A","email":"a@b.c","email_verified_at":null},"token":"t"}';

      final model = AuthResponseModel.fromJson(body);

      expect(model.user.isEmailVerified, isFalse);
    });

    test('aman bila field user/token hilang', () {
      final model = AuthResponseModel.fromJson('{}');

      expect(model.token, isEmpty);
      expect(model.user.name, isEmpty);
    });
  });

  group('UserModel', () {
    test('GET /auth/me mengembalikan objek user langsung', () {
      final user = UserModel.fromJson(
          '{"id":3,"name":"Budi","email":"budi@test.com","email_verified_at":null}');

      expect(user.id, 3);
      expect(user.name, 'Budi');
      expect(user.isEmailVerified, isFalse);
    });
  });
}
