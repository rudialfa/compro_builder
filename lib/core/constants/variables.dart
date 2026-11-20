import 'package:flutter/foundation.dart';

/// Satu-satunya sumber konfigurasi alamat server.
/// Ganti environment dengan memindah tanda komentar (//) pada baseUrl.
class Variables {
  static const String appName = 'Compro Builder';

  // ─── ALAMAT SERVER (pilih SATU, tanpa akhiran /api) ──────────────────────
  // Emulator Android -> komputer host (backend: php artisan serve --host=0.0.0.0)
  // static const String _defaultBaseUrl = 'http://10.0.2.2:8000';
  // HP asli satu Wi-Fi dengan komputer (ganti dengan IP komputer Anda)
  static const String _defaultBaseUrl = 'http://192.168.1.137:8000';
  // Tunnel (ngrok / cloudflared)
  // static const String _defaultBaseUrl = 'https://nama-anda.ngrok-free.dev';
  // Simulator iOS / Flutter desktop
  // static const String _defaultBaseUrl = 'http://127.0.0.1:8000';
  // Produksi
  // static const String _defaultBaseUrl = 'https://domain-anda.com';

  /// Boleh ditimpa saat menjalankan tanpa mengubah file:
  /// flutter run --dart-define=API_BASE_URL=https://domain-anda.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  /// Basis situs tanpa /api (garis miring di akhir dibuang).
  static String get siteBaseUrl => baseUrl.replaceAll(RegExp(r'/+$'), '');

  /// Semua endpoint ada di {baseUrl}/api.
  static String get apiUrl => '$siteBaseUrl/api';

  /// Tautan kontak admin (mis. mailto:admin@contoh.com atau https://wa.me/62...).
  /// Kosong -> tombol "Hubungi admin" disembunyikan.
  static const String adminContactUrl = String.fromEnvironment(
    'ADMIN_CONTACT_URL',
  );

  static const Duration timeout = Duration(seconds: 20);

  /// Rilis wajib HTTPS. Dipanggil sekali di main().
  static void ensureSecure() {
    if (kReleaseMode && !baseUrl.startsWith('https://')) {
      throw StateError('API_BASE_URL wajib https:// pada build rilis.');
    }
  }
}
