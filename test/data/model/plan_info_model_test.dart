import 'dart:convert';

import 'package:compro_builder/data/model/response/plan_info_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanInfoModel', () {
    test('plan objek berisi harga & batas', () {
      final p = PlanInfoModel.fromMap({
        'code': 'medium',
        'name': 'Medium',
        'price': 49000,
        'limits': {
          'max_sections': 8,
          'max_kb': 3072,
          'contact_form': true,
          'custom_domain': false,
        },
        'expires_at': '2026-12-01T00:00:00Z',
        'upgrade_url': 'https://x.test/upgrade',
      });
      expect(p.name, 'Medium');
      expect(p.priceLabel, 'Rp 49.000');
      expect(p.upgradeUrl, 'https://x.test/upgrade');
      expect(p.limitRows.map((e) => '${e.label}=${e.value}'), [
        'Jumlah section=8',
        'Ukuran gambar maks.=3 MB',
        'Form kontak=Ya',
        'Domain sendiri=Tidak',
      ]);
    });

    test('bungkus data, harga string, tanpa batas (null)', () {
      final p = PlanInfoModel.fromJson(
        jsonEncode({
          'data': {
            'code': 'pro',
            'price': '99000.00',
            'limits': {'max_sections': null, 'upload_kb': 8192},
          },
        }),
      );
      expect(p.name, 'pro'); // tanpa name -> memakai code
      expect(p.price, 99000);
      expect(p.expiresAt, isNull);
      expect(p.limitRows.first.value, isNull); // "Tanpa batas"
      expect(p.limitRows.last.value, '8 MB');
    });

    test('kunci tak dikenal dipercantik; nilai bersarang dilewati', () {
      final p = PlanInfoModel.fromMap({
        'code': 'standar',
        'limits': {
          'max_items_total': 5,
          'nested': {'a': 1},
        },
      });
      expect(p.limitRows.single.label, 'Max items total');
    });

    test('tanpa nama/kode atau bukan objek -> FormatException', () {
      expect(
        () => PlanInfoModel.fromMap({'limits': <String, dynamic>{}}),
        throwsFormatException,
      );
      expect(() => PlanInfoModel.fromJson('"x"'), throwsFormatException);
    });

    test('daysLeft: tanggal saja, negatif bila lewat, null bila tanpa batas', () {
      final p = PlanInfoModel(
        code: 'm',
        name: 'M',
        expiresAt: DateTime(2026, 11, 10, 23, 59),
      );
      expect(p.daysLeft(DateTime(2026, 11, 7, 8)), 3);
      expect(p.daysLeft(DateTime(2026, 11, 10, 8)), 0);
      expect(p.daysLeft(DateTime(2026, 11, 12)), -2);
      expect(
        const PlanInfoModel(code: 'm', name: 'M').daysLeft(DateTime(2026)),
        isNull,
      );
    });

    test('toJson -> fromJson bolak-balik', () {
      final p = PlanInfoModel.fromMap({
        'code': 'medium',
        'name': 'Medium',
        'level': 2,
        'price': 49000,
        'limits': {'max_sections': 8},
        'expires_at': '2026-12-01T00:00:00Z',
        'upgrade_url': 'https://x.test/upgrade',
      });
      final back = PlanInfoModel.fromJson(p.toJson());
      expect(back.code, 'medium');
      expect(back.level, 2);
      expect(back.price, 49000);
      expect(back.limits, {'max_sections': 8});
      expect(back.upgradeUrl, 'https://x.test/upgrade');
      expect(back.expiresAt!.isAtSameMomentAs(p.expiresAt!), isTrue);
    });
  });
}
