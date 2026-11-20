import 'package:compro_builder/core/utils/reset_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _deepLinkTests();
  test('tautan utuh: token dari path, email dari query', () {
    final r = parseResetInput(
      'https://platform.com/reset-password/abc123def?email=a%40b.com',
    );
    expect(r.token, 'abc123def');
    expect(r.email, 'a@b.com');
  });

  test('tautan dengan spasi di sekitar dan http', () {
    final r = parseResetInput('  http://localhost:8000/reset-password/tok42?email=x@y.id \n');
    expect(r.token, 'tok42');
    expect(r.email, 'x@y.id');
  });

  test('tautan tanpa email -> email null', () {
    final r = parseResetInput('https://platform.com/reset-password/tok');
    expect(r.token, 'tok');
    expect(r.email, isNull);
  });

  test('hanya token -> seluruh isian menjadi token', () {
    final r = parseResetInput('  0123456789abcdef  ');
    expect(r.token, '0123456789abcdef');
    expect(r.email, isNull);
  });

  test('tautan tanpa segmen reset-password -> isian utuh dianggap token', () {
    final r = parseResetInput('https://platform.com/login');
    expect(r.token, 'https://platform.com/login');
    expect(r.email, isNull);
  });

  test('skema selain http/https tidak dikenali sebagai tautan', () {
    final r = parseResetInput('javascript:/reset-password/x?email=a@b.c');
    expect(r.token, 'javascript:/reset-password/x?email=a@b.c');
    expect(r.email, isNull);
  });

  test('kosong -> token kosong', () {
    expect(parseResetInput('   ').token, isEmpty);
  });
}

void _deepLinkTests() {
  group('parseResetUri', () {
    test('tautan web https membawa token dan email', () {
      final r = parseResetUri(
        Uri.parse('https://situs.id/reset-password/abc123?email=a%40b.com'),
      );
      expect(r?.token, 'abc123');
      expect(r?.email, 'a@b.com');
    });

    test('skema aplikasi comprobuilder://', () {
      final r = parseResetUri(
        Uri.parse('comprobuilder://reset-password/tok9?email=x@y.id'),
      );
      expect(r?.token, 'tok9');
      expect(r?.email, 'x@y.id');
    });

    test('tanpa email -> email null', () {
      final r = parseResetUri(Uri.parse('https://situs.id/reset-password/tok'));
      expect(r?.token, 'tok');
      expect(r?.email, isNull);
    });

    test('bukan tautan atur ulang -> null', () {
      expect(parseResetUri(Uri.parse('https://situs.id/kopi-kita')), isNull);
      expect(parseResetUri(Uri.parse('https://situs.id/reset-password')), isNull);
      expect(parseResetUri(Uri.parse('comprobuilder://home')), isNull);
    });
  });
}
