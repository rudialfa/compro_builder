import 'package:compro_builder/data/model/response/auth_response_model.dart';
import 'package:compro_builder/presentation/auth/admin_home_page.dart';
import 'package:compro_builder/presentation/bottom_navbar/main_shell_page.dart';
import 'package:flutter/material.dart';

/// Tujuan setelah masuk (login atau sesi tersimpan di splash):
/// admin platform -> [AdminHomePage], pengguna biasa -> cangkang utama.
void openAfterAuth(BuildContext context, UserModel user) {
  if (user.isAdmin) {
    AdminHomePage.openReplacing(context, user);
  } else {
    MainShellPage.openReplacing(context, user);
  }
}
