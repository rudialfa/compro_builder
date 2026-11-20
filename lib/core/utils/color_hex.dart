import 'package:flutter/painting.dart';

/// "#1d2b5f" atau "1d2b5f" -> [Color]; null bila bukan 6 digit heksadesimal.
Color? parseHexColor(String value) {
  final m = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(value.trim());
  if (m == null) return null;
  return Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
}
