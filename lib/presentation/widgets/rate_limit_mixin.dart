import 'dart:async';

import 'package:flutter/material.dart';

/// Menonaktifkan tombol sementara setelah server menjawab 429.
/// Pakai pada State: startCooldown(failure.retryAfter) lalu cek [isCoolingDown].
mixin RateLimitMixin<T extends StatefulWidget> on State<T> {
  Timer? _cooldownTimer;
  int cooldownSeconds = 0;

  bool get isCoolingDown => cooldownSeconds > 0;

  void startCooldown([int? seconds]) {
    _cooldownTimer?.cancel();
    setState(() {
      cooldownSeconds = (seconds == null || seconds <= 0) ? 60 : seconds;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        cooldownSeconds--;
        if (cooldownSeconds <= 0) {
          cooldownSeconds = 0;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
