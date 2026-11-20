import 'package:compro_builder/core/config/env.dart';
import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/core/helper/app_keys.dart';
import 'package:compro_builder/core/helper/deep_link_service.dart';
import 'package:compro_builder/core/utils/reset_link.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:compro_builder/data/datasources/auth_local_datasource.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/data/datasources/sections_local_datasource.dart';
import 'package:compro_builder/data/datasources/sites_local_datasource.dart';
import 'package:compro_builder/data/datasources/sites_remote_datasource.dart';
import 'package:compro_builder/presentation/auth/bloc/login/login_bloc.dart';
import 'package:compro_builder/presentation/auth/bloc/logout/logout_bloc.dart';
import 'package:compro_builder/presentation/auth/bloc/profile/profile_bloc.dart';
import 'package:compro_builder/presentation/auth/bloc/register/register_bloc.dart';
import 'package:compro_builder/presentation/auth/login_page.dart';
import 'package:compro_builder/presentation/auth/reset_password_page.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/splash_page.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final configError = Env.validate();
  if (configError != null) {
    runApp(_ConfigErrorApp(message: configError));
    return;
  }

  runApp(const ComproBuilderApp());
}

/// Akar aplikasi: Bloc global + MaterialApp berbasis Navigator.
/// Bloc detail/editor (Fase 3+) dibuat per halaman, bukan di sini.
class ComproBuilderApp extends StatefulWidget {
  const ComproBuilderApp({super.key});

  @override
  State<ComproBuilderApp> createState() => _ComproBuilderAppState();
}

class _ComproBuilderAppState extends State<ComproBuilderApp> {
  final _authRemote = AuthRemoteDatasource();
  final _authLocal = AuthLocalDatasource();

  /// Global karena halaman yang ditumpuk lewat Navigator berada di luar pohon shell.
  late final SitesBloc _sitesBloc = SitesBloc(
    SitesRemoteDatasource(),
    SitesLocalDatasource(),
  );

  @override
  void initState() {
    super.initState();
    ApiHelper.sessionExpired.addListener(_onSessionExpired);
    DeepLinkService.instance.start(
      onReset: _openResetLink,
      onVerifyLink: _verifyFromLink,
    );
  }

  /// Tautan atur ulang password saat aplikasi sudah berjalan.
  void _openResetLink(ResetLinkInput input) {
    AppKeys.navigator.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(initialLink: input, fromLink: true),
      ),
    );
  }

  /// Tautan verifikasi dari email membuka app langsung (App Links): verifikasi lewat
  /// server lalu beri tahu layar Akun lewat verifiedTick.
  Future<void> _verifyFromLink(Uri link) async {
    final result = await _authRemote.verifyViaLink(link);
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
  }

  @override
  void dispose() {
    ApiHelper.sessionExpired.removeListener(_onSessionExpired);
    DeepLinkService.instance.dispose();
    _sitesBloc.close();
    super.dispose();
  }

  /// Server menjawab 401 pada request ber-token (token sudah dihapus oleh
  /// ApiHelper.guard): kembali ke layar masuk dan kosongkan tumpukan halaman.
  void _onSessionExpired() {
    _sitesBloc.add(const SitesEvent.reset());
    SectionsLocalDatasource().clearAll().ignore();
    final navigator = AppKeys.navigator.currentState;
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
    final messengerContext = AppKeys.messenger.currentContext;
    showToast(
      messengerContext != null
          ? messengerContext.l10n.sessionExpired
          : 'Sesi berakhir. Silakan masuk kembali.',
      kind: ToastKind.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LoginBloc(_authRemote, _authLocal)),
        BlocProvider(create: (_) => LogoutBloc(_authRemote, _authLocal)),
        BlocProvider(create: (_) => ProfileBloc(_authRemote)),
        BlocProvider(create: (_) => RegisterBloc(_authRemote, _authLocal)),
        BlocProvider<SitesBloc>.value(value: _sitesBloc),
      ],
      child: MaterialApp(
        navigatorKey: AppKeys.navigator,
        scaffoldMessengerKey: AppKeys.messenger,
        onGenerateTitle: (context) => context.l10n.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        locale: const Locale('id'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const SplashPage(),
      ),
    );
  }
}

/// Ditampilkan bila API_BASE_URL belum/keliru diatur (bukan galat pengguna akhir).
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(message, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
