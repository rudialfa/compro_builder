import 'dart:convert';

import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/model/response/site_status_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/data/model/response/theme_response_model.dart';
import 'package:dartz/dartz.dart';

/// Warna situs: /{slug}/manage/themes dan /{slug}/manage/theme.
class ThemeRemoteDatasource {
  // ─── GET /{slug}/manage/themes  ({data: {current, themes: [...]}}) ──────────
  Future<Either<ApiFailure, ThemesResponseModel>> list(String slug) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.get(
          ApiHelper.uri('/${Uri.encodeComponent(slug)}/manage/themes'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(ThemesResponseModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal memuat pilihan warna.'),
        );
      });

  // ─── PUT /{slug}/manage/theme  {theme: code}  ({data: tenantSummary}) ───────
  /// 422 bila kode tema tidak dikenal; 403 bila bukan pemilik.
  Future<Either<ApiFailure, TenantModel>> update(String slug, String code) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.put(
          ApiHelper.uri('/${Uri.encodeComponent(slug)}/manage/theme'),
          headers: await ApiHelper.headers(),
          body: jsonEncode({'theme': code}),
        );
        if (response.statusCode == 200) {
          final tenant = SiteStatusResponseModel.fromJson(response.body).tenant;
          if (tenant == null) {
            throw const FormatException('Respons situs tidak valid');
          }
          return Right(tenant);
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal mengubah warna situs.'),
        );
      });
}
