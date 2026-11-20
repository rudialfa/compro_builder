import 'dart:convert';

// ─── RESPONSE MODEL: AuthResponseModel ───────────────────────────────────────
/// POST /auth/login (200) dan POST /auth/register (201) -> {user, token}
class AuthResponseModel {
  final UserModel user;
  final String token;

  AuthResponseModel({required this.user, required this.token});

  factory AuthResponseModel.fromJson(String str) =>
      AuthResponseModel.fromMap(jsonDecode(str) as Map<String, dynamic>);

  factory AuthResponseModel.fromMap(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromMap(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      token: (json['token'] ?? '').toString(),
    );
  }
}

// ─── RESPONSE MODEL: UserModel ───────────────────────────────────────────────
/// GET /auth/me -> objek user langsung (tanpa pembungkus)
class UserModel {
  final int? id;
  final String name;
  final String email;

  /// Null bila email belum diverifikasi (dibutuhkan untuk menayangkan situs).
  final DateTime? emailVerifiedAt;

  /// Akun admin platform (`is_admin` dari server). Dibaca dari login dan /auth/me.
  final bool isAdmin;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.isAdmin = false,
  });

  bool get isEmailVerified => emailVerifiedAt != null;

  factory UserModel.fromJson(String str) =>
      UserModel.fromMap(jsonDecode(str) as Map<String, dynamic>);

  factory UserModel.fromMap(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num?)?.toInt(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      emailVerifiedAt: json['email_verified_at'] == null
          ? null
          : DateTime.tryParse(json['email_verified_at'].toString()),
      isAdmin: json['is_admin'] == true || json['is_admin'] == 1,
    );
  }
}
