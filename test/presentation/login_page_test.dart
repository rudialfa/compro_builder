import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:compro_builder/data/datasources/auth_local_datasource.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/data/model/request/login_request_model.dart';
import 'package:compro_builder/data/model/response/auth_response_model.dart';
import 'package:compro_builder/l10n/gen/app_localizations.dart';
import 'package:compro_builder/presentation/auth/bloc/login/login_bloc.dart';
import 'package:compro_builder/presentation/auth/bloc/register/register_bloc.dart';
import 'package:compro_builder/presentation/auth/login_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote extends AuthRemoteDatasource {
  final ApiFailure failure;
  _FakeRemote(this.failure);

  @override
  Future<Either<ApiFailure, AuthResponseModel>> login(
          LoginRequestModel request) async =>
      Left(failure);
}

Widget _app(AuthRemoteDatasource remote) {
  final local = AuthLocalDatasource();
  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => LoginBloc(remote, local)),
      BlocProvider(create: (_) => RegisterBloc(remote, local)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const LoginPage(),
    ),
  );
}

Future<void> _fillAndSubmit(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'demo@test.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'password');
  await tester.tap(find.text('Masuk'));
  await tester.pump(); // proses event bloc
  await tester.pump(); // render state hasil
}

void main() {
  testWidgets('form kosong menampilkan pesan validasi lokal', (tester) async {
    await tester.pumpWidget(_app(AuthRemoteDatasource()));

    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Password wajib diisi.'), findsOneWidget);
  });

  testWidgets('galat 422 tampil di bawah field terkait', (tester) async {
    await tester.pumpWidget(_app(_FakeRemote(const ApiFailure(
      'Email atau password salah.',
      statusCode: 422,
      fieldErrors: {
        'email': ['Email atau password salah.'],
      },
    ))));

    await _fillAndSubmit(tester);

    expect(find.text('Email atau password salah.'), findsOneWidget);
  });

  testWidgets('429 menonaktifkan tombol sementara', (tester) async {
    await tester.pumpWidget(_app(_FakeRemote(const ApiFailure(
      'Terlalu banyak percobaan. Coba lagi beberapa saat.',
      statusCode: 429,
      retryAfter: 30,
    ))));

    await _fillAndSubmit(tester);

    expect(find.text('Coba lagi dalam 30 dtk'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    // Lepas halaman agar Timer cooldown dibatalkan sebelum test selesai.
    await tester.pumpWidget(const SizedBox());
  });
}
