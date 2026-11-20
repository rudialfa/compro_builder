import 'dart:convert';

import 'package:compro_builder/data/model/response/theme_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemesResponseModel', () {
    test('membaca {data:{current, themes}}', () {
      final m = ThemesResponseModel.fromJson(
        jsonEncode({
          'data': {
            'current': 'hutan',
            'themes': [
              {
                'code': 'indigo',
                'name': 'Indigo',
                'brand': '#1d2b5f',
                'bright': '#f5b400',
                'soft': '#eef1fa',
              },
              {'code': 'hutan', 'name': 'Hutan', 'brand': '#14402f'},
              {'name': 'tanpa kode'},
            ],
          },
        }),
      );
      expect(m.current, 'hutan');
      expect(m.themes.map((t) => t.code), ['indigo', 'hutan']);
      expect(m.themes.first.brand, '#1d2b5f');
      expect(m.themes.last.bright, '');
    });

    test('tanpa daftar themes -> FormatException', () {
      expect(
        () => ThemesResponseModel.fromJson(jsonEncode({'data': {'current': 'x'}})),
        throwsFormatException,
      );
    });

    test('bukan objek -> FormatException', () {
      expect(() => ThemesResponseModel.fromJson('[]'), throwsFormatException);
    });
  });

  test('ThemeOptionModel.toMap membulatkan kembali fromMap', () {
    const t = ThemeOptionModel(
      code: 'laut',
      name: 'Laut',
      brand: '#0b4f5c',
      bright: '#7fe0d0',
      soft: '#e6f4f5',
    );
    final back = ThemeOptionModel.fromMap(t.toMap());
    expect(back.code, 'laut');
    expect(back.soft, '#e6f4f5');
  });
}
