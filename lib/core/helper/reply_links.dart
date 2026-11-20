/// Nomor untuk wa.me (hanya digit, kode negara): "0812-3456" -> "628123456".
/// Null bila terlalu pendek untuk menjadi nomor telepon.
String? waNumber(String? phone) {
  if (phone == null) return null;
  var d = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('0')) {
    d = '62${d.substring(1)}';
  } else if (d.startsWith('8')) {
    d = '62$d';
  }
  return d.length < 8 ? null : d;
}

Uri? whatsappUri(String? phone, String text) {
  final n = waNumber(phone);
  return n == null
      ? null
      : Uri.parse('https://wa.me/$n?text=${Uri.encodeComponent(text)}');
}

Uri? emailUri(String email, String subject) {
  final e = email.trim();
  if (e.isEmpty) return null;
  return Uri.parse('mailto:$e?subject=${Uri.encodeComponent(subject)}');
}

Uri? telUri(String? phone) {
  final p = phone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
  return p.length < 5 ? null : Uri.parse('tel:$p');
}

/// "07/11/2026 14:05" (tanpa bergantung pada data locale intl).
String formatDateTime(DateTime? t) {
  if (t == null) return '';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
}
