import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';

typedef FieldValidator = String? Function(String?);

/// Validator form sisi klien (server tetap validasi akhir).
class Validators {
  Validators._();

  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static FieldValidator required(AppLocalizations l) =>
      (v) => (v == null || v.trim().isEmpty) ? l.validationRequired : null;

  static FieldValidator email(AppLocalizations l) => (v) {
        final t = v?.trim() ?? '';
        if (t.isEmpty) return l.validationRequired;
        return _emailRe.hasMatch(t) ? null : l.validationEmail;
      };

  static FieldValidator password(AppLocalizations l, {int min = 8}) => (v) {
        if (v == null || v.isEmpty) return l.validationRequired;
        return v.length < min ? l.validationPasswordMin(min) : null;
      };

  static FieldValidator matches(AppLocalizations l, TextEditingController other) => (v) {
        if (v == null || v.isEmpty) return l.validationRequired;
        return v == other.text ? null : l.validationPasswordMatch;
      };
}
