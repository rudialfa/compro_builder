/// Galat API yang sudah dipetakan ke pesan Bahasa Indonesia.
/// Dipakai sebagai sisi Left pada `Either<ApiFailure, T>`.
class ApiFailure {
  final String message;
  final int? statusCode;

  /// Galat validasi 422: {"email": ["..."], "password": ["..."]}
  final Map<String, List<String>> fieldErrors;

  /// Detik tunggu dari header Retry-After pada 429 (null bila tidak ada).
  final int? retryAfter;

  /// Kode galat dari server (mis. `email_unverified` pada 403). Saat ini hanya
  /// diisi untuk 403; null bila server tidak mengirimnya.
  final String? code;

  const ApiFailure(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
    this.retryAfter,
    this.code,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isValidation => statusCode == 422;
  bool get isRateLimited => statusCode == 429;

  /// 403 `{code: "email_unverified"}`: email belum diverifikasi (checkout/charge).
  bool get isEmailUnverified => isForbidden && code == 'email_unverified';

  /// Pesan pertama untuk sebuah field, atau null.
  String? errorFor(String field) {
    final list = fieldErrors[field];
    return (list == null || list.isEmpty) ? null : list.first;
  }

  @override
  String toString() => 'ApiFailure($statusCode, $message)';
}
