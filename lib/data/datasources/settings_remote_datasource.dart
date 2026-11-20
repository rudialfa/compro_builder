import 'dart:convert';

import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/model/request/section_payload.dart';
import 'package:compro_builder/data/model/request/settings_changes_model.dart';
import 'package:compro_builder/data/model/response/site_settings_model.dart';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;

/// Pengaturan satu situs: /{slug}/manage/settings.
class SettingsRemoteDatasource {
  static String _path(String slug) =>
      '/${Uri.encodeComponent(slug)}/manage/settings';

  // ─── GET /{slug}/manage/settings  ({data: {...}}) ─────────────────────────
  Future<Either<ApiFailure, SiteSettingsModel>> get(String slug) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.get(
          ApiHelper.uri(_path(slug)),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(SiteSettingsModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal memuat pengaturan.'),
        );
      });

  // ─── PUT|POST /{slug}/manage/settings  (balasan = pengaturan terbaru) ──────
  /// PUT JSON bila tanpa berkas; POST multipart bila ada logo/favicon baru.
  /// Penghapusan gambar (`logo_remove`) cukup lewat JSON.
  Future<Either<ApiFailure, SiteSettingsModel>> save(
    String slug,
    SettingsChangesModel changes,
  ) => ApiHelper.guard(() async {
    final uri = ApiHelper.uri(_path(slug));
    final payload = changes.toMap();
    final flat = flattenPayload(payload);
    final http.Response response;
    if (flat.files.isEmpty) {
      response = await ApiHelper.client.put(
        uri,
        headers: await ApiHelper.headers(),
        body: jsonEncode(payload),
      );
    } else {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(await ApiHelper.headers(json: false))
        ..fields.addEntries(flat.fields);
      for (final f in flat.files) {
        request.files.add(
          http.MultipartFile.fromBytes(
            f.key,
            f.value.bytes,
            filename: f.value.filename,
          ),
        );
      }
      response = await http.Response.fromStream(
        await ApiHelper.client.send(request),
      );
    }
    if (response.statusCode == 200) {
      return Right(SiteSettingsModel.fromJson(response.body));
    }
    return Left(
      ApiHelper.failure(response, fallback: 'Gagal menyimpan pengaturan.'),
    );
  });
}
