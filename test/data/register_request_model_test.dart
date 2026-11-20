import 'dart:convert';

import 'package:compro_builder/data/model/request/register_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

RegisterRequestModel _model({String? company, String? slug}) =>
    RegisterRequestModel(
      name: 'Demo',
      email: 'demo@test.com',
      password: 'rahasia123',
      passwordConfirmation: 'rahasia123',
      companyName: company,
      slug: slug,
    );

void main() {
  group('RegisterRequestModel', () {
    test('tanpa nama usaha: tidak ada company_name/slug (perilaku lama)', () {
      final map = _model().toMap();
      expect(map.containsKey('company_name'), isFalse);
      expect(map.containsKey('slug'), isFalse);
    });

    test('nama usaha dan slug dikirim setelah di-trim', () {
      final map = _model(company: '  Maju Jaya ', slug: ' maju-jaya ').toMap();
      expect(map['company_name'], 'Maju Jaya');
      expect(map['slug'], 'maju-jaya');
    });

    test('slug kosong tidak dikirim', () {
      final map = _model(company: 'Maju Jaya', slug: '  ').toMap();
      expect(map['company_name'], 'Maju Jaya');
      expect(map.containsKey('slug'), isFalse);
    });

    test('slug tanpa nama usaha tidak dikirim (server menolaknya)', () {
      final map = _model(company: '', slug: 'maju-jaya').toMap();
      expect(map.containsKey('company_name'), isFalse);
      expect(map.containsKey('slug'), isFalse);
    });

    test('toJson sama dengan toMap', () {
      final m = _model(company: 'Maju Jaya', slug: 'maju-jaya');
      expect(jsonDecode(m.toJson()), m.toMap());
    });
  });
}
