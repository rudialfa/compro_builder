import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/auth_remote_datasource.dart';
import 'package:compro_builder/data/model/request/reset_password_request_model.dart';
import 'package:compro_builder/data/model/response/account_message_model.dart';
import 'package:compro_builder/presentation/auth/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:compro_builder/presentation/auth/bloc/reset_password/reset_password_bloc.dart';
import 'package:compro_builder/presentation/auth/bloc/verify_email/verify_email_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements AuthRemoteDatasource {}

const _request = ResetPasswordRequestModel(
  token: 'tok',
  email: 'a@b.com',
  password: 'password-baru',
  passwordConfirmation: 'password-baru',
);

void main() {
  late MockRemote remote;
  setUp(() => remote = MockRemote());

  setUpAll(() => registerFallbackValue(_request));

  group('ForgotPasswordBloc', () {
    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'sukses: loading lalu sent(pesan server)',
      setUp: () => when(() => remote.forgotPassword('a@b.com')).thenAnswer(
        (_) async => const Right(AccountMessageModel(message: 'Cek email.')),
      ),
      build: () => ForgotPasswordBloc(remote),
      act: (b) => b.add(const ForgotPasswordEvent.submit('a@b.com')),
      expect: () => [
        const ForgotPasswordState.loading(),
        const ForgotPasswordState.sent('Cek email.'),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      '429 -> error dengan retryAfter',
      setUp: () => when(() => remote.forgotPassword(any())).thenAnswer(
        (_) async => const Left(ApiFailure('tunggu', statusCode: 429, retryAfter: 30)),
      ),
      build: () => ForgotPasswordBloc(remote),
      act: (b) => b.add(const ForgotPasswordEvent.submit('a@b.com')),
      expect: () => [
        const ForgotPasswordState.loading(),
        predicate<ForgotPasswordState>(
          (s) => s.maybeWhen(
            error: (f) => f.isRateLimited && f.retryAfter == 30,
            orElse: () => false,
          ),
        ),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'submit ganda saat loading: hanya satu panggilan jaringan',
      setUp: () => when(() => remote.forgotPassword('a@b.com')).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const Right(AccountMessageModel(message: 'ok'));
      }),
      build: () => ForgotPasswordBloc(remote),
      act: (b) {
        b.add(const ForgotPasswordEvent.submit('a@b.com'));
        b.add(const ForgotPasswordEvent.submit('a@b.com'));
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) => verify(() => remote.forgotPassword('a@b.com')).called(1),
    );
  });

  group('ResetPasswordBloc', () {
    blocTest<ResetPasswordBloc, ResetPasswordState>(
      'sukses: loading lalu success(pesan server)',
      setUp: () => when(() => remote.resetPassword(any())).thenAnswer(
        (_) async => const Right(AccountMessageModel(message: 'Password berhasil diganti.')),
      ),
      build: () => ResetPasswordBloc(remote),
      act: (b) => b.add(const ResetPasswordEvent.submit(_request)),
      expect: () => [
        const ResetPasswordState.loading(),
        const ResetPasswordState.success('Password berhasil diganti.'),
      ],
    );

    blocTest<ResetPasswordBloc, ResetPasswordState>(
      '422 token salah -> error dengan galat field email',
      setUp: () => when(() => remote.resetPassword(any())).thenAnswer(
        (_) async => const Left(
          ApiFailure(
            'Tautan tidak valid.',
            statusCode: 422,
            fieldErrors: {
              'email': ['Tautan tidak valid.'],
            },
          ),
        ),
      ),
      build: () => ResetPasswordBloc(remote),
      act: (b) => b.add(const ResetPasswordEvent.submit(_request)),
      expect: () => [
        const ResetPasswordState.loading(),
        predicate<ResetPasswordState>(
          (s) => s.maybeWhen(
            error: (f) => f.errorFor('email') == 'Tautan tidak valid.',
            orElse: () => false,
          ),
        ),
      ],
    );
  });

  group('VerifyEmailBloc', () {
    blocTest<VerifyEmailBloc, VerifyEmailState>(
      'sukses: sent membawa message + verified',
      setUp: () => when(() => remote.resendVerification()).thenAnswer(
        (_) async => const Right(
          AccountMessageModel(message: 'Terkirim.', verified: false),
        ),
      ),
      build: () => VerifyEmailBloc(remote),
      act: (b) => b.add(const VerifyEmailEvent.resend()),
      expect: () => [
        const VerifyEmailState.loading(),
        predicate<VerifyEmailState>(
          (s) => s.maybeWhen(
            sent: (r) => r.message == 'Terkirim.' && r.verified == false,
            orElse: () => false,
          ),
        ),
      ],
    );

    blocTest<VerifyEmailBloc, VerifyEmailState>(
      '503 -> error',
      setUp: () => when(() => remote.resendVerification()).thenAnswer(
        (_) async => const Left(ApiFailure('Email belum bisa dikirim.', statusCode: 503)),
      ),
      build: () => VerifyEmailBloc(remote),
      act: (b) => b.add(const VerifyEmailEvent.resend()),
      expect: () => [
        const VerifyEmailState.loading(),
        predicate<VerifyEmailState>(
          (s) => s.maybeWhen(error: (f) => f.statusCode == 503, orElse: () => false),
        ),
      ],
    );
  });
}
