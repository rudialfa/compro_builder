import 'package:compro_builder/data/model/response/section_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache offline daftar section per situs (bukan data rahasia).
/// Kunci sama dengan versi lama (`cache_sections_<slug>`); bentuk pembungkus
/// lama maupun bentuk datar baru sama-sama terbaca oleh model.
class SectionsLocalDatasource {
  static const _prefix = 'cache_sections_';

  /// Null bila belum ada cache atau isinya rusak.
  Future<SectionsDataModel?> read(String slug) async {
    final raw = (await SharedPreferences.getInstance()).getString(
      '$_prefix$slug',
    );
    if (raw == null) return null;
    try {
      return SectionsDataModel.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String slug, SectionsDataModel data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$slug', data.toJson());
  }

  /// Dipanggil saat keluar / sesi berakhir supaya data pengguna lain tidak bocor.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key
        in prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      await prefs.remove(key);
    }
  }
}
