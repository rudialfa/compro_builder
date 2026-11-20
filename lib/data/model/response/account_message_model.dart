import 'dart:convert';

// ─── RESPONSE MODEL: AccountMessageModel ─────────────────────────────────────
/// Balasan endpoint akun (docs/API.md 6.1): `{message}` untuk lupa/atur ulang
/// password, `{message, verified}` untuk kirim ulang verifikasi email.
class AccountMessageModel {
  final String message;

  /// Hanya ada pada kirim ulang verifikasi: true bila email ternyata sudah
  /// terverifikasi. Null bila server tidak menyebutnya.
  final bool? verified;

  /// Hanya server uji (DEV_EXPOSE_VERIFY_LINK): tautan verifikasi yang sama dengan di email.
  /// Null di server sungguhan.
  final String? devVerifyUrl;

  const AccountMessageModel({
    required this.message,
    this.verified,
    this.devVerifyUrl,
  });

  factory AccountMessageModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) throw const FormatException('Balasan tidak valid');
    return AccountMessageModel.fromMap(Map<String, dynamic>.from(decoded));
  }

  factory AccountMessageModel.fromMap(Map<String, dynamic> json) {
    final raw = json['message'];
    final verified = json['verified'];
    final dev = json['dev_verify_url'];
    return AccountMessageModel(
      message: raw is String ? raw.trim() : '',
      verified: verified is bool ? verified : null,
      devVerifyUrl: dev is String && dev.isNotEmpty ? dev : null,
    );
  }
}
