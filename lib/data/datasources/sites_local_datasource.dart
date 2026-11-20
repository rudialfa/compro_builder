import 'dart:convert';

import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache offline daftar situs + slug situs aktif (bukan data rahasia).
/// Kunci sama dengan versi lama, jadi cache lama tetap terbaca.
class SitesLocalDatasource {
  static const _tenantsKey = 'cache_tenants';
  static const _activeKey = 'active_slug';

  /// Null bila belum ada cache atau isinya rusak.
  Future<List<TenantModel>?> readTenants() async {
    final raw = (await SharedPreferences.getInstance()).getString(_tenantsKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      final list = decoded is Map ? decoded['data'] : decoded;
      if (list is! List) return null;
      return TenantsResponseModel.fromList(list).data;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeTenants(List<TenantModel> tenants) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _tenantsKey,
      TenantsResponseModel(data: tenants).toJson(),
    );
  }

  Future<String?> readActiveSlug() async =>
      (await SharedPreferences.getInstance()).getString(_activeKey);

  Future<void> writeActiveSlug(String slug) async =>
      (await SharedPreferences.getInstance()).setString(_activeKey, slug);

  /// Dipanggil saat keluar / sesi berakhir supaya data pengguna lain tidak bocor.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tenantsKey);
    await prefs.remove(_activeKey);
  }
}
