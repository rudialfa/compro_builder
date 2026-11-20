import 'dart:convert';
import 'dart:typed_data';

import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/core/utils/url.dart';
import 'package:compro_builder/data/model/request/section_payload.dart';
import 'package:compro_builder/data/model/response/section_model.dart';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;

/// Kelola section satu situs: /{slug}/manage/sections.
class SectionsRemoteDatasource {
  static String _base(String slug) =>
      '/${Uri.encodeComponent(slug)}/manage/sections';

  // ─── GET /{slug}/manage/sections  ({data: {sections, usage, addable, locked}}) ─
  Future<Either<ApiFailure, SectionsDataModel>> list(String slug) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.get(
          ApiHelper.uri(_base(slug)),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(SectionsDataModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal memuat daftar section.'),
        );
      });

  // ─── POST /{slug}/manage/sections  (201 → {data: section}) ───────────────
  Future<Either<ApiFailure, SectionModel>> add(
    String slug,
    SectionTypeModel type,
  ) => ApiHelper.guard(() async {
    final body = type.sectionTypeId != null
        ? {'section_type_id': type.sectionTypeId}
        : {'type': type.type};
    final response = await ApiHelper.client.post(
      ApiHelper.uri(_base(slug)),
      headers: await ApiHelper.headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Right(SectionModel.fromJson(response.body));
    }
    return Left(
      ApiHelper.failure(response, fallback: 'Gagal menambahkan section.'),
    );
  });

  // ─── POST /{slug}/manage/sections/{id}/toggle  ({data: section}) ──────────
  Future<Either<ApiFailure, SectionModel>> toggle(String slug, int id) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.post(
          ApiHelper.uri('${_base(slug)}/$id/toggle'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(SectionModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(
            response,
            fallback: 'Gagal mengubah status section.',
          ),
        );
      });

  // ─── POST /{slug}/manage/sections/{id}/move  {direction: up|down} ─────────
  /// Backend membalas dengan daftar section lengkap (bentuk sama seperti list).
  Future<Either<ApiFailure, SectionsDataModel>> move(
    String slug,
    int id, {
    required bool up,
  }) => ApiHelper.guard(() async {
    final response = await ApiHelper.client.post(
      ApiHelper.uri('${_base(slug)}/$id/move'),
      headers: await ApiHelper.headers(),
      body: jsonEncode({'direction': up ? 'up' : 'down'}),
    );
    if (response.statusCode == 200) {
      return Right(SectionsDataModel.fromJson(response.body));
    }
    return Left(
      ApiHelper.failure(response, fallback: 'Gagal memindahkan section.'),
    );
  });

  // ─── DELETE /{slug}/manage/sections/{id}  (204) ───────────────────────────
  Future<Either<ApiFailure, Unit>> delete(String slug, int id) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.delete(
          ApiHelper.uri('${_base(slug)}/$id'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 204 || response.statusCode == 200) {
          return const Right(unit);
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal menghapus section.'),
        );
      });

  // ─── GET /{slug}/manage/sections/{id}  ({data: section}) ──────────────────
  Future<Either<ApiFailure, SectionModel>> detail(String slug, int id) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.get(
          ApiHelper.uri('${_base(slug)}/$id'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(SectionModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal memuat section.'),
        );
      });

  // ─── PUT|POST /{slug}/manage/sections/{id}  ({data: section}) ──────────────
  /// JSON (PUT) bila tanpa gambar baru; multipart (POST) bila ada gambar baru.
  /// Gambar dihapus: payload memuat "`<field>_remove`". Galat 422 membawa
  /// fieldErrors berkunci notasi titik (mis. "items.0.title").
  Future<Either<ApiFailure, SectionModel>> update(
    String slug,
    int id,
    Map<String, dynamic> payload,
  ) => ApiHelper.guard(() async {
    final uri = ApiHelper.uri('${_base(slug)}/$id');
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
      return Right(SectionModel.fromJson(response.body));
    }
    return Left(
      ApiHelper.failure(response, fallback: 'Gagal menyimpan perubahan.'),
    );
  });

  // ─── GET <url gambar>  (tanpa Authorization) ──────────────────────────────
  /// Mengunduh bytes gambar lama (saat baris repeater berpindah indeks).
  Future<Either<ApiFailure, Uint8List>> downloadBytes(String url) =>
      ApiHelper.guard(authenticated: false, () async {
        final response = await ApiHelper.client.get(Uri.parse(resolveUrl(url)));
        if (response.statusCode == 200) return Right(response.bodyBytes);
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal mengunduh gambar.'),
        );
      });
}
