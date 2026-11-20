import 'dart:math' as math;

import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rasio kontras WCAG 2.x antara dua warna.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('palet brand mengikuti web: indigo + kunyit', () {
    expect(AppTheme.indigo, const Color(0xFF1D2B5F));
    expect(AppTheme.kunyit, const Color(0xFFF5B400));
    expect(AppTheme.light().colorScheme.primary, AppTheme.indigo);
    expect(AppTheme.light().colorScheme.tertiary, AppTheme.kunyit);
    expect(AppTheme.dark().colorScheme.secondary, AppTheme.kunyit);
    expect(AppTheme.light().colorScheme.brightness, Brightness.light);
    expect(AppTheme.dark().colorScheme.brightness, Brightness.dark);
  });

  for (final entry in {
    'terang': AppTheme.light(),
    'gelap': AppTheme.dark(),
  }.entries) {
    test('kontras teks >= 4,5:1 pada tema ${entry.key}', () {
      final c = entry.value.colorScheme;
      final pairs = <String, (Color, Color)>{
        'primary/onPrimary': (c.primary, c.onPrimary),
        'primaryContainer': (c.primaryContainer, c.onPrimaryContainer),
        'secondary/onSecondary': (c.secondary, c.onSecondary),
        'secondaryContainer': (c.secondaryContainer, c.onSecondaryContainer),
        'tertiary/onTertiary': (c.tertiary, c.onTertiary),
        'tertiaryContainer': (c.tertiaryContainer, c.onTertiaryContainer),
        'error/onError': (c.error, c.onError),
        'errorContainer': (c.errorContainer, c.onErrorContainer),
        'surface/onSurface': (c.surface, c.onSurface),
        'surface/onSurfaceVariant': (c.surface, c.onSurfaceVariant),
        'surfaceContainerHighest': (c.surfaceContainerHighest, c.onSurfaceVariant),
        // Teks berwarna langsung di atas permukaan (mis. tombol teks).
        'surface/primary': (c.surface, c.primary),
        'surface/secondary': (c.surface, c.secondary),
      };
      for (final e in pairs.entries) {
        final ratio = _contrast(e.value.$1, e.value.$2);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${e.key}: ${ratio.toStringAsFixed(2)}:1',
        );
      }
    });

    test('garis outline >= 3:1 terhadap permukaan (tema ${entry.key})', () {
      final c = entry.value.colorScheme;
      expect(_contrast(c.surface, c.outline), greaterThanOrEqualTo(3));
    });
  }
}
