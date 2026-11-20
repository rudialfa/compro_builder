import 'dart:convert';

import 'package:compro_builder/data/model/response/template_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';

// ─── RESPONSE MODEL: TemplateUpdateResponseModel ─────────────────────────────
/// PUT /{slug}/manage/template ->
/// {data: {active, chosen, templates, summary: tenantSummary}, message}.
/// Dipisah dari SiteStatusResponseModel karena tenantSummary ada di `data.summary`,
/// bukan di `data`.
class TemplateUpdateResponseModel {
  final TemplatesResponseModel templates;
  final TenantModel tenant;

  const TemplateUpdateResponseModel({
    required this.templates,
    required this.tenant,
  });

  factory TemplateUpdateResponseModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) throw const FormatException('Respons tidak valid');
    final inner = decoded['data'];
    if (inner is! Map) throw const FormatException('Respons tidak valid');
    final node = Map<String, dynamic>.from(inner);
    final summary = node['summary'];
    if (summary is! Map) throw const FormatException('Ringkasan situs tidak ada');
    final tenant = TenantModel.fromMap(Map<String, dynamic>.from(summary));
    if (tenant.slug.isEmpty) throw const FormatException('Ringkasan situs tidak valid');
    return TemplateUpdateResponseModel(
      templates: TemplatesResponseModel.fromMap(node),
      tenant: tenant,
    );
  }
}
