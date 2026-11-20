import 'dart:convert';

import 'package:compro_builder/core/constants/variables.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/model/request/login_request_model.dart';
import 'package:compro_builder/data/model/request/register_request_model.dart';
import 'package:compro_builder/data/model/request/reset_password_request_model.dart';
import 'package:compro_builder/data/model/response/account_message_model.dart';
import 'package:compro_builder/data/model/response/auth_response_model.dart';
import 'package:dartz/dartz.dart';

class AuthRemoteDatasource {
  static const _base = '/auth';

  // ─── POST /auth/login  (throttle 5/menit; token disimpan oleh bloc) ────────
  Future<Either<ApiFailure, AuthResponseModel>> login(
    LoginRequestModel request,
  ) =>
      ApiHelper.guard(authenticated: false, () async {
        final response = await ApiHelper.client.post(
          ApiHelper.uri('$_base/login'),
          headers: await ApiHelper.headers(auth: false),
          body: request.toJson(),
        );
        if (response.statusCode == 200) {
          return Right(AuthResponseModel.fromJson(response.body));
        }
        return Left(ApiHelper.failure(
          response,
          fallback: 'Gagal masuk. Silakan coba lagi.',
        ));
      });

  // ─── POST /auth/register  (201 -> {user, token}) ───────────────────────────
  Future<Either<ApiFailure, AuthResponseModel>> register(
    RegisterRequestModel request,
  ) =>
      ApiHelper.guard(authenticated: false, () async {
        final response = await ApiHelper.client.post(
          ApiHelper.uri('$_base/register'),
          headers: await ApiHelper.headers(auth: false),
          body: request.toJson(),
        );
        if (response.statusCode == 201 || response.statusCode == 200) {
          return Right(AuthResponseModel.fromJson(response.body));
        }
        return Left(ApiHelper.failure(
          response,
          fallback: 'Pendaftaran gagal. Silakan coba lagi.',
        ));
      });

  // ─── GET /auth/me  (objek user langsung) ───────────────────────────────────
  Future<Either<ApiFailure, UserModel>> me() => ApiHelper.guard(() async {
        final response = await ApiHelper.client.get(
          ApiHelper.uri('$_base/me'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(UserModel.fromJson(response.body));
        }
        return Left(ApiHelper.failure(response));
      });

  // ─── POST /auth/logout  (204; 401 dianggap sukses: sesi memang sudah mati) ─
  Future<Either<ApiFailure, Unit>> logout() =>
      ApiHelper.guard(authenticated: false, () async {
        final response = await ApiHelper.client.post(
          ApiHelper.uri('$_base/logout'),
          headers: await ApiHelper.headers(),
        );
        final code = response.statusCode;
        if (code == 204 || code == 200 || code == 401) {
          return const Right(unit);
        }
        return Left(ApiHelper.failure(response));
      });

  // ─── POST /auth/forgot-password  {email}  (200 {message}; 5/menit) ─────────
  /// Jawaban server selalu sama, ada atau tidaknya akun.
  Future<Either<ApiFailure, AccountMessageModel>> forgotPassword(
    String email,
  ) =>
      ApiHelper.guard(authenticated: false, () async {
        final response = await ApiHelper.client.post(
          ApiHelper.uri('$_base/forgot-password'),
          headers: await ApiHelper.headers(auth: false),
          body: jsonEncode({'email': email}),
        );
        if (response.statusCode == 200) {
          return Right(AccountMessageModel.fromJson(response.body));
        }
        return Left(ApiHelper.failure(
          response,
          fallback: 'Gagal mengirim tautan. Silakan coba lagi.',
        ));
      });

  // ─── POST /auth/reset-password  (200 {message}; 422 bila token salah) ──────
  Future<Either<ApiFailure, AccountMessageModel>> resetPassword(
    ResetPasswordRequestModel request,
  ) =>
      ApiHelper.guard(authenticated: false, () async {
        final response = await ApiHelper.client.post(
          ApiHelper.uri('$_base/reset-password'),
          headers: await ApiHelper.headers(auth: false),
          body: request.toJson(),
        );
        if (response.statusCode == 200) {
          return Right(AccountMessageModel.fromJson(response.body));
        }
        return Left(ApiHelper.failure(
          response,
          fallback: 'Gagal mengatur ulang password. Silakan coba lagi.',
        ));
      });

  // ─── POST /auth/email/verification-notification  (200 {message, verified}) ─
  /// Butuh token. 503 bila server gagal mengirim email; 429 setelah 3x/menit.
  Future<Either<ApiFailure, AccountMessageModel>> resendVerification() =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.post(
          ApiHelper.uri('$_base/email/verification-notification'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(AccountMessageModel.fromJson(response.body));
        }
        return Left(ApiHelper.failure(
          response,
          fallback: 'Email belum bisa dikirim. Coba lagi sebentar lagi.',
        ));
      });

  // ─── GET {tautan bertanda tangan dari email}  (Accept: application/json) ───
  /// Tanpa token: keamanannya dari tanda tangan URL + hash email di server.
  /// Hanya tautan dari host server aplikasi ini yang diproses.
  Future<Either<ApiFailure, AccountMessageModel>> verifyViaLink(Uri link) async {
    final serverHost = Uri.tryParse(Variables.siteBaseUrl)?.host ?? '';
    if (serverHost.isEmpty || link.host != serverHost) {
      return const Left(ApiFailure(
        'Tautan verifikasi ini bukan dari server aplikasi.',
      ));
    }
    return ApiHelper.guard(authenticated: false, () async {
      final response = await ApiHelper.client.get(
        link,
        headers: await ApiHelper.headers(json: false, auth: false),
      );
      if (response.statusCode == 200) {
        return Right(AccountMessageModel.fromJson(response.body));
      }
      return Left(ApiHelper.failure(
        response,
        fallback: 'Tautan verifikasi tidak valid atau sudah kedaluwarsa. '
            'Kirim ulang dari menu Akun.',
      ));
    });
  }

  // ─── GET /auth/email/dev-verify-link  (HANYA server uji) ───────────────────
  /// Tautan verifikasi tanpa mengirim email. null bila fitur mati di server
  /// (404), sudah terverifikasi, atau server sungguhan.
  Future<Either<ApiFailure, String?>> devVerifyLink() =>
      ApiHelper.guard<String?>(() async {
        final response = await ApiHelper.client.get(
          ApiHelper.uri('$_base/email/dev-verify-link'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 404) {
          return const Right<ApiFailure, String?>(null);
        }
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final url = decoded is Map ? decoded['dev_verify_url'] : null;
          return Right<ApiFailure, String?>(
            url is String && url.isNotEmpty ? url : null,
          );
        }
        return Left<ApiFailure, String?>(ApiHelper.failure(response));
      });
}
