import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';

import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/data/model/response/section_model.dart';
import 'package:compro_builder/presentation/widgets/section_icons.dart';

class SectionTile extends StatelessWidget {
  const SectionTile({
    super.key,
    required this.section,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onTap,
    required this.onToggle,
    required this.onMove,
    required this.onDelete,
    this.position,
    this.total,
  });

  final SectionModel section;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final void Function(bool up) onMove;
  final VoidCallback onDelete;

  /// Urutan tampil (mulai 1) dan jumlah section; dipakai untuk teks "Urutan 2/4".
  final int? position;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dim = !section.isEnabled && !section.locked;
    final name = sectionLabel(section.type, section.name);

    return Semantics(
      customSemanticsActions: {
        if (!section.locked)
          CustomSemanticsAction(label: l.actionDelete): onDelete,
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: dim
                              ? scheme.surfaceContainerHighest
                              : scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          sectionIcon(section.type),
                          size: 22,
                          color: dim ? scheme.outline : scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: text.titleMedium?.copyWith(
                              color: dim ? scheme.outline : null,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (section.isSample)
                                Chip(
                                  label: Text(l.sampleBadge),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (section.locked)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Semantics(
                          label: l.lockedTitle,
                          child: const Icon(Icons.lock_outline),
                        ),
                      )
                    else
                      Semantics(
                        label: '${l.visibilityToggle}: $name',
                        child: Switch(
                          value: section.isEnabled,
                          onChanged: (_) => onToggle(),
                        ),
                      ),
                  ],
                ),
                if (!section.locked)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            (position != null && total != null)
                                ? '${l.orderLabel} $position/$total'
                                : l.orderLabel,
                            style: text.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        _MoveButton(
                          icon: Icons.arrow_upward,
                          label: l.moveUpShort,
                          tooltip: '${l.moveUp}: $name',
                          onPressed: canMoveUp ? () => onMove(true) : null,
                        ),
                        const SizedBox(width: 8),
                        _MoveButton(
                          icon: Icons.arrow_downward,
                          label: l.moveDownShort,
                          tooltip: '${l.moveDown}: $name',
                          onPressed: canMoveDown ? () => onMove(false) : null,
                        ),
                      ],
                    ),
                  ),
                if (section.locked) const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol geser urutan berlabel (ikon + kata) supaya jelas fungsinya.
/// Area sentuh minimal 44px; nonaktif (abu-abu) bila sudah di ujung daftar.
class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
