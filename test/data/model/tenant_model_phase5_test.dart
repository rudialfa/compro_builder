import 'package:compro_builder/data/model/response/template_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final json = {
    'id': 1,
    'name': 'Kopi Kita',
    'slug': 'kopikita',
    'status': 'draft',
    'template': {
      'code': 'classic',
      'name': 'Classic',
      'tier': 'classic',
      'min_level': 1,
    },
  };

  test('membaca template dari tenantSummary', () {
    final t = TenantModel.fromMap(json);
    expect(t.template?.code, 'classic');
    expect(t.template?.name, 'Classic');
    expect(t.template?.tier, 'classic');
    expect(t.template?.minLevel, 1);
  });

  test('cache lama tanpa template: null', () {
    final t = TenantModel.fromMap({'id': 2, 'name': 'Lama', 'slug': 'lama'});
    expect(t.template, isNull);
  });

  test('toMap/fromMap membulatkan kembali template', () {
    final back = TenantModel.fromJson(TenantModel.fromMap(json).toJson());
    expect(back.template?.name, 'Classic');
    expect(back.template?.minLevel, 1);
  });

  test('copyWith menjaga template lama bila tidak diganti', () {
    final t = TenantModel.fromMap(json);
    expect(t.copyWith(name: 'Baru').template?.code, 'classic');
    expect(
      t.copyWith(template: const TemplateSummaryModel(code: 'elegan')).template?.code,
      'elegan',
    );
  });
}
