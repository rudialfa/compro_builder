part of 'template_bloc.dart';

/// Tautan pratinjau siap dibuka (satu emisi).
class TemplatePreviewTarget {
  final String name;
  final String url;
  const TemplatePreviewTarget({required this.name, required this.url});
}

class TemplateViewData {
  final List<TemplateOptionModel> templates;

  /// Template yang benar-benar dipakai situs.
  final String active;

  /// Pilihan tersimpan; beda dari [active] bila paket turun.
  final String? chosen;

  /// Kode template yang sedang diterapkan / diminta pratinjaunya.
  final String? applyingCode;
  final String? previewingCode;

  /// Galat sesaat (satu emisi).
  final ApiFailure? failure;

  /// Situs terbaru dari server setelah ganti template sukses (satu emisi);
  /// halaman meneruskannya ke SitesBloc.
  final TenantModel? appliedTenant;

  /// Tautan pratinjau siap dibuka (satu emisi).
  final TemplatePreviewTarget? previewTarget;

  const TemplateViewData({
    required this.templates,
    required this.active,
    this.chosen,
    this.applyingCode,
    this.previewingCode,
    this.failure,
    this.appliedTenant,
    this.previewTarget,
  });

  bool get isBusy => applyingCode != null || previewingCode != null;

  /// Pilihan tersimpan tidak sedang aktif (paket belum cukup).
  bool get chosenInactive => chosen != null && chosen != active;

  TemplateOptionModel? byCode(String code) =>
      templates.where((t) => t.code == code).firstOrNull;

  /// [failure], [appliedTenant], dan [previewTarget] sengaja tidak dibawa
  /// (satu emisi). [clearApplying]/[clearPreviewing] mengosongkan penanda proses.
  TemplateViewData copyWith({
    List<TemplateOptionModel>? templates,
    String? active,
    String? chosen,
    String? applyingCode,
    String? previewingCode,
    bool clearApplying = false,
    bool clearPreviewing = false,
    ApiFailure? failure,
    TenantModel? appliedTenant,
    TemplatePreviewTarget? previewTarget,
  }) => TemplateViewData(
    templates: templates ?? this.templates,
    active: active ?? this.active,
    chosen: chosen ?? this.chosen,
    applyingCode: clearApplying ? null : (applyingCode ?? this.applyingCode),
    previewingCode:
        clearPreviewing ? null : (previewingCode ?? this.previewingCode),
    failure: failure,
    appliedTenant: appliedTenant,
    previewTarget: previewTarget,
  );
}

@blocFreezed
sealed class TemplateState with _$TemplateState {
  const factory TemplateState.initial() = _Initial;
  const factory TemplateState.loading() = _Loading;
  const factory TemplateState.loaded(TemplateViewData data) = _Loaded;
  const factory TemplateState.error(ApiFailure failure) = _Error;
}
