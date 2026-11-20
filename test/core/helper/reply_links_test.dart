import 'package:compro_builder/core/helper/reply_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nomor WhatsApp dinormalkan ke 62', () {
    expect(waNumber('0812-3456-789'), '628123456789');
    expect(waNumber('+62 812 3456 789'), '628123456789');
    expect(waNumber('8123456789'), '628123456789');
    expect(waNumber('123'), isNull);
    expect(waNumber(null), isNull);
  });

  test('URL wa.me, mailto, tel', () {
    expect(
      whatsappUri('0812345678', 'Halo A').toString(),
      'https://wa.me/62812345678?text=Halo%20A',
    );
    expect(emailUri('a@b.co', 'Re: x')!.scheme, 'mailto');
    expect(emailUri(' ', 'x'), isNull);
    expect(telUri('0812-345-678').toString(), 'tel:0812345678');
  });

  test('formatDateTime', () {
    expect(formatDateTime(DateTime(2026, 11, 7, 14, 5)), '07/11/2026 14:05');
    expect(formatDateTime(null), '');
  });
}
