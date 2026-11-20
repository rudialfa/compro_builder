import 'package:compro_builder/core/utils/color_hex.dart';
import 'package:compro_builder/presentation/widgets/ui_kit.dart';
import 'package:compro_builder/data/model/response/theme_response_model.dart';
import 'package:flutter/material.dart';

/// Kisi pilihan warna situs (brand / cerah / lembut), dipakai layar Warna
/// situs dan langkah terakhir onboarding. [onSelect] null = nonaktif.
class ThemePicker extends StatelessWidget {
  final List<ThemeOptionModel> themes;
  final String selected;
  final ValueChanged<String>? onSelect;

  const ThemePicker({
    super.key,
    required this.themes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in themes)
              SizedBox(
                width: width,
                child: _ThemeTile(
                  theme: t,
                  selected: t.code == selected,
                  onTap: onSelect == null ? null : () => onSelect!(t.code),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final ThemeOptionModel theme;
  final bool selected;
  final VoidCallback? onTap;

  const _ThemeTile({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = parseHexColor(theme.brand) ?? scheme.primary;
    final bright = parseHexColor(theme.bright) ?? scheme.secondary;
    final soft = parseHexColor(theme.soft) ?? scheme.surfaceContainerHighest;

    return Semantics(
      button: true,
      selected: selected,
      label: theme.name,
      onTap: onTap,
      child: ExcludeSemantics(
        child: AppSurface(
          selected: selected,
          onTap: onTap,
          radius: 16,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  // Pratinjau mini: latar brand, titik cerah, dua garis lembut.
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: brand,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: bright,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        for (final w in const [28.0, 18.0]) ...[
                          Container(
                            width: w,
                            height: 8,
                            decoration: BoxDecoration(
                              color: soft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 32),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            theme.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: scheme.primary,
                          ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
