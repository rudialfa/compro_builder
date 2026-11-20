import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:compro_builder/core/constants/variables.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/auth_local_datasource.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Helper bersama supaya setiap datasource tidak mengulang header, URL,
/// dan penanganan galat. Bentuk datasource: `Future<Either<ApiFailure, T>>`.
class ApiHelper {
  /// Bisa diganti di test dengan MockClient.
  static http.Client client = http.Client();

  /// Naik 1 setiap kali server menjawab 401 pada request ber-token.
  /// main.dart mendengarkan ini untuk mengembalikan pengguna ke layar masuk.
  static final ValueNotifier<int> sessionExpired = ValueNotifier<int>(0);

  /// Bentuk URL: ApiHelper.uri('/auth/login')
  static Uri uri(String path, [Map<String, String>? query]) {
    final url = Uri.parse('${Variables.apiUrl}$path');
    if (query == null || query.isEmpty) return url;
    return url.replace(queryParameters: query);
  }

  /// Header standar. Bearer ikut dikirim bila [auth] true dan token ada.
  static Future<Map<String, String>> headers({
    bool json = true,
    bool auth = true,
  }) async {
    final token = auth ? await AuthLocalDatasource().getToken() : null;
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Petakan response non-sukses menjadi [ApiFailure] (401/403/404/422/429/5xx).
  static ApiFailure failure(
    http.Response response, {
    String fallback = 'Terjadi kesalahan pada server.',
  }) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      // body bukan JSON; pakai pesan berdasarkan status
    }

    final fieldErrors = <String, List<String>>{};
    final errors = body?['errors'];
    if (errors is Map) {
      errors.forEach((key, value) {
        if (value is List) {
          fieldErrors['$key'] = value.map((e) => '$e').toList();
        } else if (value != null) {
          fieldErrors['$key'] = ['$value'];
        }
      });
    }

    final rawMessage = body?['message'];
    final bodyMessage = (rawMessage is String && rawMessage.trim().isNotEmpty)
        ? rawMessage
        : null;
    final code = response.statusCode;

    switch (code) {
      case 401:
        return ApiFailure('Sesi berakhir. Silakan masuk kembali.',
            statusCode: code);
      case 403:
        final rawCode = body?['code'];
        return ApiFailure(
          bodyMessage ?? 'Anda tidak memiliki akses.',
          statusCode: code,
          code: rawCode is String && rawCode.isNotEmpty ? rawCode : null,
        );
      case 404:
        return ApiFailure('Data tidak ditemukan.', statusCode: code);
      case 422:
        final allMessages = fieldErrors.values.expand((e) => e);
        return ApiFailure(
          allMessages.isNotEmpty
              ? allMessages.first
              : (bodyMessage ?? 'Data yang dikirim belum sesuai.'),
          statusCode: code,
          fieldErrors: fieldErrors,
        );
      case 429:
        return ApiFailure(
          'Terlalu banyak percobaan. Coba lagi beberapa saat.',
          statusCode: code,
          retryAfter: int.tryParse(response.headers['retry-after'] ?? ''),
        );
      default:
        // Pesan 5xx Laravel berbahasa Inggris -> pakai fallback.
        return ApiFailure(
          code >= 500 ? fallback : (bodyMessage ?? fallback),
          statusCode: code,
        );
    }
  }

  /// Bungkus pemanggilan supaya galat jaringan menjadi Left, bukan exception.
  /// [authenticated] true (bawaan): 401 menghapus token dan memicu
  /// [sessionExpired]. Pakai false untuk login/register/logout.
  static Future<Either<ApiFailure, T>> guard<T>(
    Future<Either<ApiFailure, T>> Function() call, {
    bool authenticated = true,
  }) async {
    try {
      final result = await call().timeout(Variables.timeout);
      final failed = result.fold<ApiFailure?>((l) => l, (_) => null);
      if (authenticated && failed != null && failed.isUnauthorized) {
        await AuthLocalDatasource().removeToken();
        sessionExpired.value++;
      }
      return result;
    } on TimeoutException {
      return const Left(ApiFailure('Koneksi timeout. Silakan coba lagi.'));
    } on SocketException {
      return const Left(ApiFailure(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      ));
    } on http.ClientException {
      return const Left(ApiFailure(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      ));
    } on FormatException {
      return const Left(ApiFailure('Format data dari server tidak sesuai.'));
    } catch (_) {
      // Jangan bocorkan detail exception (bisa memuat data sensitif).
      return const Left(ApiFailure('Terjadi kesalahan. Silakan coba lagi.'));
    }
  }
}
