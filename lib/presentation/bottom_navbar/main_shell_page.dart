import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/data/datasources/sections_local_datasource.dart';
import 'package:compro_builder/data/model/response/auth_response_model.dart';
import 'package:compro_builder/presentation/auth/bloc/logout/logout_bloc.dart';
import 'package:compro_builder/presentation/auth/login_page.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/pages/account/account_page.dart';
import 'package:compro_builder/presentation/pages/dashboard/dashboard_page.dart';
import 'package:compro_builder/presentation/pages/onboarding/onboarding_page.dart';
import 'package:compro_builder/presentation/pages/sections/sections_page.dart';
import 'package:compro_builder/presentation/pages/sites/sites_page.dart';
import 'package:compro_builder/presentation/widgets/dev_verify_notice.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cangkang utama setelah masuk: bottom navbar.
/// Tab: 0 = Beranda (situs aktif), 1 = Situs, 2 = Section (situs aktif), 3 = Akun.
class MainShellPage extends StatefulWidget {
  final UserModel user;
  const MainShellPage({super.key, required this.user});

  static void openReplacing(BuildContext context, UserModel user) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainShellPage(user: user)),
      (_) => false,
    );
  }

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  static const _homeTab = 0;
  static const _sitesTab = 1;
  int _index = _homeTab;

  /// Dinaikkan saat bloc section lain (halaman Publikasi dari Beranda) mungkin
  /// mengubah section: tab Section dibangun ulang dan memuat data baru.
  int _sectionsEpoch = 0;

  /// Slug yang sudah ditawari pengaturan awal pada sesi ini (tampil sekali;
  /// bila ditutup tanpa memilih, kartu di Beranda tetap mengingatkan).
  final _onboardingOffered = <String>{};
  bool _onboardingOpen = false;

  Future<void> _loadDevVerifyNotice() async {
    final result = await AuthRemoteDatasource().devVerifyLink();
    if (!mounted) return;
    result.fold((_) {}, (url) {
      if (url != null) showDevVerifyNotice(url);
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<SitesBloc>().add(const SitesEvent.fetch());
    // Server uji: tampilkan tautan verifikasi sebagai notifikasi (tidak melakukan apa-apa di server sungguhan).
    if (!widget.user.isEmailVerified) _loadDevVerifyNotice();
  }

  /// Situs aktif yang `needs_onboarding` (data segar, bukan cache) -> buka wizard
  /// sekali. Tidak dibuka bila halaman lain sedang menutupi cangkang.
  void _maybeOfferOnboarding(BuildContext context, SitesState state) {
    final data = state.whenOrNull(loaded: (d) => d);
    final tenant = data?.activeTenant;
    if (data == null || tenant == null || data.fromCache) return;
    if (!tenant.needsOnboarding || _onboardingOpen) return;
    if (_onboardingOffered.contains(tenant.slug)) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _onboardingOffered.add(tenant.slug);
    _openOnboarding(context, tenant.slug);
  }

  Future<void> _openOnboarding(BuildContext context, String slug) async {
    _onboardingOpen = true;
    final saved = await OnboardingPage.open(context, slug: slug);
    _onboardingOpen = false;
    // Hero/kontak berubah di server: muat ulang tab Section.
    if (saved && mounted) setState(() => _sectionsEpoch++);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LogoutBloc, LogoutState>(
      listener: (context, state) {
        state.whenOrNull(
          success: () {
            // Kosongkan daftar situs + cache supaya tidak bocor ke pengguna berikutnya.
            context.read<SitesBloc>().add(const SitesEvent.reset());
            SectionsLocalDatasource().clearAll().ignore();
            LoginPage.openReplacing(context);
          },
        );
      },
      builder: (context, state) {
        final loggingOut = state.maybeWhen(
          loading: () => true,
          orElse: () => false,
        );
        if (loggingOut) {
          return Scaffold(
            body: LoadingView(message: context.l10n.shellLoggingOut),
          );
        }
        return BlocListener<SitesBloc, SitesState>(
          listener: _maybeOfferOnboarding,
          child: PopScope(
            canPop: _index == _homeTab,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) setState(() => _index = _homeTab);
            },
            child: Scaffold(
              body: IndexedStack(
                index: _index,
                children: [
                  DashboardPage(
                    onSwitchSite: () => setState(() => _index = _sitesTab),
                    onSectionsMayHaveChanged: () {
                      if (mounted) setState(() => _sectionsEpoch++);
                    },
                  ),
                  const SitesPage(),
                  _SectionsTab(epoch: _sectionsEpoch),
                  AccountPage(
                    user: widget.user,
                    onSwitchSite: () => setState(() => _index = _sitesTab),
                  ),
                ],
              ),
              bottomNavigationBar: _FloatingNavBar(
                child: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      selectedIcon: const Icon(Icons.dashboard),
                      label: context.l10n.dashboardTitle,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.storefront_outlined),
                      selectedIcon: const Icon(Icons.storefront),
                      label: context.l10n.shellTabSites,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.view_agenda_outlined),
                      selectedIcon: const Icon(Icons.view_agenda),
                      label: context.l10n.sectionsTitle,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline_rounded),
                      selectedIcon: const Icon(Icons.person_rounded),
                      label: context.l10n.shellTabAccount,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Tab Section: mengikuti situs aktif dari [SitesBloc]. `key` = slug supaya
/// berganti situs (atau [epoch] naik) membuat SectionsBloc baru.
class _SectionsTab extends StatelessWidget {
  final int epoch;
  const _SectionsTab({required this.epoch});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SitesBloc, SitesState>(
      builder: (context, state) {
        final tenant = state.maybeWhen(
          loaded: (data) => data.activeTenant,
          orElse: () => null,
        );
        if (tenant == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.sectionsTitle)),
            body: EmptyView(
              icon: Icons.storefront_outlined,
              title: context.l10n.dashboardNoSiteTitle,
              message: context.l10n.dashboardNoSiteMessage,
            ),
          );
        }
        return SectionsPage(
          key: ValueKey('${tenant.slug}#$epoch'),
          slug: tenant.slug,
          siteName: tenant.name,
        );
      },
    );
  }
}

/// Bilah navigasi melayang berbentuk pil. Hanya pembungkus tampilan: isinya
/// tetap [NavigationBar] dengan `selectedIndex` dan handler dari pemakai.
class _FloatingNavBar extends StatelessWidget {
  final NavigationBar child;
  const _FloatingNavBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    const radius = BorderRadius.all(Radius.circular(30));
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? scheme.surfaceContainer,
            borderRadius: radius,
            boxShadow: dark
                ? null
                : [
                    BoxShadow(
                      color: AppTheme.indigo.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
            border: dark
                ? Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6))
                : null,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Theme(
              data: theme.copyWith(
                navigationBarTheme: theme.navigationBarTheme.copyWith(
                  height: 64,
                  backgroundColor: Colors.transparent,
                  indicatorColor: scheme.primary,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      size: 24,
                      color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                    );
                  }),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
