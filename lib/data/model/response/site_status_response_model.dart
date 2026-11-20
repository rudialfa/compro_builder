import 'dart:convert';

import 'package:compro_builder/data/model/response/tenant_model.dart';

// ─── RESPONSE MODEL: SiteStatusResponseModel ─────────────────────────────────
/// Balasan POST /{slug}/manage/status: {data: tenantSummary}.
/// Toleran: `tenant`/`data` boleh membungkus, atau objek situs langsung.
/// [tenant] null bila balasan tidak memuat situs yang bisa dibaca; [status]
/// `unknown` bila server tidak menyebut status (pemanggil memakai status yang diminta).
class SiteStatusResponseModel {
  final SiteStatus status;
  final TenantModel? tenant;

  const SiteStatusResponseModel({
    this.status = SiteStatus.unknown,
    this.tenant,
  });

  factory SiteStatusResponseModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) throw const FormatException('Respons tidak valid');
    return SiteStatusResponseModel.fromMap(Map<String, dynamic>.from(decoded));
  }

  factory SiteStatusResponseModel.fromMap(Map<String, dynamic> json) {
    Map<String, dynamic> node = json;
    // Buka pembungkus data/tenant maksimal dua tingkat sampai ketemu `slug`.
    // (`status` saja tidak cukup: hasil toMap() memuat `status` di luar `tenant`.)
    for (var i = 0; i < 2; i++) {
      if (node['slug'] is String) break;
      final inner = node['data'] ?? node['tenant'];
      if (inner is! Map) break;
      node = Map<String, dynamic>.from(inner);
    }
    final tenant = TenantModel.fromMap(node);
    return SiteStatusResponseModel(
      status: tenant.status,
      tenant: tenant.slug.isEmpty ? null : tenant,
    );
  }

  Map<String, dynamic> toMap() => {
    'status': switch (status) {
      SiteStatus.published => 'published',
      SiteStatus.draft => 'draft',
      SiteStatus.unknown => null,
    },
    'tenant': tenant?.toMap(),
  };

  String toJson() => jsonEncode(toMap());
}
