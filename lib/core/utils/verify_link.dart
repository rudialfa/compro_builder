/// Tautan masuk ke aplikasi yang berkaitan dengan verifikasi email.

/// Skema app `comprobuilder://email-verified` (tombol "Buka aplikasi" di halaman web
/// setelah verifikasi). Bentuk https dengan segmen `email-verified` juga dikenali.
bool isEmailVerifiedUri(Uri uri) {
  final isWeb = uri.scheme == 'https' || uri.scheme == 'http';
  final segments = [
    if (!isWeb && uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments,
  ];
  return segments.contains('email-verified');
}

/// Tautan di email verifikasi: `https://domain/email/verify-link/{id}/{hash}?expires=..&signature=..`.
/// Bila app terpasang dan domain terverifikasi (Android App Links / iOS Universal Links),
/// tautan ini membuka app langsung, lalu app memverifikasinya lewat server.
bool isVerifyLinkUri(Uri uri) {
  if (uri.scheme != 'https' && uri.scheme != 'http') return false;
  final s = uri.pathSegments;
  final i = s.indexOf('verify-link');
  return i >= 1 &&
      s[i - 1] == 'email' &&
      i + 2 < s.length &&
      s[i + 1].isNotEmpty &&
      s[i + 2].isNotEmpty &&
      uri.queryParameters.containsKey('signature');
}
