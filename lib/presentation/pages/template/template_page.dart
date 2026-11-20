import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:compro_builder/core/utils/color_hex.dart';
import 'package:compro_builder/presentation/widgets/gradient_card.dart';
import 'package:compro_builder/core/widgets/template_thumb.dart';
import 'package:compro_builder/data/datasources/template_remote_datasource.dart';
import 'package:compro_builder/data/model/response/template_response_model.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/bloc/template/template_bloc.dart';
import 'package:compro_builder/presentation/pages/plan/plan_page.dart';
import 'package:compro_builder/presentation/pages/template/template_preview_page.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Template tampilan situs (setara dashboard web): daftar template per tier,
/// kartu terkunci bila paket belum cukup, konfirmasi sebelum mengganti, dan
/// pratinjau. Hasil ganti (tenantSummary) diteruskan ke [SitesBloc].
class TemplatePage extends StatelessWidget {
  final String slug;
  const TemplatePage({super.key, required this.slug});

  static Future<void> open(BuildContext context, {required String slug}) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TemplatePage(slug: slug)),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TemplateBloc(TemplateRemoteDatasource(), slug: slug)
            ..add(const TemplateEvent.load()),
      child: _TemplateView(slug: slug),
    );
  }
}

class _TemplateView extends StatelessWidget {
  final String slug;
  const _TemplateView({required this.slug});

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  void _onState(BuildContext context, TemplateState state) {
    final data = state.whenOrNull(loaded: (d) => d);
    if (data == null) return;

    final tenant = data.appliedTenant;
    if (tenant != null) {
      context.read<SitesBloc>().add(SitesEvent.tenantUpdated(tenant));
      final name = data.byCode(data.active)?.name ?? data.active;
      _snack(context.l10n.templateApplied(name), kind: ToastKind.success);
      return;
    }

    final preview = data.previewTarget;
    if (preview != null) {
      final target = data.templates
          .where((t) => t.name == preview.name)
          .firstOrNull;
      TemplatePreviewPage.open(
        context,
        name: preview.name,
        url: preview.url,
        locked: target?.locked ?? false,
        active: target?.active ?? false,
        onUse: (target == null || target.locked || target.active)
            ? null
            : () => _confirmApply(context, target),
        onUpgrade: (target != null && target.locked)
            ? () => _openPlan(context)
            : null,
      );
      return;
    }

    final failure = data.failure;
    if (failure != null) {
      _snack(failure.message, kind: ToastKind.error);
      // Paket berubah atau template dinonaktifkan: samakan daftar dengan server.
      if (failure.isForbidden || failure.isValidation) {
        context.read<TemplateBloc>().add(const TemplateEvent.load());
      }
    }
  }

  Future<void> _confirmApply(
    BuildContext context,
    TemplateOptionModel t,
  ) async {
    final l = context.l10n;
    final bloc = context.read<TemplateBloc>();
    final ok = await showConfirmDialog(
      context,
      title: l.templateConfirmTitle,
      message: l.templateConfirmMessage(t.name),
      confirmLabel: l.templateUse,
    );
    if (ok && !bloc.isClosed) bloc.add(TemplateEvent.apply(t.code));
  }

