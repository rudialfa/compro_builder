import 'dart:convert';

// ─── REQUEST MODEL: ResetPasswordRequestModel ────────────────────────────────
/// POST /auth/reset-password
class ResetPasswordRequestModel {
  final String token;
  final String email;
  final String password;
  final String passwordConfirmation;

  const ResetPasswordRequestModel({
    required this.token,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toMap() => {
        'token': token,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };

  String toJson() => jsonEncode(toMap());
}
