import 'dart:math' as math;

import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Komponen visual kecil untuk desain baru. Semuanya murni tampilan: tidak
/// memegang state bisnis, hanya menerima data dan callback dari pemakai.

/// Permukaan kartu putih membulat dengan bayangan lembut (terang) atau garis
/// tepi (gelap). Bila [onTap] diisi, permukaan bisa disentuh dengan ripple.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.radius = AppTheme.radiusTile,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  /// Beri garis tepi tebal warna utama (mis. item yang sedang dipakai).
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? scheme.surfaceContainer,
        borderRadius: shape,
        boxShadow: dark ? null : AppTheme.softShadow,
        border: selected
            ? Border.all(color: scheme.primary, width: 2)
            : (dark
                ? Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  )
                : null),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Kotak ikon: latar [color] transparan, ikon berwarna [foreground] (atau
/// [color]). Di mode gelap ikon dicerahkan supaya tetap terbaca.
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    required this.color,
    this.foreground,
    this.size = 40,
  });

  final IconData icon;
  final Color color;
  final Color? foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = foreground ?? color;
    final fg = dark ? Color.lerp(base, Colors.white, 0.35)! : base;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: dark ? 0.22 : 0.14),
          borderRadius: BorderRadius.circular(size * 0.35),
        ),
        child: Icon(icon, color: fg, size: size * 0.5),
      ),
    );
  }
}

/// Lencana pil kecil (ikon + teks). Cocok di atas kartu bergradasi.
class PillBadge extends StatelessWidget {
  const PillBadge({
    super.key,
    this.icon,
    required this.label,
    required this.background,
    this.foreground = Colors.white,
  });

  final IconData? icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu statistik: ikon-chip, nilai besar, dan label.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    this.foreground,
    required this.value,
    required this.label,
    this.onTap,
    this.compactValue = false,
  });

  final IconData icon;
  final Color color;
  final Color? foreground;
  final String value;
  final String label;
  final VoidCallback? onTap;

  /// Nilai berupa kata (mis. "Tayang"), bukan angka: huruf lebih kecil.
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      button: onTap != null,
      label: '$label: $value',
      onTap: onTap,
      excludeSemantics: true,
      child: AppSurface(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconChip(icon: icon, color: color, foreground: foreground, size: 36),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (compactValue ? text.titleSmall : text.titleLarge)
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu menu: ikon-chip, judul, dan keterangan singkat ([subtitle]).
class NavTile extends StatelessWidget {
  const NavTile({
    super.key,
    required this.icon,
    required this.color,
    this.foreground,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color? foreground;
  final String title;
  final Widget? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconChip(icon: icon, color: color, foreground: foreground),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            DefaultTextStyle.merge(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              child: subtitle!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Judul kelompok di atas daftar kartu.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// Cincin kemajuan 0-100 dengan angka persen di tengah (animasi singkat).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 64,
    this.stroke = 7,
  });

  final int percent;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = percent.clamp(0, 100) / 100;
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: t,
              track: scheme.outlineVariant,
              color: scheme.primary,
              stroke: stroke,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(stroke + 2),
                child: FittedBox(
                  child: Text(
                    '$percent%',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.color,
    required this.stroke,
  });

  final double progress;
  final Color track;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.color != color ||
      old.stroke != stroke;
}

/// Bilah aksi bawah: lembar putih bersudut atas membulat dengan bayangan ke
/// atas, untuk tombol Simpan. Hanya pembungkus tampilan.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child, this.progress = false});

  final Widget child;

  /// Tampilkan garis kemajuan di atas tombol (mis. saat menyimpan).
  final bool progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusSheet),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.indigo.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progress)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),
          child,
        ],
      ),
    );
  }
}
