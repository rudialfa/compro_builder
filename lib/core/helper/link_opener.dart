import 'package:url_launcher/url_launcher.dart';

/// Membuka tautan di aplikasi luar (browser). Hanya http/https.
/// Mengembalikan false bila skema tidak diizinkan atau gagal dibuka.
Future<bool> openExternalLink(Uri uri) async {
  if (uri.scheme != 'https' && uri.scheme != 'http') return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

const _contactSchemes = {'http', 'https', 'mailto', 'tel', 'sms', 'whatsapp'};

/// Membuka tautan kontak di aplikasi luar: http/https, mailto, tel, sms, whatsapp.
/// Skema lain (intent:, file:, javascript:) ditolak. Dipakai untuk tombol balas
/// lewat email/telepon dan tautan keluar dari pratinjau. Tautan dari server
/// (mis. upgrade paket) tetap memakai [openExternalLink] yang hanya http/https.
Future<bool> openContactLink(Uri uri) async {
  if (!_contactSchemes.contains(uri.scheme.toLowerCase())) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
