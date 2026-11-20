import 'package:compro_builder/core/constants/variables.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/data/datasources/auth_local_datasource.dart';
import 'package:compro_builder/presentation/auth/bloc/profile/profile_bloc.dart';
import 'package:compro_builder/presentation/auth/login_page.dart';
import 'package:compro_builder/presentation/auth/post_auth_route.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Layar awal: cek token tersimpan, validasi lewat GET /auth/me,
/// lalu arahkan ke cangkang utama atau layar masuk.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = await AuthLocalDatasource().getToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      LoginPage.openReplacing(context);
      return;
    }
    context.read<ProfileBloc>().add(const ProfileEvent.load());
  }

  Future<void> _logoutLocal() async {
    await AuthLocalDatasource().removeToken();
    if (mounted) LoginPage.openReplacing(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          // 401 ditangani global (ApiHelper.sessionExpired -> layar masuk).
          state.whenOrNull(
            loaded: (user) => openAfterAuth(context, user),
          );
        },
        builder: (context, state) {
          final failure = state.whenOrNull(error: (f) => f);
          if (failure != null && !failure.isUnauthorized) {
            return SafeArea(
              child: ErrorView(
                message: failure.message,
                onRetry: () =>
                    context.read<ProfileBloc>().add(const ProfileEvent.load()),
                secondaryLabel: context.l10n.actionLogout,
                onSecondary: _logoutLocal,
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandBadge(icon: Icons.web_rounded, size: 72),
                const SizedBox(height: 16),
                Text(Variables.appName,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ),
          );
        },
      ),
    );
  }
}
