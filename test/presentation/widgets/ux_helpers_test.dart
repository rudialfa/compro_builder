import 'package:compro_builder/core/helper/app_keys.dart';
import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:compro_builder/l10n/gen/app_localizations.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget Function(BuildContext) body) {
  return MaterialApp(
    theme: AppTheme.light(),
    scaffoldMessengerKey: AppKeys.messenger,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('id'),
    home: Scaffold(body: Builder(builder: body)),
  );
}

void main() {
  group('showConfirmDialog', () {
    testWidgets('mengembalikan true saat tombol aksi ditekan', (tester) async {
      bool? result;
      await tester.pumpWidget(_host((context) => TextButton(
            onPressed: () async {
              result = await showConfirmDialog(
                context,
                title: 'Hapus?',
                message: 'Tidak bisa dibatalkan.',
                confirmLabel: 'Hapus',
                destructive: true,
              );
            },
            child: const Text('buka'),
          )));
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus?'), findsOneWidget);
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('mengembalikan false saat Batal ditekan', (tester) async {
      bool? result;
      await tester.pumpWidget(_host((context) => TextButton(
            onPressed: () async {
              result = await showConfirmDialog(
                context,
                title: 'Keluar?',
                message: 'Anda perlu masuk lagi.',
                confirmLabel: 'Keluar',
              );
            },
            child: const Text('buka'),
          )));
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });

  group('showToast', () {
    testWidgets('menampilkan pesan galat', (tester) async {
      await tester.pumpWidget(_host((_) => const SizedBox()));
      showToast('Gagal memuat', kind: ToastKind.error);
      await tester.pump();
      expect(find.text('Gagal memuat'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('pesan baru menggantikan yang lama', (tester) async {
      await tester.pumpWidget(_host((_) => const SizedBox()));
      showToast('Pertama');
      await tester.pump();
      showToast('Kedua', kind: ToastKind.success);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Kedua'), findsOneWidget);
    });
  });

  group('LoadingButton', () {
    testWidgets('nonaktif dan menampilkan spinner saat loading',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host((_) => LoadingButton(
            label: 'Simpan',
            loading: true,
            onPressed: () => taps++,
          )));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Simpan'), findsNothing);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
    });

    testWidgets('memanggil onPressed saat tidak loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host((_) => LoadingButton(
            label: 'Simpan',
            onPressed: () => taps++,
          )));
      await tester.tap(find.text('Simpan'));
      expect(taps, 1);
    });
  });

  testWidgets('SkeletonList menampilkan jumlah blok yang diminta',
      (tester) async {
    await tester.pumpWidget(_host((_) => const SkeletonList(count: 3)));
    await tester.pump();
    expect(find.byType(SkeletonBox), findsNWidgets(3));
  });
}
