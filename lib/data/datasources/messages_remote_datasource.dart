import 'dart:convert';

import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/model/response/contact_message_model.dart';
import 'package:dartz/dartz.dart';

/// Pesan masuk dari form kontak: /{slug}/manage/messages.
/// Paket tanpa form kontak (Standar) dijawab 403 oleh backend.
class MessagesRemoteDatasource {
  static String _base(String slug) =>
      '/${Uri.encodeComponent(slug)}/manage/messages';

  // ─── GET /{slug}/manage/messages?page&per_page  ({data: [...], meta}) ─────
  Future<Either<ApiFailure, MessagesPageModel>> list(
    String slug, {
    required int page,
    required int perPage,
  }) => ApiHelper.guard(() async {
    final response = await ApiHelper.client.get(
      ApiHelper.uri(_base(slug), {'page': '$page', 'per_page': '$perPage'}),
      headers: await ApiHelper.headers(),
    );
    if (response.statusCode == 200) {
      return Right(MessagesPageModel.fromJson(response.body));
    }
    return Left(ApiHelper.failure(response, fallback: 'Gagal memuat pesan.'));
  });

  // ─── POST /{slug}/manage/messages/{id}/read  ({data: {id, read}}) ──────────
  /// Endpoint bersifat toggle. Mengembalikan status dibaca yang BARU.
  Future<Either<ApiFailure, bool>> toggleRead(String slug, int id) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.post(
          ApiHelper.uri('${_base(slug)}/$id/read'),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final data = decoded is Map ? decoded['data'] : null;
          final read = data is Map ? data['read'] : null;
          if (read is bool) return Right(read);
          throw const FormatException('Status pesan tidak valid');
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal mengubah status pesan.'),
        );
      });

  // ─── DELETE /{slug}/manage/messages/{id}  (204) ───────────────────────────
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
          ApiHelper.failure(response, fallback: 'Gagal menghapus pesan.'),
        );
      });
}
