import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/model/request/onboarding_request_model.dart';
import 'package:compro_builder/data/model/response/onboarding_response_model.dart';
import 'package:compro_builder/data/model/response/site_status_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:dartz/dartz.dart';

/// Pengaturan awal situs: /{slug}/manage/onboarding (+ /skip).
class OnboardingRemoteDatasource {
  static TenantModel _tenantFrom(String body) {
    final tenant = SiteStatusResponseModel.fromJson(body).tenant;
    if (tenant == null) throw const FormatException('Respons situs tidak valid');
    return tenant;
  }

  // ─── GET /{slug}/manage/onboarding  ({data: {needed, state, values, themes}}) ─
  Future<Either<ApiFailure, OnboardingResponseModel>> show(String slug) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.get(
          ApiHelper.uri('/${Uri.encodeComponent(slug)}/manage/onboarding'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(OnboardingResponseModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(
            response,
            fallback: 'Gagal memuat pengaturan awal.',
          ),
        );
      });

  // ─── POST /{slug}/manage/onboarding  ({data: tenantSummary}) ────────────────
  /// Mengisi hero + kontak + warna dalam satu transaksi. 422 membawa
  /// fieldErrors (name, subtitle, whatsapp, theme) atau `onboarding`.
  Future<Either<ApiFailure, TenantModel>> submit(
    String slug,
    OnboardingRequestModel request,
  ) => ApiHelper.guard(() async {
    final response = await ApiHelper.client.post(
      ApiHelper.uri('/${Uri.encodeComponent(slug)}/manage/onboarding'),
      headers: await ApiHelper.headers(),
      body: request.toJson(),
    );
    if (response.statusCode == 200) return Right(_tenantFrom(response.body));
    return Left(
      ApiHelper.failure(response, fallback: 'Gagal menyimpan pengaturan awal.'),
    );
  });

  // ─── POST /{slug}/manage/onboarding/skip  ({data: tenantSummary}) ───────────
  Future<Either<ApiFailure, TenantModel>> skip(String slug) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.post(
          ApiHelper.uri('/${Uri.encodeComponent(slug)}/manage/onboarding/skip'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(_tenantFrom(response.body));
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal melewati pengaturan awal.'),
        );
      });
}
