import 'package:compro_builder/core/constants/variables.dart';
import 'package:flutter/foundation.dart';

/// Pembungkus tipis atas [Variables] supaya kode lama (main.dart, url.dart)
/// tetap jalan. Sumber nilainya satu: Variables.
class Env {
  Env._();

  static String get apiUrl => Variables.apiUrl;
  static String get siteBaseUrl => Variables.siteBaseUrl;
  static String get adminContactUrl => Variables.adminContactUrl;

  /// Mengembalikan pesan galat bila konfigurasi tidak valid, atau null bila aman.
  static String? validate() {
    final base = Variables.baseUrl;
    if (base.isEmpty) {
      return 'Alamat server belum diatur.\n'
          'Isi baseUrl di lib/core/constants/variables.dart.';
    }
    final uri = Uri.tryParse(base);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Alamat server tidak valid: $base';
    }
    if (kReleaseMode && uri.scheme != 'https') {
      return 'Build rilis hanya boleh memakai HTTPS.';
    }
    return null;
  }
}
