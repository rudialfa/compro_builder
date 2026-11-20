import 'dart:convert';

import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/model/response/site_status_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:dartz/dartz.dart';

/// Status tayang situs: /{slug}/manage/status.
class PublishRemoteDatasource {
  // ─── POST /{slug}/manage/status  {status: published|draft}  ({data: tenantSummary}) ─
  /// 403 = situs dinonaktifkan admin atau email belum terverifikasi (hanya saat
  /// menayangkan); 422 bila nilai status tidak valid. Pesan server dipertahankan
  /// di [ApiFailure.message] supaya UI bisa membedakan penyebab 403.
  Future<Either<ApiFailure, SiteStatusResponseModel>> setStatus(
    String slug,
    SiteStatus target,
  ) => ApiHelper.guard(() async {
    final value = switch (target) {
      SiteStatus.published => 'published',
      SiteStatus.draft => 'draft',
      SiteStatus.unknown => throw ArgumentError('Status tujuan tidak valid'),
    };
    final response = await ApiHelper.client.post(
      ApiHelper.uri('/${Uri.encodeComponent(slug)}/manage/status'),
      headers: await ApiHelper.headers(),
      body: jsonEncode({'status': value}),
    );
    if (response.statusCode == 200) {
      return Right(SiteStatusResponseModel.fromJson(response.body));
    }
    return Left(
      ApiHelper.failure(response, fallback: 'Gagal mengubah status situs.'),
    );
  });
}
