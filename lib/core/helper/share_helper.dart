import 'package:share_plus/share_plus.dart';

/// Lembar bagikan sistem. Dipisah dari halaman supaya mudah diganti saat uji.
Future<void> shareText(String text, {String? subject}) async {
  await SharePlus.instance.share(ShareParams(text: text, subject: subject));
}
