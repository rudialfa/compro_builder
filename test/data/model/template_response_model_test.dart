import 'dart:convert';

import 'package:compro_builder/data/model/response/template_response_model.dart';
import 'package:compro_builder/data/model/response/template_update_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _listing() => {
  'active': 'classic',
  'chosen': 'elegan',
  'templates': [
    {
      'code': 'classic',
      'name': 'Classic',
      'tagline': 'Rapi',
      'best_for': 'Semua usaha',
      'tier': 'classic',
      'min_level': 1,
      'plan_required': {'level': 1, 'name': 'Standar'},
      'locked': false,
      'active': true,
    },
    {
      'code': 'elegan',
      'name': 'Elegan',
      'tagline': 'Mewah',
      'best_for': 'Butik',
      'tier': 'pro',
      'min_level': 3,
      'plan_required': {'level': 3, 'name': 'Pro'},
      'locked': true,
      'active': false,
    },
    {'name': 'Tanpa kode'},
  ],
};

void main() {
  group('TemplatesResponseModel', () {
    test('membaca {data: {...}}; entri tanpa code dilewati', () {
      final m = TemplatesResponseModel.fromJson(jsonEncode({'data': _listing()}));
      expect(m.active, 'classic');
      expect(m.chosen, 'elegan');
      expect(m.templates.length, 2);

      final pro = m.templates[1];
      expect(pro.locked, isTrue);
      expect(pro.active, isFalse);
      expect(pro.minLevel, 3);
      expect(pro.requiredLevel, 3);
      expect(pro.requiredPlanName, 'Pro');
      expect(pro.bestFor, 'Butik');
    });

    test('chosen null atau kosong = null', () {
      final a = TemplatesResponseModel.fromMap({
        'data': {'active': 'classic', 'chosen': null, 'templates': []},
      });
      final b = TemplatesResponseModel.fromMap({
        'active': 'classic',
        'chosen': '',
        'templates': [],
      });
      expect(a.chosen, isNull);
      expect(b.chosen, isNull);
    });

    test('tanpa daftar templates -> FormatException', () {
      expect(
        () => TemplatesResponseModel.fromMap({'data': {'active': 'x'}}),
        throwsFormatException,
      );
    });

    test('plan_required hilang: level jatuh ke min_level, nama kosong', () {
      final o = TemplateOptionModel.fromMap({
        'code': 'a',
        'min_level': 2,
      });
      expect(o.requiredLevel, 2);
      expect(o.requiredPlanName, '');
      expect(o.locked, isFalse);
    });
  });

  group('PreviewLinkModel', () {
    test('membaca url dan expires_at', () {
      final m = PreviewLinkModel.fromJson(
        jsonEncode({
          'data': {
            'url': 'https://x.test/api/a/manage/templates/b/preview?signature=s',
            'expires_at': '2026-11-09T10:00:00+00:00',
          },
        }),
      );
      expect(m.url, contains('signature=s'));
      expect(m.expiresAt, isNotNull);
    });

    test('url kosong -> FormatException', () {
      expect(
        () => PreviewLinkModel.fromJson(jsonEncode({'data': {'url': ''}})),
        throwsFormatException,
      );
    });
  });

  group('TemplateUpdateResponseModel', () {
    test('membaca daftar dan summary (tenantSummary) dari data.summary', () {
      final m = TemplateUpdateResponseModel.fromJson(
        jsonEncode({
          'data': {
            ..._listing(),
            'active': 'elegan',
            'summary': {
              'id': 1,
              'name': 'Kopi Kita',
              'slug': 'kopikita',
              'status': 'draft',
              'template': {
                'code': 'elegan',
                'name': 'Elegan',
                'tier': 'pro',
                'min_level': 3,
              },
            },
          },
          'message': 'Tampilan diganti ke Elegan.',
        }),
      );
      expect(m.templates.active, 'elegan');
      expect(m.tenant.slug, 'kopikita');
      expect(m.tenant.template?.code, 'elegan');
      expect(m.tenant.template?.minLevel, 3);
    });

    test('tanpa summary -> FormatException', () {
      expect(
        () => TemplateUpdateResponseModel.fromJson(jsonEncode({'data': _listing()})),
        throwsFormatException,
      );
    });
  });
}
