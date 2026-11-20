import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';

/// Kartu satu situs di daftar situs. Tampilan mengikuti versi lama.
class SiteCard extends StatelessWidget {
  const SiteCard({
    super.key,
    required this.tenant,
    required this.isActive,
    required this.onTap,
  });

  final TenantModel tenant;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final unread = tenant.unreadMessages ?? 0;
    final planName = tenant.plan?.name ?? '';

    final dark = Theme.of(context).brightness == Brightness.dark;
    final completeness = tenant.completeness;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Semantics(
        button: true,
        selected: isActive,
        child: AppSurface(
          selected: isActive,
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.heroDeep,
                        AppTheme.indigo,
                        AppTheme.heroLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    tenant.name.isEmpty
                        ? '?'
                        : tenant.name.characters.first.toUpperCase(),
                    style: text.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '/${tenant.slug}',
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        if (tenant.status == SiteStatus.published)
                          SiteChip(
                            icon: Icons.public,
                            label: l.statusPublished,
                            color: dark
                                ? scheme.primaryContainer
                                : const Color(0xFFC9F2EA),
                            onColor: dark
                                ? scheme.onPrimaryContainer
                                : const Color(0xFF0A5C50),
                          ),
                        if (tenant.status == SiteStatus.draft)
                          SiteChip(
                            icon: Icons.edit_note,
                            label: l.statusDraft,
                            color: scheme.surfaceContainerHighest,
                            onColor: scheme.onSurfaceVariant,
                          ),
                        if (tenant.suspended)
                          SiteChip(
                            icon: Icons.block,
                            label: l.statusDisabled,
                            color: scheme.errorContainer,
                            onColor: scheme.onErrorContainer,
                          ),
                        if (planName.isNotEmpty)
                          SiteChip(
                            icon: Icons.workspace_premium_outlined,
                            label: l.planLabel(planName),
                            color: scheme.secondaryContainer,
                            onColor: scheme.onSecondaryContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (completeness != null && completeness.total > 0) ...[
                const SizedBox(width: 8),
                Semantics(
                  label: l.completenessPercent(completeness.percent),
                  child: ProgressRing(
                    percent: completeness.percent,
                    size: 46,
                    stroke: 5,
                  ),
                ),
              ],
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Semantics(
                  label: l.unreadMessages(unread),
                  child: ExcludeSemantics(
                    child: Badge(label: Text(unread > 99 ? '99+' : '$unread')),
                  ),
                ),
              ],
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Semantics(
                    label: l.activeSite,
                    child: Icon(Icons.check_circle, color: scheme.primary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SiteChip extends StatelessWidget {
  const SiteChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: onColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: onColor, fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}
