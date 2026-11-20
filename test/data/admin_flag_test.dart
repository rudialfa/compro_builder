import 'package:compro_builder/data/model/response/auth_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('is_admin dibaca dari respons user', () {
    expect(UserModel.fromMap({'id': 1, 'name': 'A', 'email': 'a@x.id', 'is_admin': true}).isAdmin, isTrue);
    expect(UserModel.fromMap({'id': 1, 'name': 'A', 'email': 'a@x.id', 'is_admin': 1}).isAdmin, isTrue);
    expect(UserModel.fromMap({'id': 2, 'name': 'B', 'email': 'b@x.id'}).isAdmin, isFalse);
    expect(UserModel.fromMap({'id': 2, 'name': 'B', 'email': 'b@x.id', 'is_admin': false}).isAdmin, isFalse);
  });
}
