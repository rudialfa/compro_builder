import 'dart:convert';

import 'package:compro_builder/data/model/response/checklist_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _body({
  List<String> blockers = const [],
  String status = 'draft',
}) => {
  'data': {
    'percent': 60,
    'total': 3,
    'counts': {'lengkap': 1, 'sebagian': 1, 'kosong': 1},
    'items': [
      {
        'id': 11,
        'code': 'hero',
        'name': 'Hero',
        'status': 'lengkap',
        'missing': [],
        'note': null,
        'is_sample': false,
      },
      {
        'id': 12,
        'code': 'about',
        'name': 'Tentang',
        'status': 'sebagian',
        'missing': ['Deskripsi'],
        'note': 'Belum diisi: Deskripsi',
        'is_sample': false,
      },
      {
        'id': 14,
        'code': 'contact',
        'name': 'Kontak',
        'status': 'kosong',
        'missing': ['WhatsApp'],
        'note': 'Masih teks contoh',
        'is_sample': true,
      },
    ],
    'publish': {
      'status': status,
      'email_verified': blockers.isEmpty,
      'suspended': blockers.contains('suspended'),
      'can_publish': blockers.isEmpty,
      'blockers': blockers,
    },
  },
};

void main() {
  group('ChecklistResponseModel', () {
    test('memetakan persen, hitungan, item, dan status', () {
      final m = ChecklistResponseModel.fromJson(jsonEncode(_body()));
      expect(m.percent, 60);
      expect(m.total, 3);
      expect((m.complete, m.partial, m.empty), (1, 1, 1));
      expect(m.items.map((i) => i.status), [
        ChecklistStatus.full,
        ChecklistStatus.partial,
        ChecklistStatus.empty,
      ]);
      expect(m.items[1].missing, ['Deskripsi']);
      expect(m.items[1].note, 'Belum diisi: Deskripsi');
      expect(m.items[2].isSample, isTrue);
      expect(m.items[0].note, isNull);
    });

    test('issueCount = section yang belum lengkap', () {
      final m = ChecklistResponseModel.fromJson(jsonEncode(_body()));
      expect(m.issueCount, 2);
    });

    test('publish tanpa hambatan', () {
      final m = ChecklistResponseModel.fromJson(jsonEncode(_body()));
      expect(m.publish.status, SiteStatus.draft);
      expect(m.publish.canPublish, isTrue);
      expect(m.publish.blockers, isEmpty);
    });

    test('blockers email_unverified dan suspended terbaca', () {
      final m = ChecklistResponseModel.fromJson(
        jsonEncode(_body(blockers: ['suspended', 'email_unverified'])),
      );
      expect(m.publish.canPublish, isFalse);
      expect(m.publish.isSuspendedBlock, isTrue);
      expect(m.publish.isEmailBlock, isTrue);
    });

    test('status tak dikenal -> unknown, persen dijepit 0..100', () {
      final m = ChecklistResponseModel.fromMap({
        'percent': 250,
        'items': [
          {'id': 1, 'name': 'X', 'status': 'aneh'},
        ],
      });
      expect(m.percent, 100);
      expect(m.items.single.status, ChecklistStatus.unknown);
      expect(m.items.single.isComplete, isFalse);
      expect(m.publish.canPublish, isTrue);
    });

    test('bukan objek -> FormatException', () {
      expect(
        () => ChecklistResponseModel.fromJson('[]'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
