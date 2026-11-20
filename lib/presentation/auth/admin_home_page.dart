import 'package:compro_builder/core/config/env.dart';
import 'package:compro_builder/core/helper/link_opener.dart';
import 'package:compro_builder/data/datasources/sections_local_datasource.dart';
import 'package:compro_builder/data/model/response/auth_response_model.dart';
import 'package:compro_builder/presentation/auth/bloc/logout/logout_bloc.dart';
import 'package:compro_builder/presentation/auth/login_page.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/bottom_navbar/main_shell_page.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Layar pertama untuk akun admin platform. Panel admin lengkap ada di web
/// (`/admin`); dari sini admin membukanya di browser, atau lanjut memakai
/// situs miliknya sendiri di aplikasi.
class AdminHomePage extends StatelessWidget {
  final UserModel user;
  const AdminHomePage({super.key, required this.user});

  static void openReplacing(BuildContext context, UserModel user) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AdminHomePage(user: user)),
      (_) => false,
    );
  }

  Future<void> _openAdminPanel(BuildContext context) async {
    final ok = await openExternalLink(Uri.parse('${Env.siteBaseUrl}/admin'));
    if (!ok && context.mounted) {
      showToast('Tidak bisa membuka panel admin.', kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<LogoutBloc, LogoutState>(
      listener: (context, state) {
        state.whenOrNull(
          success: () {
            context.read<SitesBloc>().add(const SitesEvent.reset());
            SectionsLocalDatasource().clearAll().ignore();
            LoginPage.openReplacing(context);
          },
        );
      },
      builder: (context, state) {
        final loggingOut = state.maybeWhen(loading: () => true, orElse: () => false);
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BrandBadge(
                          icon: Icons.admin_panel_settings_rounded, size: 72),
                      const SizedBox(height: 16),
                      Text(
                        'Halo, ${user.name}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kamu masuk sebagai admin platform.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        onPressed: loggingOut ? null : () => _openAdminPanel(context),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Buka panel admin'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        onPressed: loggingOut
                            ? null
                            : () => MainShellPage.openReplacing(context, user),
                        icon: const Icon(Icons.web_rounded),
                        label: const Text('Situs saya'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: loggingOut
                            ? null
                            : () => context.read<LogoutBloc>().add(const LogoutEvent.logout()),
                        child: Text(loggingOut ? 'Keluar...' : 'Keluar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
