import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/model/response/plan_info_model.dart';
import 'package:dartz/dartz.dart';

/// Paket situs: /{slug}/manage/plan (pembayaran dilakukan lewat web).
class PlanRemoteDatasource {
  // ─── GET /{slug}/manage/plan  ({data: {code,name,level,expires_at,price,limits,upgrade_url}}) ─
  Future<Either<ApiFailure, PlanInfoModel>> get(String slug) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.get(
          ApiHelper.uri('/${Uri.encodeComponent(slug)}/manage/plan'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(PlanInfoModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal memuat data paket.'),
        );
      });
}
