import 'package:compro_builder/core/helper/app_keys.dart';
import 'package:compro_builder/core/helper/deep_link_service.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/presentation/widgets/ux_helpers.dart';
import 'package:flutter/material.dart';

/// Notifikasi dalam aplikasi untuk SERVER UJI: server mengirim `dev_verify_url`
/// (tautan yang sama dengan di email), lalu pengguna cukup mengetuk
/// "Verifikasi sekarang" tanpa membuka Gmail. Di server sungguhan tautan ini tidak
/// pernah dikirim, jadi banner ini tidak pernah muncul.
void showDevVerifyNotice(String url, {AuthRemoteDatasource? remote}) {
  final messenger = AppKeys.messenger.currentState;
  if (messenger == null) return;
  final link = Uri.tryParse(url);
  if (link == null) return;

  messenger.hideCurrentMaterialBanner();
  messenger.showMaterialBanner(
    MaterialBanner(
      leading: const Icon(Icons.mark_email_read_outlined),
      content: const Text(
        'Mode uji: tautan verifikasi siap. Ketuk untuk memverifikasi tanpa membuka email.',
      ),
      actions: [
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: const Text('Tutup'),
        ),
        FilledButton(
          onPressed: () async {
            messenger.hideCurrentMaterialBanner();
            final result = await (remote ?? AuthRemoteDatasource()).verifyViaLink(link);
            result.fold(
              (failure) => showToast(failure.message, kind: ToastKind.error),
              (data) {
                showToast(
                  data.message.isEmpty ? 'Email terverifikasi. Terima kasih!' : data.message,
                  kind: ToastKind.success,
                );
                DeepLinkService.instance.verifiedTick.value++;
              },
            );
          },
          child: const Text('Verifikasi sekarang'),
        ),
      ],
    ),
  );
}
