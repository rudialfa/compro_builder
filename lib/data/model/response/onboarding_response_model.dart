import 'dart:convert';

import 'package:compro_builder/data/model/response/theme_response_model.dart';

String _toStr(Object? v) => v == null ? '' : v.toString();

/// `state` dari server: null (belum), "done", atau "skipped".
enum OnboardingStatus { none, done, skipped }

// ─── RESPONSE MODEL: OnboardingValuesModel ───────────────────────────────────
/// Nilai awal formulir: {name, subtitle, whatsapp, theme}.
class OnboardingValuesModel {
  final String name;
  final String subtitle;
  final String whatsapp;

  /// Kode tema.
  final String theme;

  const OnboardingValuesModel({
    this.name = '',
    this.subtitle = '',
    this.whatsapp = '',
    this.theme = '',
  });

  factory OnboardingValuesModel.fromMap(Map<String, dynamic> json) =>
      OnboardingValuesModel(
        name: _toStr(json['name']),
        subtitle: _toStr(json['subtitle']),
        whatsapp: _toStr(json['whatsapp']),
        theme: _toStr(json['theme']),
      );
}

// ─── RESPONSE MODEL: OnboardingResponseModel ─────────────────────────────────
/// GET /{slug}/manage/onboarding ->
/// {data: {needed, state, values: {name, subtitle, whatsapp, theme}, themes}}.
class OnboardingResponseModel {
  final bool needed;
  final OnboardingStatus state;
  final OnboardingValuesModel values;
  final List<ThemeOptionModel> themes;

  const OnboardingResponseModel({
    this.needed = false,
    this.state = OnboardingStatus.none,
    this.values = const OnboardingValuesModel(),
    this.themes = const [],
  });

  factory OnboardingResponseModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) throw const FormatException('Respons tidak valid');
    return OnboardingResponseModel.fromMap(Map<String, dynamic>.from(decoded));
  }

  factory OnboardingResponseModel.fromMap(Map<String, dynamic> json) {
    final inner = json['data'];
    final node = inner is Map ? Map<String, dynamic>.from(inner) : json;
    final rawValues = node['values'];
    return OnboardingResponseModel(
      needed: node['needed'] == true,
      state: switch (node['state']) {
        'done' => OnboardingStatus.done,
        'skipped' => OnboardingStatus.skipped,
        _ => OnboardingStatus.none,
      },
      values: rawValues is Map
          ? OnboardingValuesModel.fromMap(rawValues.cast<String, dynamic>())
          : const OnboardingValuesModel(),
      themes: ThemeOptionModel.listFrom(node['themes']),
    );
  }
}
