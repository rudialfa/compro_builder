import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan token Sanctum di Keychain (iOS) / Keystore (Android).
/// Hanya token yang disimpan; password tidak pernah disimpan.
class AuthLocalDatasource {
  static const _keyToken = 'auth_token';

  final FlutterSecureStorage _storage;

  AuthLocalDatasource([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  /// Keystore rusak/tidak terbaca dianggap belum login (token dibersihkan).
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _keyToken);
    } catch (_) {
      await removeToken();
      return null;
    }
  }

  Future<void> removeToken() async {
    try {
      await _storage.delete(key: _keyToken);
    } catch (_) {
      // Abaikan; tidak ada yang bisa dilakukan bila Keystore tidak bisa ditulis.
    }
  }
}
