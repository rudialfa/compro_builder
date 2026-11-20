import 'dart:convert';

import 'package:compro_builder/data/model/request/onboarding_request_model.dart';
import 'package:compro_builder/data/model/response/onboarding_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingResponseModel', () {
    test('membaca needed, state, values, themes', () {
      final m = OnboardingResponseModel.fromJson(
        jsonEncode({
          'data': {
            'needed': true,
            'state': null,
            'values': {
              'name': 'Kopi Kita',
              'subtitle': '',
              'whatsapp': '628123456789',
              'theme': 'indigo',
            },
            'themes': [
              {'code': 'indigo', 'name': 'Indigo'},
              {'code': 'hutan', 'name': 'Hutan'},
            ],
          },
        }),
      );
      expect(m.needed, isTrue);
      expect(m.state, OnboardingStatus.none);
      expect(m.values.name, 'Kopi Kita');
      expect(m.values.whatsapp, '628123456789');
      expect(m.values.theme, 'indigo');
      expect(m.themes.length, 2);
    });

    test('state done dan skipped', () {
      OnboardingStatus stateOf(String s) => OnboardingResponseModel.fromMap({
        'data': {'needed': false, 'state': s},
      }).state;
      expect(stateOf('done'), OnboardingStatus.done);
      expect(stateOf('skipped'), OnboardingStatus.skipped);
      expect(stateOf('lain'), OnboardingStatus.none);
    });

    test('values/themes hilang -> bawaan kosong, tidak melempar', () {
      final m = OnboardingResponseModel.fromMap({'data': {'needed': false}});
      expect(m.needed, isFalse);
      expect(m.values.name, '');
      expect(m.themes, isEmpty);
    });

    test('bukan objek -> FormatException', () {
      expect(() => OnboardingResponseModel.fromJson('[]'), throwsFormatException);
    });
  });

  group('OnboardingRequestModel', () {
    test('subtitle dan whatsapp kosong tidak dikirim, nama dipangkas', () {
      const r = OnboardingRequestModel(
        name: '  Kopi Kita ',
        subtitle: '   ',
        whatsapp: '',
        theme: 'hutan',
      );
      expect(r.toMap(), {'name': 'Kopi Kita', 'theme': 'hutan'});
    });

    test('semua terisi dikirim', () {
      const r = OnboardingRequestModel(
        name: 'Kopi Kita',
        subtitle: 'Kopi enak',
        whatsapp: '0812 3456 7890',
        theme: 'indigo',
      );
      expect(jsonDecode(r.toJson()), {
        'name': 'Kopi Kita',
        'subtitle': 'Kopi enak',
        'whatsapp': '0812 3456 7890',
        'theme': 'indigo',
      });
    });
  });
}
