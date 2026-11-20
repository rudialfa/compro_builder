import 'dart:convert';
import 'dart:typed_data';

import 'package:compro_builder/data/model/request/section_payload.dart';
import 'package:compro_builder/data/model/request/settings_changes_model.dart';
import 'package:compro_builder/data/model/response/site_settings_model.dart';
import 'package:flutter_test/flutter_test.dart';

SiteSettingsModel _base() => SiteSettingsModel.fromJson(
  jsonEncode({
    'data': {
      'name': 'Toko',
      'seo': {'title': 'T', 'description': null},
      'socials': {
        'instagram': {'label': 'Instagram', 'url': 'https://instagram.com/a'},
        'x': {'label': 'X', 'url': 'https://x.com/a'},
      },
      'notify_email': 'a@b.c',
    },
  }),
);

void main() {
  test('tanpa perubahan -> isEmpty (spasi di tepi diabaikan)', () {
    final c = SettingsChangesModel.diff(_base(), {
      'name': ' Toko ',
      'seo_title': 'T',
    });
    expect(c.isEmpty, isTrue);
  });

  test('hanya teks yang berubah yang dikirim, dengan kunci datar', () {
    final c = SettingsChangesModel.diff(_base(), {
      'name': 'Toko',
      'seo_title': 'Baru',
    });
    expect(c.toMap(), {'seo_title': 'Baru'});
  });

  test('satu tautan berubah -> SELURUH peta tautan dikirim (backend menimpa semuanya)', () {
    final c = SettingsChangesModel.diff(_base(), {
      'socials.facebook': 'https://fb.com/a',
    });
    expect(c.toMap()['socials'], {
      'instagram': 'https://instagram.com/a',
      'facebook': 'https://fb.com/a',
      'x': 'https://x.com/a',
    });
  });

  test('mengosongkan tautan menghapusnya dari peta', () {
    final c = SettingsChangesModel.diff(_base(), {'socials.x': ''});
    expect(c.toMap()['socials'], {'instagram': 'https://instagram.com/a'});
  });

  test('tautan tidak berubah -> kunci socials tidak dikirim', () {
    final c = SettingsChangesModel.diff(_base(), {
      'socials.x': 'https://x.com/a',
      'name': 'Lain',
    });
    expect(c.toMap().containsKey('socials'), isFalse);
  });

  test('logo baru mengalahkan hapus; favicon dihapus -> favicon_remove', () {
    final c = SettingsChangesModel.diff(
      _base(),
      {},
      logo: Uint8List.fromList([1]),
      removeLogo: true,
      removeFavicon: true,
    );
    final map = c.toMap();
    expect(map['logo'], isA<UploadFile>());
    expect(map.containsKey('logo_remove'), isFalse);
    expect(map['favicon_remove'], 1);
    expect(c.touchesFiles, isTrue);
  });

  test('round-trip toJson -> fromJson', () {
    final again = SiteSettingsModel.fromJson(_base().toJson());
    expect(again.socials, _base().socials);
    expect(again.seoTitle, 'T');
  });

  test('multipage: hanya dikirim bila berubah, sebagai boolean', () {
    final base = _base(); // multipage default false
    final on = SettingsChangesModel.diff(base, {}, multipage: true);
    expect(on.isEmpty, isFalse);
    expect(on.toMap(), {'multipage': true});

    expect(SettingsChangesModel.diff(base, {}, multipage: false).isEmpty, isTrue);
    expect(SettingsChangesModel.diff(base, {}).toMap().containsKey('multipage'), isFalse);

    final flat = flattenPayload(on.toMap());
    expect(flat.fields.single.key, 'multipage');
    expect(flat.fields.single.value, '1');
  });

  test('SiteSettingsModel membaca multipage & multipage_available (default false), round-trip', () {
    expect(_base().multipage, isFalse);
    expect(_base().multipageAvailable, isFalse);

    final on = SiteSettingsModel.fromJson(
      jsonEncode({
        'data': {'name': 'T', 'multipage': true, 'multipage_available': true},
      }),
    );
    expect(on.multipage, isTrue);
    expect(on.multipageAvailable, isTrue);
    final again = SiteSettingsModel.fromJson(on.toJson());
    expect(again.multipage, isTrue);
    expect(again.multipageAvailable, isTrue);

    // multipage sudah true: mengirim true lagi bukan perubahan
    expect(SettingsChangesModel.diff(on, {}, multipage: true).isEmpty, isTrue);
    expect(SettingsChangesModel.diff(on, {}, multipage: false).toMap(), {'multipage': false});
  });
}
