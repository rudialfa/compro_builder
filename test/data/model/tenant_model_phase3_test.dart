import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanSummaryModel.daysLeft / isExpired', () {
    final now = DateTime.utc(2026, 11, 9, 12);

    test('tanpa masa berlaku -> null dan tidak kedaluwarsa', () {
      const p = PlanSummaryModel(code: 'pro');
      expect(p.daysLeft(now: now), isNull);
      expect(p.isExpired(now: now), isFalse);
    });

    test('dibulatkan ke atas seperti server', () {
      final p = PlanSummaryModel(expiresAt: DateTime.utc(2026, 11, 23, 0));
      // 13,5 hari -> 14
      expect(p.daysLeft(now: now), 14);
      final q = PlanSummaryModel(expiresAt: DateTime.utc(2026, 11, 23, 13));
      // 14 hari 1 jam -> 15
      expect(q.daysLeft(now: now), 15);
    });

    test('sudah lewat -> tidak positif dan isExpired', () {
      final p = PlanSummaryModel(expiresAt: DateTime.utc(2026, 11, 8));
      expect(p.daysLeft(now: now), lessThanOrEqualTo(0));
      expect(p.isExpired(now: now), isTrue);
    });

    test('tanpa expiresAt memakai expires_in_days dari server', () {
      final p = PlanSummaryModel.fromMap({'code': 'x', 'expires_in_days': 9});
      expect(p.daysLeft(now: now), 9);
    });
  });

  group('TenantModel (Fase 3)', () {
    test('membaca suspended, alasan, dan kelengkapan dari tenantSummary', () {
      final t = TenantModel.fromMap({
        'id': 1,
        'name': 'Kopi',
        'slug': 'kopi',
        'status': 'draft',
        'suspended': true,
        'suspended_reason': '  Pelanggaran  ',
        'completeness': {
          'percent': 60,
          'total': 5,
          'counts': {'lengkap': 2, 'sebagian': 2, 'kosong': 1},
        },
      });
      expect(t.suspended, isTrue);
      expect(t.suspendedReason, 'Pelanggaran');
      expect(t.completeness?.percent, 60);
      expect(t.completeness?.complete, 2);
      expect(t.completeness?.empty, 1);
    });

    test('cache lama tanpa kunci baru tetap terbaca (default aman)', () {
      final t = TenantModel.fromMap({'slug': 'abc', 'plan': 'Standar'});
      expect(t.suspended, isFalse);
      expect(t.suspendedReason, isNull);
      expect(t.completeness, isNull);
    });

    test('toJson -> fromJson bolak-balik membawa kunci baru', () {
      const src = TenantModel(
        id: 5,
        name: 'N',
        slug: 'n',
        suspended: true,
        suspendedReason: 'x',
        plan: PlanSummaryModel(code: 'pro', expiresInDays: 3),
        completeness: CompletenessModel(percent: 40, total: 5, complete: 1, partial: 2, empty: 2),
      );
      final back = TenantModel.fromJson(src.toJson());
      expect(back.suspended, isTrue);
      expect(back.suspendedReason, 'x');
      expect(back.plan?.expiresInDays, 3);
      expect(back.completeness?.percent, 40);
      expect(back.completeness?.partial, 2);
    });

    test('copyWith mempertahankan kunci baru', () {
      const t = TenantModel(
        name: 'N',
        slug: 'n',
        suspended: true,
        completeness: CompletenessModel(percent: 10),
      );
      final c = t.copyWith(unreadMessages: 2);
      expect(c.suspended, isTrue);
      expect(c.completeness?.percent, 10);
      expect(c.unreadMessages, 2);
    });
  });
}
