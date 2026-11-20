import 'package:compro_builder/data/model/response/account_message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dev_verify_url dibaca bila ada', () {
    final m = AccountMessageModel.fromJson(
      '{"message":"ok","verified":false,"dev_verify_url":"https://x.test/email/verify-link/1/a?signature=s"}',
    );
    expect(m.devVerifyUrl, 'https://x.test/email/verify-link/1/a?signature=s');
  });

  test('tanpa dev_verify_url -> null', () {
    final m = AccountMessageModel.fromJson('{"message":"ok","verified":false}');
    expect(m.devVerifyUrl, isNull);
  });
}
