import 'dart:convert';

import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/model/response/address_response_model.dart';
import 'package:compro_builder/data/model/response/domain_response_model.dart';
import 'package:dartz/dartz.dart';

/// Alamat website (slug) dan status domain sendiri: /{slug}/manage/slug*, /domain.
/// Domain hanya baca; menyetel, memverifikasi, dan melepas domain ada di web.
class AddressRemoteDatasource {
  String _base(String slug) => '/${Uri.encodeComponent(slug)}/manage';

  // ─── GET /{slug}/manage/slug/check?slug=...  (dibatasi 60/menit) ────────────
  /// Selalu 200 dari server; hasil di `ok`/`state`. 429 -> Left.
  Future<Either<ApiFailure, SlugCheckModel>> check(
    String slug,
    String candidate,
  ) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.get(
          ApiHelper.uri('${_base(slug)}/slug/check', {'slug': candidate}),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(SlugCheckModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal memeriksa alamat.'),
        );
      });

  // ─── PUT /{slug}/manage/slug  {slug, confirm: true} ─────────────────────────
  /// Server memeriksa ulang. 422 membawa fieldErrors['slug']. Link lama berhenti
  /// berfungsi, jadi [slug] (lama) tidak boleh dipakai lagi setelah Right.
  Future<Either<ApiFailure, SlugChangeResponseModel>> update(
    String slug,
    String newSlug,
  ) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.put(
          ApiHelper.uri('${_base(slug)}/slug'),
          headers: await ApiHelper.headers(),
          body: jsonEncode({'slug': newSlug, 'confirm': true}),
        );
        if (response.statusCode == 200) {
          return Right(SlugChangeResponseModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal mengganti alamat.'),
        );
      });

  // ─── GET /{slug}/manage/domain  (hanya baca) ────────────────────────────────
  Future<Either<ApiFailure, DomainStatusModel>> domain(String slug) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.get(
          ApiHelper.uri('${_base(slug)}/domain'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(DomainStatusModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal memuat status domain.'),
        );
      });
}
