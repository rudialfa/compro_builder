/// 49000 -> "Rp 49.000".
String formatRupiah(num value) {
  final n = value.round();
  final digits = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return '${n < 0 ? '-' : ''}Rp $buf';
}

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// "7 Nov 2026" (tanpa bergantung pada data locale intl).
String formatDateId(DateTime t) => '${t.day} ${_bulan[t.month - 1]} ${t.year}';

/// "10 Nov 2026, 03:00" (jam 24 jam; berikan waktu lokal, mis. `.toLocal()`).
String formatDateTimeId(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${formatDateId(t)}, ${two(t.hour)}:${two(t.minute)}';
}

/// Sisa waktu sebagai "HH:MM:SS"; nilai negatif ditampilkan "00:00:00".
String formatCountdown(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(total ~/ 3600)}:${two((total % 3600) ~/ 60)}:${two(total % 60)}';
}
