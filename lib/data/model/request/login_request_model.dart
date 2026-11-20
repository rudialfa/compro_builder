import 'dart:convert';

// ─── REQUEST MODEL: LoginRequestModel ────────────────────────────────────────
/// POST /auth/login
class LoginRequestModel {
  final String email;
  final String password;
  final String deviceName;

  LoginRequestModel({
    required this.email,
    required this.password,
    this.deviceName = 'mobile',
  });

  Map<String, dynamic> toMap() => {
        'email': email,
        'password': password,
        'device_name': deviceName,
      };

  String toJson() => jsonEncode(toMap());
}
