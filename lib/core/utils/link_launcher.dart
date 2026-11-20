import 'package:compro_builder/core/helper/link_opener.dart';

/// Bentuk fungsi "buka tautan di aplikasi luar".
/// Dipakai bila halaman/bloc menerima fungsi ini lewat konstruktor supaya
/// mudah diganti saat uji.
typedef LinkLauncher = Future<bool> Function(Uri uri);

/// Implementasi bawaan: [openContactLink] (core/helper/link_opener.dart),
/// yang hanya mengizinkan http, https, mailto, tel, sms, dan whatsapp.
const LinkLauncher defaultLinkLauncher = openContactLink;
