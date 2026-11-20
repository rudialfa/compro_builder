import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/utils/reset_link.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/data/model/response/account_message_model.dart';
import 'package:compro_builder/l10n/gen/app_localizations.dart';
import 'package:compro_builder/presentation/auth/forgot_password_page.dart';
import 'package:compro_builder/presentation/auth/reset_password_page.dart';
import 'package:compro_builder/presentation/widgets/resend_verification_button.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote extends AuthRemoteDatasource {
  int calls = 0;
  String? lastEmail;

  @override
  Future<Either<ApiFailure, AccountMessageModel>> forgotPassword(
    String email,
  ) async {
    calls++;
    lastEmail = email;
    return const Right(
      AccountMessageModel(message: 'Kalau email itu terdaftar, tautan sudah dikirim.'),
    );
  }
}

class _FakeResend extends AuthRemoteDatasource {
  final bool verified;
  int calls = 0;
  _FakeResend({required this.verified});

  @override
  Future<Either<ApiFailure, AccountMessageModel>> resendVerification() async {
    calls++;
    return Right(AccountMessageModel(message: 'Terkirim.', verified: verified));
  }
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('id'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

void main() {
  group('ForgotPasswordPage', () {
    testWidgets('email kosong -> validasi lokal, tanpa panggilan jaringan', (tester) async {
      final remote = _FakeRemote();
      await tester.pumpWidget(_app(ForgotPasswordPage(remote: remote)));

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Wajib diisi'), findsOneWidget);
      expect(remote.calls, 0);
    });

    testWidgets('email dari halaman masuk terisi otomatis', (tester) async {
      await tester.pumpWidget(
        _app(ForgotPasswordPage(initialEmail: 'a@b.com', remote: _FakeRemote())),
      );
      expect(find.text('a@b.com'), findsOneWidget);
    });

    testWidgets('sukses: pesan server tampil, tombol menunggu, ada jalan ke atur ulang', (tester) async {
      final remote = _FakeRemote();
      await tester.pumpWidget(_app(ForgotPasswordPage(remote: remote)));

      await tester.enterText(find.byType(TextFormField), '  a@b.com ');
      await tester.tap(find.byType(FilledButton));
      await tester.pump(); // proses event bloc
      await tester.pump(); // render hasil

      expect(remote.calls, 1);
      expect(remote.lastEmail, 'a@b.com');
      expect(find.text('Cek email Anda'), findsOneWidget);
      expect(
        find.text('Kalau email itu terdaftar, tautan sudah dikirim.'),
        findsOneWidget,
      );
      expect(find.text('Kirim ulang dalam 30 dtk'), findsOneWidget);
      expect(find.text('Saya sudah punya tautan atau kode'), findsOneWidget);

      // Lepas halaman agar Timer cooldown dibatalkan sebelum test selesai.
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('ResetPasswordPage', () {
    testWidgets('menempel tautan utuh mengisi email otomatis', (tester) async {
      await tester.pumpWidget(_app(const ResetPasswordPage()));

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'https://platform.com/reset-password/abc123?email=a%40b.com',
      );
      await tester.pump();

      expect(find.text('a@b.com'), findsOneWidget);
    });

    testWidgets('dibuka dari deep link: token dan email terisi otomatis',
        (tester) async {
      await tester.pumpWidget(
        _app(
          const ResetPasswordPage(
            initialLink: ResetLinkInput(token: 'tok9', email: 'x@y.id'),
            fromLink: true,
          ),
        ),
      );

      expect(find.text('tok9'), findsOneWidget);
      expect(find.text('x@y.id'), findsOneWidget);
    });

    testWidgets('konfirmasi password beda -> pesan validasi', (tester) async {
      await tester.pumpWidget(_app(const ResetPasswordPage()));

      await tester.enterText(find.byType(TextFormField).at(0), 'abc123');
      await tester.enterText(find.byType(TextFormField).at(1), 'a@b.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password-baru');
      await tester.enterText(find.byType(TextFormField).at(3), 'password-lain');
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Konfirmasi kata sandi tidak sama'), findsOneWidget);
    });
  });

  group('ResendVerificationButton', () {
    testWidgets('terkirim: tombol menunggu 30 dtk dan onVerified tidak dipanggil', (tester) async {
      final remote = _FakeResend(verified: false);
      var verifiedCalls = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: ResendVerificationButton(
              remote: remote,
              onVerified: () => verifiedCalls++,
            ),
          ),
        ),
      );

      expect(find.text('Kirim ulang tautan verifikasi'), findsOneWidget);
      // FilledButton.tonalIcon bertipe turunan: cari lewat teks.
      await tester.tap(find.text('Kirim ulang tautan verifikasi'));
      await tester.pump();
      await tester.pump();

      expect(remote.calls, 1);
      expect(verifiedCalls, 0);
      expect(find.text('Kirim ulang dalam 30 dtk'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('server menjawab sudah terverifikasi: onVerified dipanggil', (tester) async {
      final remote = _FakeResend(verified: true);
      var verifiedCalls = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: ResendVerificationButton(
              remote: remote,
              onVerified: () => verifiedCalls++,
            ),
          ),
        ),
      );

      // FilledButton.tonalIcon bertipe turunan: cari lewat teks.
      await tester.tap(find.text('Kirim ulang tautan verifikasi'));
      await tester.pump();
      await tester.pump();

      expect(verifiedCalls, 1);
      // Tidak ada jeda: tombol tetap bisa ditekan (tidak ada Timer tersisa).
      expect(find.text('Kirim ulang tautan verifikasi'), findsOneWidget);
    });
  });
}
