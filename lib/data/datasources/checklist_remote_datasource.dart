import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/model/response/checklist_response_model.dart';
import 'package:dartz/dartz.dart';

/// Kelengkapan situs + syarat tayang: /{slug}/manage/checklist.
class ChecklistRemoteDatasource {
  // ─── GET /{slug}/manage/checklist  ({data: {percent, items, publish, ...}}) ─
  Future<Either<ApiFailure, ChecklistResponseModel>> get(String slug) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.get(
          ApiHelper.uri('/${Uri.encodeComponent(slug)}/manage/checklist'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(ChecklistResponseModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal memuat kelengkapan situs.'),
        );
      });
}
