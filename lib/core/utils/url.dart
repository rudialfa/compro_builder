import '../config/env.dart';

/// Mengubah path gambar relatif ("/storage/x.jpg") menjadi URL absolut.
String resolveUrl(String u) {
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  return '${Env.siteBaseUrl}${u.startsWith('/') ? u : '/$u'}';
}
