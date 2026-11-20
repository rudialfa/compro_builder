import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:dartz/dartz.dart';

class SitesRemoteDatasource {
  static const _base = '/me';

  // ─── GET /me/tenants  ({data: [tenantSummary]}) ────────────────────────────
  Future<Either<ApiFailure, TenantsResponseModel>> tenants() =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.get(
          ApiHelper.uri('$_base/tenants'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(TenantsResponseModel.fromJson(response.body));
        }
        return Left(ApiHelper.failure(
          response,
          fallback: 'Gagal memuat daftar situs.',
        ));
      });
}
