import 'package:compro_builder/core/l10n/l10n.dart';

/// Status order dari server (pending/paid/failed/expired) -> teks tampil.
/// Status yang tidak dikenal ditampilkan apa adanya.
String billingStatusLabel(AppLocalizations l, String status) =>
    switch (status) {
      'paid' => l.billingStatusPaid,
      'pending' => l.billingStatusPending,
      'failed' => l.billingStatusFailed,
      'expired' => l.billingStatusExpired,
      _ => status,
    };
