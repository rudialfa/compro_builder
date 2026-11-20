import 'dart:convert';

// ─── REQUEST MODEL: RegisterRequestModel ─────────────────────────────────────
/// POST /auth/register
class RegisterRequestModel {
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;

  /// Nama usaha: bila diisi, server ikut membuat situs pertama (tenant).
  final String? companyName;

  /// Alamat situs (opsional). Kosong -> server membuatnya dari nama usaha.
  /// Hanya dikirim bila [companyName] terisi (server menolak slug tanpa nama usaha).
  final String? slug;

  RegisterRequestModel({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.companyName,
    this.slug,
  });

  Map<String, dynamic> toMap() {
    final company = companyName?.trim() ?? '';
    final slugValue = slug?.trim() ?? '';
    return {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (company.isNotEmpty) 'company_name': company,
      if (company.isNotEmpty && slugValue.isNotEmpty) 'slug': slugValue,
    };
  }

  String toJson() => jsonEncode(toMap());
}
