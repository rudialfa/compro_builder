import 'dart:convert';

import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/model/response/template_response_model.dart';
import 'package:compro_builder/data/model/response/template_update_response_model.dart';
import 'package:dartz/dartz.dart';

/// Template tampilan: /{slug}/manage/templates, /template, dan preview-link.
class TemplateRemoteDatasource {
  String _base(String slug) => '/${Uri.encodeComponent(slug)}/manage';

  // ─── GET /{slug}/manage/templates  ({data: {active, chosen, templates}}) ────
  Future<Either<ApiFailure, TemplatesResponseModel>> list(String slug) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.get(
          ApiHelper.uri('${_base(slug)}/templates'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(TemplatesResponseModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal memuat daftar template.'),
        );
      });

  // ─── PUT /{slug}/manage/template  {template: code} ──────────────────────────
  /// 403 `template_locked` bila paket belum cukup (pesan server memuat nama
  /// paket); 422 bila kode tidak dikenal.
  Future<Either<ApiFailure, TemplateUpdateResponseModel>> update(
    String slug,
    String code,
  ) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.put(
          ApiHelper.uri('${_base(slug)}/template'),
          headers: await ApiHelper.headers(),
          body: jsonEncode({'template': code}),
        );
        if (response.statusCode == 200) {
          return Right(TemplateUpdateResponseModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal mengganti template.'),
        );
      });

  // ─── POST /{slug}/manage/templates/{code}/preview-link ──────────────────────
  /// URL bertanda tangan 10 menit; template terkunci boleh dipratinjau.
  Future<Either<ApiFailure, PreviewLinkModel>> previewLink(
    String slug,
    String code,
  ) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.post(
          ApiHelper.uri(
            '${_base(slug)}/templates/${Uri.encodeComponent(code)}/preview-link',
          ),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(PreviewLinkModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal membuat tautan pratinjau.'),
        );
      });
}