  /// Halaman Paket bisa membuka kunci template: muat ulang saat kembali.
  Future<void> _openPlan(BuildContext context) async {
    final bloc = context.read<TemplateBloc>();
    final sites = context.read<SitesBloc>();
    await PlanPage.open(context, slug: slug);
    if (!bloc.isClosed) bloc.add(const TemplateEvent.load());
    if (!sites.isClosed) sites.add(const SitesEvent.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<TemplateBloc, TemplateState>(
      listener: _onState,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(l.templateTitle)),
        body: state.when(
          initial: () => const LoadingView(),
          loading: () => const LoadingView(),
          error: (failure) => ErrorView(
            message: failure.message,
            onRetry: () =>
                context.read<TemplateBloc>().add(const TemplateEvent.load()),
          ),
          loaded: (data) => SafeArea(
            child: Column(
              children: [
                if (data.isBusy) const LinearProgressIndicator(),
                Expanded(
                  child: _TemplateList(
                    data: data,
                    onPreview: (code) => context.read<TemplateBloc>().add(
                      TemplateEvent.preview(code),
                    ),
                    onUse: (t) => _confirmApply(context, t),
                    onUpgrade: () => _openPlan(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _tierLabel(BuildContext context, String tier) {
  final l = context.l10n;
  return switch (tier.toLowerCase()) {
    'classic' => l.templateTierClassic,
    'medium' => l.templateTierMedium,
    'pro' => l.templateTierPro,
    _ => tier,
  };
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: scheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Daftar template + penyaring tier (Semua / Classic / Medium / Pro).
class _TemplateList extends StatefulWidget {
  final TemplateViewData data;
  final void Function(String code) onPreview;
  final void Function(TemplateOptionModel t) onUse;
  final VoidCallback onUpgrade;

  const _TemplateList({
    required this.data,
    required this.onPreview,
    required this.onUse,
    required this.onUpgrade,
  });

  @override
  State<_TemplateList> createState() => _TemplateListState();
}

class _TemplateListState extends State<_TemplateList> {
  String _tier = 'all';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final data = widget.data;
    final tiers = <String>[];
    for (final t in data.templates) {
      final k = t.tier.toLowerCase();
      if (!tiers.contains(k)) tiers.add(k);
    }
    final shown = _tier == 'all'
        ? data.templates
        : data.templates.where((t) => t.tier.toLowerCase() == _tier).toList();
    final current = data.byCode(data.active);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (current != null) ...[
          _ActiveHero(template: current),
          const SizedBox(height: 12),
        ],
        Text(
          l.templateIntro,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (data.chosenInactive) ...[
          const SizedBox(height: 12),
          _InfoBanner(
            text: l.templateChosenInactive(
              data.byCode(data.chosen!)?.name ?? data.chosen!,
              data.byCode(data.active)?.name ?? data.active,
            ),
          ),
        ],
        if (tiers.length > 1) ...[
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  label: 'Semua (${data.templates.length})',
                  selected: _tier == 'all',
                  onTap: () => setState(() => _tier = 'all'),
                ),
                for (final k in tiers) ...[
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: _tierLabel(context, k),
                    selected: _tier == k,
                    onTap: () => setState(() => _tier = k),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (data.templates.isEmpty)
          EmptyView(icon: Icons.web_outlined, title: l.templateEmpty)
        else
          for (final t in shown) ...[
            _TemplateCard(
              template: t,
              busy: data.isBusy,
              applying: data.applyingCode == t.code,
              previewing: data.previewingCode == t.code,
              onPreview: () => widget.onPreview(t.code),
              onUse: () => widget.onUse(t),
              onUpgrade: widget.onUpgrade,
            ),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
}

/// Ringkasan template yang sedang dipakai (turunan dari data yang sama).
class _ActiveHero extends StatelessWidget {
  final TemplateOptionModel template;
  const _ActiveHero({required this.template});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    return GradientCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: TemplateThumb(
              code: template.code,
              palette: template.palette,
              imageUrl: template.previewImage,
              aspectRatio: 92 / 60,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PillBadge(
                  icon: Icons.check_circle_outline,
                  label: l.templateActive,
                  background: AppTheme.teal.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 6),
                Text(
                  template.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pil penyaring tier (pengganti tampilan ChoiceChip; perilaku sama).
class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerHighest,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
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

/// Titik warna palet template (brand, aksen, lembut).
class _PaletteDots extends StatelessWidget {
  final Map<String, String> palette;
  const _PaletteDots({required this.palette});

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    final dots = <Widget>[];
    for (final key in const ['brand', 'bright', 'soft']) {
      final raw = palette[key];
      final color = raw == null ? null : parseHexColor(raw);
      if (color == null) continue;
      dots.add(
        Container(
          width: 13,
          height: 13,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: outline),
          ),
        ),
      );
    }
    if (dots.isEmpty) return const SizedBox.shrink();
    return ExcludeSemantics(child: Row(mainAxisSize: MainAxisSize.min, children: dots));
  }
}

class _TemplateCard extends StatelessWidget {
  final TemplateOptionModel template;
  final bool busy;
  final bool applying;
  final bool previewing;
  final VoidCallback onPreview;
  final VoidCallback onUse;
  final VoidCallback onUpgrade;

  const _TemplateCard({
    required this.template,
    required this.busy,
    required this.applying,
    required this.previewing,
    required this.onPreview,
    required this.onUse,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final t = template;
    const thumbRadius = BorderRadius.all(Radius.circular(14));

    return AppSurface(
      selected: t.active,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contoh tampilan: ketuk untuk pratinjau penuh.
          ClipRRect(
            borderRadius: thumbRadius,
            child: InkWell(
              onTap: busy ? null : onPreview,
              child: Stack(
                children: [
                  Opacity(
                    opacity: t.locked ? 0.7 : 1,
                    child: TemplateThumb(
                      code: t.code,
                      palette: t.palette,
                      imageUrl: t.previewImage,
                      borderRadius: thumbRadius,
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: PillBadge(
                      label: _tierLabel(context, t.tier),
                      background: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  if (t.locked)
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: PillBadge(
                        icon: Icons.lock_outline,
                        label: 'Upgrade',
                        background: Color(0xFFF2B01E),
                        foreground: Color(0xFF1E2A5E),
                      ),
                    )
                  else if (t.active)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: PillBadge(
                        icon: Icons.check_circle,
                        label: l.templateActive,
                        background: scheme.primary,
                        foreground: scheme.onPrimary,
                      ),
                    ),
                  if (previewing)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.25),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.name,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _PaletteDots(palette: t.palette),
                  ],
                ),
                if (t.tagline.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    t.tagline,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (t.bestFor.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Cocok untuk: ${t.bestFor}',
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (t.locked) ...[
                  const SizedBox(height: 8),
                  Text(
                    l.templateLockedPlan(
                      t.requiredPlanName.isNotEmpty
                          ? t.requiredPlanName
                          : _tierLabel(context, t.tier),
                    ),
                    style: text.bodySmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : onPreview,
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: Text(l.templatePreview),
                      ),
                    ),
                    if (t.locked) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: busy ? null : onUpgrade,
                          icon: const Icon(
                            Icons.workspace_premium_outlined,
                            size: 18,
                          ),
                          label: Text(l.planViewPlans),
                        ),
                      ),
                    ] else if (!t.active) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: busy ? null : onUse,
                          child: applying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l.templateUse),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
