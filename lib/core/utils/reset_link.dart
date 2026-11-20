/// Hasil membaca isian "tautan atau kode" dari email atur ulang password.
class ResetLinkInput {
  final String token;

  /// Email dari parameter `email` pada tautan; null bila isian bukan tautan.
  final String? email;

  const ResetLinkInput({required this.token, this.email});
}

/// Email atur ulang membawa tautan web `/reset-password/{token}?email=...`.
/// Pengguna boleh menempel tautan utuh atau hanya token. Hanya http/https yang
/// dikenali sebagai tautan; selain itu seluruh isian dianggap token.
ResetLinkInput parseResetInput(String raw) {
  final text = raw.trim();
  final uri = Uri.tryParse(text);
  if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
    final segments = uri.pathSegments;
    final i = segments.indexOf('reset-password');
    if (i >= 0 && i + 1 < segments.length && segments[i + 1].isNotEmpty) {
      final email = uri.queryParameters['email']?.trim();
      return ResetLinkInput(
        token: segments[i + 1],
        email: (email == null || email.isEmpty) ? null : email,
      );
    }
  }
  return ResetLinkInput(token: text);
}

/// Membaca tautan masuk ke aplikasi (deep link) untuk atur ulang password.
///
/// Dikenali dua bentuk, keduanya memuat segmen `reset-password/{token}` dan
/// parameter `email`:
/// - `https://domain/reset-password/{token}?email=...` (tautan di email web)
/// - `comprobuilder://reset-password/{token}?email=...` (skema aplikasi)
///
/// Mengembalikan null bila bukan tautan atur ulang password.
ResetLinkInput? parseResetUri(Uri uri) {
  final isWeb = uri.scheme == 'https' || uri.scheme == 'http';
  final segments = [
    if (!isWeb && uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments,
  ];
  final i = segments.indexOf('reset-password');
  if (i < 0 || i + 1 >= segments.length || segments[i + 1].isEmpty) {
    return null;
  }
  final email = uri.queryParameters['email']?.trim();
  return ResetLinkInput(
    token: segments[i + 1],
    email: (email == null || email.isEmpty) ? null : email,
  );
}
