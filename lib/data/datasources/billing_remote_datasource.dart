import 'dart:convert';

import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/api_helper.dart';
import 'package:compro_builder/data/model/response/billing_response_model.dart';
import 'package:dartz/dartz.dart';

/// Pembayaran paket: /{slug}/manage/billing (docs/API.md bagian 6.8).
/// Alur: overview -> checkout -> charge -> polling status sampai lunas.
class BillingRemoteDatasource {
  String _base(String slug) =>
      '/${Uri.encodeComponent(slug)}/manage/billing';

  // ─── GET /billing  ({data: {current, plans, methods, periods, pending_order, ...}}) ──
  /// Server menyinkronkan order pending ke gateway lebih dulu, jadi data ini
  /// juga cara memuat ulang paket setelah pembayaran di luar aplikasi.
  Future<Either<ApiFailure, BillingOverviewModel>> overview(String slug) =>
      ApiHelper.guard(() async {
        final response = await ApiHelper.client.get(
          ApiHelper.uri(_base(slug)),
          headers: await ApiHelper.headers(),
        );
        if (response.statusCode == 200) {
          return Right(BillingOverviewModel.fromJson(response.body));
        }
        return Left(
          ApiHelper.failure(response, fallback: 'Gagal memuat data tagihan.'),
        );
      });

  // ─── POST /billing/checkout  {plan, months}  -> 201 {data: order} ───────────
  /// 403 `email_unverified` bila email belum diverifikasi; 422 pada `plan`
  /// bila paket tidak boleh dibeli.
  Future<Either<ApiFailure, BillingOrderModel>> checkout(
    String slug, {
    required String plan,
    required int months,
  }) => ApiHelper.guard(() async {
    final response = await ApiHelper.client.post(
      ApiHelper.uri('${_base(slug)}/checkout'),
      headers: await ApiHelper.headers(),
      body: jsonEncode({'plan': plan, 'months': months}),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Right(BillingOrderModel.fromJson(response.body));
    }
    return Left(
      ApiHelper.failure(response, fallback: 'Gagal membuat tagihan.'),
    );
  });

  // ─── POST /billing/orders/{id}/charge  {method}  -> 200 {data: order} ───────
  /// 422 pada `method` bila metode tidak tersedia atau ditolak gateway;
  /// 403 `email_unverified` bila email belum diverifikasi.
  Future<Either<ApiFailure, BillingOrderModel>> charge(
    String slug,
    int orderId,
    String method,
  ) => ApiHelper.guard(() async {
    final response = await ApiHelper.client.post(
      ApiHelper.uri('${_base(slug)}/orders/$orderId/charge'),
      headers: await ApiHelper.headers(),
      body: jsonEncode({'method': method}),
    );
    if (response.statusCode == 200) {
      return Right(BillingOrderModel.fromJson(response.body));
    }
    return Left(
      ApiHelper.failure(response, fallback: 'Gagal membuat tagihan pembayaran.'),
    );
  });

  // ─── GET /billing/orders/{id}/status  ({data: {status, paid, expired, state, tenant?}}) ──
  /// Dipakai untuk polling. Server menanyakan gateway paling sering sekali per
  /// 8 detik per order; batas 40 permintaan/menit (429 bila terlampaui).
  Future<Either<ApiFailure, BillingStatusModel>> status(
    String slug,
    int orderId,
  ) => ApiHelper.guard(() async {
    final response = await ApiHelper.client.get(
      ApiHelper.uri('${_base(slug)}/orders/$orderId/status'),
      headers: await ApiHelper.headers(),
    );
    if (response.statusCode == 200) {
      return Right(BillingStatusModel.fromJson(response.body));
    }
    return Left(
      ApiHelper.failure(response, fallback: 'Gagal memeriksa status pembayaran.'),
    );
  });

  // ─── GET /billing/orders?page=&per_page=  ({data: [order], meta: {page,last_page,total}}) ──
  Future<Either<ApiFailure, BillingOrdersPageModel>> orders(
    String slug, {
    int page = 1,
    int perPage = 20,
  }) => ApiHelper.guard(() async {
    final response = await ApiHelper.client.get(
      ApiHelper.uri('${_base(slug)}/orders', {
        'page': '$page',
        'per_page': '$perPage',
      }),
      headers: await ApiHelper.headers(),
    );
    if (response.statusCode == 200) {
      return Right(BillingOrdersPageModel.fromJson(response.body));
    }
    return Left(
      ApiHelper.failure(response, fallback: 'Gagal memuat riwayat pembayaran.'),
    );
  });
}
