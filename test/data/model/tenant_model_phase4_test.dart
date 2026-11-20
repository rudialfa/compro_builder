import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final json = {
    'id': 1,
    'name': 'Kopi Kita',
    'slug': 'kopikita',
    'status': 'draft',
    'theme': {
      'code': 'indigo',
      'name': 'Indigo',
      'brand': '#1d2b5f',
      'bright': '#f5b400',
      'soft': '#eef1fa',
    },
    'needs_onboarding': true,
  };

  test('membaca theme dan needs_onboarding dari tenantSummary', () {
    final t = TenantModel.fromMap(json);
    expect(t.theme?.code, 'indigo');
    expect(t.theme?.brand, '#1d2b5f');
    expect(t.needsOnboarding, isTrue);
  });

  test('cache lama tanpa kunci baru: theme null, needsOnboarding false', () {
    final t = TenantModel.fromMap({'id': 2, 'name': 'Lama', 'slug': 'lama'});
    expect(t.theme, isNull);
    expect(t.needsOnboarding, isFalse);
  });

  test('toMap/fromMap membulatkan kembali, termasuk kunci lama', () {
    final t = TenantModel.fromMap({
      ...json,
      'suspended': true,
      'suspended_reason': 'Pelanggaran',
    });
    final back = TenantModel.fromJson(t.toJson());
    expect(back.theme?.name, 'Indigo');
    expect(back.needsOnboarding, isTrue);
    expect(back.suspended, isTrue);
    expect(back.suspendedReason, 'Pelanggaran');
    expect(back.slug, 'kopikita');
  });

  test('copyWith mengganti needsOnboarding dan mempertahankan theme', () {
    final t = TenantModel.fromMap(json).copyWith(needsOnboarding: false);
    expect(t.needsOnboarding, isFalse);
    expect(t.theme?.code, 'indigo');
  });
}
