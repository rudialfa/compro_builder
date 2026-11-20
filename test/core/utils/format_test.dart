import 'package:compro_builder/core/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatRupiah', () {
    expect(formatRupiah(49000), 'Rp 49.000');
    expect(formatRupiah(1250000), 'Rp 1.250.000');
    expect(formatRupiah(0), 'Rp 0');
    expect(formatRupiah(999), 'Rp 999');
  });

  test('formatDateId', () {
    expect(formatDateId(DateTime(2026, 11, 7)), '7 Nov 2026');
  });

  test('formatDateTimeId memakai jam 24 jam dengan nol di depan', () {
    expect(formatDateTimeId(DateTime(2026, 11, 10, 3, 5)), '10 Nov 2026, 03:05');
    expect(formatDateTimeId(DateTime(2026, 12, 1, 18, 30)), '1 Des 2026, 18:30');
  });

  test('formatCountdown', () {
    expect(formatCountdown(const Duration(hours: 2, minutes: 5, seconds: 9)), '02:05:09');
    expect(formatCountdown(const Duration(seconds: 59)), '00:00:59');
    expect(formatCountdown(const Duration(hours: 25)), '25:00:00');
    expect(formatCountdown(const Duration(seconds: -5)), '00:00:00');
  });
}
