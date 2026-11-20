import 'package:compro_builder/core/helper/share_helper.dart';

/// Bentuk fungsi "bagikan teks" lewat lembar bagikan sistem.
/// Dipakai bila halaman/bloc menerima fungsi ini lewat konstruktor supaya
/// mudah diganti saat uji.
typedef ShareText = Future<void> Function(String text, {String? subject});

/// Implementasi bawaan: [shareText] (core/helper/share_helper.dart).
const ShareText defaultShareText = shareText;
