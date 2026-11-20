import 'package:flutter/material.dart';

/// Kunci global supaya navigasi dan snackbar bisa dipicu dari luar widget
/// (mis. saat sesi berakhir karena server menjawab 401).
class AppKeys {
  static final GlobalKey<NavigatorState> navigator =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> messenger =
      GlobalKey<ScaffoldMessengerState>();
}
