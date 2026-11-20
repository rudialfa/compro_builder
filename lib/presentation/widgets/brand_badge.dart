import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Lencana merek: kotak membulat bergradasi indigo dengan ikon putih.
/// Hanya tampilan; dipakai di kepala layar masuk dan layar admin.
class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key, required this.icon, this.size = 64});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.indigo, Color(0xFF3B4FA8)],
            ),
            borderRadius: BorderRadius.circular(size * 0.3),
            boxShadow: [
              BoxShadow(
                color: AppTheme.indigo.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }
}
