import 'package:compro_builder/core/utils/verify_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('skema app dikenali', () {
    expect(isEmailVerifiedUri(Uri.parse('comprobuilder://email-verified')), isTrue);
  });

  test('https dengan segmen email-verified dikenali', () {
    expect(isEmailVerifiedUri(Uri.parse('https://platform.com/email-verified')), isTrue);
  });

  test('tautan lain tidak dikenali', () {
    expect(isEmailVerifiedUri(Uri.parse('comprobuilder://reset-password/abc?email=a@b.com')), isFalse);
    expect(isEmailVerifiedUri(Uri.parse('https://platform.com/email/verify-link/1/abc')), isFalse);
  });

  group('isVerifyLinkUri', () {
    test('tautan email verifikasi dikenali', () {
      expect(
        isVerifyLinkUri(Uri.parse(
          'https://platform.com/email/verify-link/7/abc123?expires=1&signature=xyz',
        )),
        isTrue,
      );
    });

    test('tanpa signature, bukan https, atau jalur lain ditolak', () {
      expect(isVerifyLinkUri(Uri.parse('https://platform.com/email/verify-link/7/abc')), isFalse);
      expect(isVerifyLinkUri(Uri.parse('comprobuilder://email/verify-link/7/abc?signature=x')), isFalse);
      expect(isVerifyLinkUri(Uri.parse('https://platform.com/reset-password/tok?signature=x')), isFalse);
    });
  });
}
