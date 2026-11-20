import 'dart:convert';

// ─── REQUEST MODEL: OnboardingRequestModel ───────────────────────────────────
/// POST /{slug}/manage/onboarding  {name, subtitle?, whatsapp?, theme}
/// Server mengabaikan `subtitle`/`whatsapp` yang kosong (isi bawaan dipertahankan),
/// jadi nilai kosong tidak dikirim.
class OnboardingRequestModel {
  final String name;
  final String subtitle;
  final String whatsapp;
  final String theme;

  const OnboardingRequestModel({
    required this.name,
    this.subtitle = '',
    this.whatsapp = '',
    required this.theme,
  });

  Map<String, dynamic> toMap() {
    final sub = subtitle.trim();
    final wa = whatsapp.trim();
    return {
      'name': name.trim(),
      if (sub.isNotEmpty) 'subtitle': sub,
      if (wa.isNotEmpty) 'whatsapp': wa,
      'theme': theme,
    };
  }

  String toJson() => jsonEncode(toMap());
}
