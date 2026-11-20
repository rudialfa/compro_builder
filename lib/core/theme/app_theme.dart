import 'package:flutter/material.dart';

/// Tema Material 3 (terang/gelap) mengikuti pengaturan sistem.
///
/// Palet mengikuti web: indigo `#1d2b5f` (brand) dan kunyit `#f5b400` (aksen).
/// Peran warna yang dipakai teks/tombol ditetapkan eksplisit supaya kontras
/// aman (WCAG AA >= 4,5:1; lihat test/core/theme/app_theme_test.dart). Peran
/// lain (permukaan turunan, outlineVariant, dll.) tetap dari seed indigo.
class AppTheme {
  AppTheme._();

  /// Brand web.
  static const indigo = Color(0xFF1D2B5F);

  /// Aksen web.
  static const kunyit = Color(0xFFF5B400);

  // ── Token tambahan untuk komponen desain baru (hanya tampilan) ──
  /// Ujung gelap & terang gradasi hero.
  static const heroDeep = Color(0xFF16224F);
  static const heroLight = Color(0xFF3B4FA8);

  /// Warna aksen ikon-chip (latar transparan + ikon senada).
  static const blue = Color(0xFF2F80ED);
  static const violet = Color(0xFF7C5CFC);
  static const teal = Color(0xFF12B5A0);
  static const tealDeep = Color(0xFF0F8A7A);
  static const rose = Color(0xFFE5566D);
  static const kunyitDeep = Color(0xFF7A5900);

  static const radiusTile = 22.0; // kartu statistik / menu
  static const radiusHero = 26.0; // kartu hero bergradasi

  /// Bayangan lembut kartu (mode terang saja; mode gelap memakai garis tepi).
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: indigo.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: indigo.withValues(alpha: 0.04),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  static ThemeData light() => _build(_lightScheme());
  static ThemeData dark() => _build(_darkScheme());

  static ColorScheme _lightScheme() =>
      ColorScheme.fromSeed(seedColor: indigo, brightness: Brightness.light)
          .copyWith(
            primary: indigo,
            onPrimary: const Color(0xFFFFFFFF),
            primaryContainer: const Color(0xFFDCE2F9),
            onPrimaryContainer: const Color(0xFF0A1233),
            // Kunyit pekat untuk teks/ikon di atas terang; kunyit asli dipakai
            // sebagai tertiary (latar) dengan teks indigo.
            secondary: const Color(0xFF7A5900),
            onSecondary: const Color(0xFFFFFFFF),
            secondaryContainer: const Color(0xFFFFDF8F),
            onSecondaryContainer: const Color(0xFF251A00),
            tertiary: kunyit,
            onTertiary: indigo,
            tertiaryContainer: const Color(0xFFFFEBB3),
            onTertiaryContainer: const Color(0xFF3B2A00),
            surface: const Color(0xFFFAFBFF),
            onSurface: const Color(0xFF1A1C24),
            onSurfaceVariant: const Color(0xFF444958),
            outline: const Color(0xFF737888),
            surfaceContainerHighest: const Color(0xFFE1E4F0),
          );

  static ColorScheme _darkScheme() =>
      ColorScheme.fromSeed(seedColor: indigo, brightness: Brightness.dark)
          .copyWith(
            primary: const Color(0xFFB8C5FF),
            onPrimary: const Color(0xFF0F1C4D),
            primaryContainer: const Color(0xFF2A3A78),
            onPrimaryContainer: const Color(0xFFDCE2FF),
            secondary: kunyit,
            onSecondary: const Color(0xFF3B2A00),
            secondaryContainer: const Color(0xFF574100),
            onSecondaryContainer: const Color(0xFFFFDF8F),
            tertiary: const Color(0xFFFFD15E),
            onTertiary: const Color(0xFF3B2A00),
            tertiaryContainer: const Color(0xFF4F3B00),
            onTertiaryContainer: const Color(0xFFFFEBB3),
            surface: const Color(0xFF11131B),
            onSurface: const Color(0xFFE3E4EE),
            onSurfaceVariant: const Color(0xFFC4C8D8),
            outline: const Color(0xFF8E93A5),
            surfaceContainerHighest: const Color(0xFF2E3039),
          );

  /// Keluarga huruf (dibundel di assets/fonts, lihat pubspec.yaml).
  static const fontFamily = 'PlusJakartaSans';

  /// Latar halaman mode terang (abu kebiruan lembut, sama dengan web).
  static const paper = Color(0xFFF4F6FA);

  // Skala sudut desain baru.
  static const radiusControl = 14.0; // tombol, input
  static const radiusCard = 20.0; // kartu
  static const radiusSheet = 24.0; // bottom sheet, dialog besar

  static ThemeData _build(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final scaffold = isLight ? paper : scheme.surface;
    final cardColor = isLight ? Colors.white : scheme.surfaceContainer;
    final control = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusControl),
    );
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.6),
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineSmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        titleSmall: TextStyle(fontWeight: FontWeight.w700),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
        labelMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 1.5,
        shadowColor: AppTheme.indigo.withValues(alpha: 0.28),
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(scheme.outlineVariant),
        enabledBorder: border(scheme.outlineVariant),
        focusedBorder: border(scheme.primary, 2),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 2),
      ),
      // Target sentuh minimal 48dp.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: control,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: control,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: control,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusSheet)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearMinHeight: 6,
        borderRadius: BorderRadius.all(Radius.circular(9)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
      ),
    );
  }
}
