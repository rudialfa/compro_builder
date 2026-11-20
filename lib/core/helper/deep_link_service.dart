import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:compro_builder/core/utils/reset_link.dart';
import 'package:compro_builder/core/utils/verify_link.dart';
import 'package:flutter/foundation.dart';

/// Membaca tautan yang membuka aplikasi dan meneruskan tautan atur ulang
/// password ke layar yang tepat.
///
/// - Tautan verifikasi dari email (https .../email/verify-link/...): diteruskan ke
///   `onVerifyLink` (app yang memverifikasi lewat server, tanpa browser).
/// - Tautan `email-verified` (dari halaman web setelah verifikasi email): menaikkan
///   [verifiedTick] supaya layar yang peduli (mis. Akun) memuat ulang status.
///   Pada cold start tidak perlu disimpan: splash memuat `/auth/me` yang baru.
/// - Tautan saat aplikasi sudah berjalan: langsung memanggil `onReset`.
/// - Tautan yang membuka aplikasi dari keadaan mati (cold start): disimpan
///   sebagai tertunda dan diambil layar masuk lewat [takePending], karena
///   layar splash akan mengganti seluruh tumpukan halaman. Tertunda kedaluwarsa
///   setelah [pendingTtl] supaya tidak muncul tiba-tiba di sesi berikutnya.
class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService();

  /// Bisa diganti di test.
  final Stream<Uri>? _uriStream;
  final Future<Uri?> Function()? _initialUri;
  final DateTime Function() _now;
  final Duration pendingTtl;

  DeepLinkService({
    Stream<Uri>? uriStream,
    Future<Uri?> Function()? initialUri,
    DateTime Function()? now,
    this.pendingTtl = const Duration(minutes: 2),
  }) : _uriStream = uriStream,
       _initialUri = initialUri,
       _now = now ?? DateTime.now;

  /// Naik 1 setiap tautan "email terverifikasi" masuk.
  final ValueNotifier<int> verifiedTick = ValueNotifier<int>(0);

  StreamSubscription<Uri>? _subscription;
  ResetLinkInput? _pending;
  DateTime? _pendingAt;

  /// Mulai mendengarkan. Aman dipanggil sekali; galat plugin diabaikan
  /// (mis. platform tanpa dukungan) supaya aplikasi tetap berjalan.
  Future<void> start({
    required void Function(ResetLinkInput) onReset,
    void Function(Uri link)? onVerifyLink,
  }) async {
    try {
      final links = _uriStream == null || _initialUri == null
          ? AppLinks()
          : null;
      final initial = await (_initialUri ?? links!.getInitialLink)();
      if (initial != null) {
        _handle(initial, cold: true, onReset: onReset, onVerifyLink: onVerifyLink);
      }
      _subscription = (_uriStream ?? links!.uriLinkStream).listen(
        (uri) => _handle(
          uri,
          cold: false,
          onReset: onReset,
          onVerifyLink: onVerifyLink,
        ),
        onError: (_) {},
      );
    } catch (_) {
      // Tanpa deep link, pengguna masih bisa menempel tautan secara manual.
    }
  }

  void _handle(
    Uri uri, {
    required bool cold,
    required void Function(ResetLinkInput) onReset,
    void Function(Uri link)? onVerifyLink,
  }) {
    if (isVerifyLinkUri(uri)) {
      onVerifyLink?.call(uri);
      return;
    }
    if (isEmailVerifiedUri(uri)) {
      verifiedTick.value++;
      return;
    }
    final input = parseResetUri(uri);
    if (input == null) return;
    if (cold) {
      _pending = input;
      _pendingAt = _now();
    } else {
      onReset(input);
    }
  }

  /// Mengambil (sekali) tautan atur ulang dari cold start, bila belum kedaluwarsa.
  ResetLinkInput? takePending() {
    final input = _pending;
    final at = _pendingAt;
    _pending = null;
    _pendingAt = null;
    if (input == null || at == null) return null;
    return _now().difference(at) > pendingTtl ? null : input;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
