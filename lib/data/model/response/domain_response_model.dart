import 'dart:convert';

String _toStr(Object? v) => v == null ? '' : v.toString();

String? _toNullableStr(Object? v) {
  final s = v == null ? '' : v.toString().trim();
  return s.isEmpty ? null : s;
}

// ─── RESPONSE MODEL: DomainSummaryModel ──────────────────────────────────────
/// Domain di dalam tenantSummary: {host, verified, active}.
/// Null di TenantModel bila cache lama.
class DomainSummaryModel {
  /// Null = belum ada domain sendiri.
  final String? host;
  final bool verified;

  /// Terverifikasi DAN paket masih mengizinkan.
  final bool active;

  const DomainSummaryModel({this.host, this.verified = false, this.active = false});

  factory DomainSummaryModel.fromMap(Map<String, dynamic> json) =>
      DomainSummaryModel(
        host: _toNullableStr(json['host']),
        verified: json['verified'] == true,
        active: json['active'] == true,
      );

  Map<String, dynamic> toMap() => {
        'host': host,
        'verified': verified,
        'active': active,
      };
}

// ─── RESPONSE MODEL: DomainDnsModel ──────────────────────────────────────────
/// Petunjuk DNS: {txt_name, txt_value, server_ip, cname_target}. Semua bisa null.
class DomainDnsModel {
  final String? txtName;
  final String? txtValue;
  final String? serverIp;
  final String? cnameTarget;

  const DomainDnsModel({
    this.txtName,
    this.txtValue,
    this.serverIp,
    this.cnameTarget,
  });

  factory DomainDnsModel.fromMap(Map<String, dynamic> json) => DomainDnsModel(
        txtName: _toNullableStr(json['txt_name']),
        txtValue: _toNullableStr(json['txt_value']),
        serverIp: _toNullableStr(json['server_ip']),
        cnameTarget: _toNullableStr(json['cname_target']),
      );

  bool get isEmpty =>
      txtName == null && txtValue == null && serverIp == null && cnameTarget == null;
}

// ─── RESPONSE MODEL: DomainStatusModel ───────────────────────────────────────
/// GET /{slug}/manage/domain (hanya baca):
/// {data: {allowed, feature_ready, host, verified, verified_at, active, url,
/// web_url, dns}}. `dns` null kecuali domain terdaftar, belum terverifikasi,
/// dan paket mengizinkan.
class DomainStatusModel {
  /// Paket mengizinkan domain sendiri.
  final bool allowed;

  /// Server sudah siap menerima domain sendiri.
  final bool featureReady;
  final String? host;
  final bool verified;
  final DateTime? verifiedAt;
  final bool active;

  /// Alamat publik situs saat ini.
  final String? url;

  /// Halaman web untuk menyetel, memverifikasi, dan melepas domain.
  final String? webUrl;
  final DomainDnsModel? dns;

  const DomainStatusModel({
    this.allowed = false,
    this.featureReady = false,
    this.host,
    this.verified = false,
    this.verifiedAt,
    this.active = false,
    this.url,
    this.webUrl,
    this.dns,
  });

  factory DomainStatusModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) throw const FormatException('Respons domain tidak valid');
    return DomainStatusModel.fromMap(Map<String, dynamic>.from(decoded));
  }

  factory DomainStatusModel.fromMap(Map<String, dynamic> json) {
    final inner = json['data'];
    final node = inner is Map ? Map<String, dynamic>.from(inner) : json;
    final rawDns = node['dns'];
    final dns = rawDns is Map
        ? DomainDnsModel.fromMap(rawDns.cast<String, dynamic>())
        : null;
    final rawVerified = node['verified_at'];
    return DomainStatusModel(
      allowed: node['allowed'] == true,
      featureReady: node['feature_ready'] == true,
      host: _toNullableStr(node['host']),
      verified: node['verified'] == true,
      verifiedAt: rawVerified == null ? null : DateTime.tryParse(_toStr(rawVerified)),
      active: node['active'] == true,
      url: _toNullableStr(node['url']),
      webUrl: _toNullableStr(node['web_url']),
      dns: (dns == null || dns.isEmpty) ? null : dns,
    );
  }
}
