/// Tautan situs publik, dibentuk dari basis situs (tanpa /api).
String siteUrl(String base, String slug) =>
    '$base/${Uri.encodeComponent(slug)}';

/// Mode pengunjung untuk pemilik: `?lihat=pengunjung`.
String previewUrl(String base, String slug) =>
    '${siteUrl(base, slug)}?lihat=pengunjung';

/// Tautan situs publik untuk pratinjau/berbagi. Memakai url dari server bila
/// ada dan valid (http/https dengan host), sehingga domain sendiri tetap benar;
/// bila tidak, jatuh ke [siteUrl] dari basis API + slug.
String publicSiteUrl(String? serverUrl, String base, String slug) {
  final raw = serverUrl?.trim() ?? '';
  final uri = raw.isEmpty ? null : Uri.tryParse(raw);
  var valid =
      uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
  // Server uji sering memberi alamat 127.0.0.1/localhost (APP_URL), yang tidak
  // bisa dijangkau dari HP. Bila app sendiri memakai host lain, pakai host app.
  if (valid && _isLoopback(uri.host)) {
    final baseHost = Uri.tryParse(base)?.host ?? '';
    if (baseHost.isNotEmpty && !_isLoopback(baseHost)) valid = false;
  }
  // buang garis miring akhir supaya tidak ada `//` saat disambung path
  return valid ? raw.replaceFirst(RegExp(r'/+$'), '') : siteUrl(base, slug);
}

bool _isLoopback(String host) {
  final h = host.toLowerCase();
  return h == 'localhost' ||
      h == '127.0.0.1' ||
      h == '0.0.0.0' ||
      h == '::1' ||
      h == '[::1]';
}

enum NavDecision { allow, external, block }

const _externalSchemes = {'tel', 'mailto', 'sms', 'whatsapp'};

/// Kebijakan navigasi WebView pratinjau:
/// - http/https ke host situs sendiri -> tetap di WebView;
/// - http/https ke host lain -> buka di browser luar;
/// - tel/mailto/sms/whatsapp -> aplikasi luar; skema lain (intent:, file:, javascript:) -> blokir.
NavDecision decideNavigation(Uri target, Uri base) {
  final scheme = target.scheme.toLowerCase();
  if (scheme == 'about') return NavDecision.allow;
  if (scheme == 'http' || scheme == 'https') {
    return target.host.toLowerCase() == base.host.toLowerCase() &&
            target.port == base.port
        ? NavDecision.allow
        : NavDecision.external;
  }
  return _externalSchemes.contains(scheme)
      ? NavDecision.external
      : NavDecision.block;
}

/// Perlu membawa token pemilik? Hanya untuk situs DRAFT dan hanya ke host API sendiri.
/// WebView tidak punya sesi web: tanpa header ini server menjawab 404 untuk halaman situs draft,
/// jadi setiap perpindahan halaman (menu, detail layanan, foto galeri) harus ikut membawa token.
bool needsAuthHeader(Uri target, Uri api, {required bool draft}) {
  if (!draft) return false;
  final scheme = target.scheme.toLowerCase();
  return (scheme == 'http' || scheme == 'https') &&
      target.host.toLowerCase() == api.host.toLowerCase() &&
      target.port == api.port;
}

/// Dua alamat menunjuk halaman yang sama (hanya beda `#anchor`)? Perpindahan seperti ini
/// tidak memuat ulang halaman, jadi tidak perlu dimuat ulang dengan header.
bool isSamePageIgnoringFragment(Uri a, Uri b) =>
    a.removeFragment().toString() == b.removeFragment().toString();

String fixSiteUrl(String url, String baseUrl) {
  final u = Uri.parse(url);
  const loopback = {'127.0.0.1', 'localhost', '10.0.2.2'};
  if (!loopback.contains(u.host)) return url; // domain asli tidak disentuh
  final b = Uri.parse(baseUrl);
  return u.replace(scheme: b.scheme, host: b.host, port: b.port).toString();
}
