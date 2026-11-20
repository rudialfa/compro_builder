import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Kartu bergradasi indigo dengan lingkaran kunyit sebagai dekorasi.
/// Hanya pembungkus tampilan: isinya (teks putih) ditentukan pemakai.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.heroDeep, AppTheme.indigo, AppTheme.heroLight],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusHero),
        boxShadow: [
          BoxShadow(
            color: AppTheme.indigo.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -46,
            top: -46,
            child: ExcludeSemantics(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppTheme.kunyit.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            left: -28,
            bottom: -34,
            child: ExcludeSemantics(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
