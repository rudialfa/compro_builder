import 'package:flutter/widgets.dart';
import 'package:compro_builder/l10n/gen/app_localizations.dart';

export 'package:compro_builder/l10n/gen/app_localizations.dart';

/// Akses cepat teks lokal: `context.l10n.actionLogin`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
