import 'package:cached_network_image/cached_network_image.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/media/image_service.dart';
import 'package:compro_builder/core/utils/color_hex.dart';
import 'package:compro_builder/core/utils/url.dart';
import 'package:compro_builder/data/model/response/field_def_model.dart';
import 'package:compro_builder/presentation/pages/sections/dynamic_form/form_values.dart';
import 'package:compro_builder/presentation/widgets/simple_markdown.dart';

/// Merender form dari definisi `fields[]`. Tidak ada form per-tipe section: tipe/field
/// baru yang belum dikenal jatuh ke tampilan "belum didukung" (tidak dikirim ke server).
class DynamicForm extends StatelessWidget {
  const DynamicForm({super.key, required this.controller});

  final DynamicFormController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final d in controller.defs)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FieldWidget(
                def: d,
                scope: controller.values,
                path: d.key,
                keyPath: d.key,
                controller: controller,
              ),
            ),
        ],
      ),
    );
  }
}

/// [path] = notasi titik berindeks (untuk galat); [keyPath] = berbasis id baris (untuk key widget).
class FieldWidget extends StatelessWidget {
  const FieldWidget({
    super.key,
    required this.def,
    required this.scope,
    required this.path,
    required this.keyPath,
    required this.controller,
  });

  final FieldDefModel def;
  final Map<String, dynamic> scope;
  final String path;
  final String keyPath;
  final DynamicFormController controller;

  String get _label => def.required ? '${def.label} *' : def.label;

  @override
  Widget build(BuildContext context) {
    switch (def.type) {
      case FieldType.text ||
          FieldType.textarea ||
          FieldType.link ||
          FieldType.phone ||
          FieldType.email:
        final multiline = def.type == FieldType.textarea;
        final input = TextFormField(
          key: ValueKey('f:$keyPath'),
          initialValue: scope[def.key] as String? ?? '',
          maxLength: def.maxLength,
          minLines: multiline ? 3 : 1,
          maxLines: multiline ? 8 : 1,
          keyboardType: switch (def.type) {
            FieldType.textarea => TextInputType.multiline,
            FieldType.link => TextInputType.url,
            FieldType.phone => TextInputType.phone,
            FieldType.email => TextInputType.emailAddress,
            _ => TextInputType.text,
          },
          textCapitalization: multiline
              ? TextCapitalization.sentences
              : TextCapitalization.none,
          decoration: InputDecoration(
            labelText: _label,
            errorText: controller.errors[path],
            // Petunjuk format hanya ditampilkan untuk isian Markdown.
            helperText: def.markdown ? def.hint : null,
            helperMaxLines: 4,
          ),
          onChanged: (v) => controller.set(scope, def.key, v, path),
        );
        if (!def.markdown) return input;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            input,
            _MarkdownPreview(
              key: ValueKey('md:$keyPath'),
              text: scope[def.key] as String? ?? '',
            ),
          ],
        );
      case FieldType.toggle:
        return SwitchListTile(
          key: ValueKey('f:$keyPath'),
          contentPadding: EdgeInsets.zero,
          title: Text(def.label),
          value: scope[def.key] == true,
          onChanged: (v) => controller.set(scope, def.key, v, path),
        );
      case FieldType.image:
        return _ImageField(
          def: def,
          value: scope[def.key] as ImageValue,
          path: path,
          controller: controller,
        );
      case FieldType.repeater:
        return _RepeaterField(
          def: def,
          rows: scope[def.key] as List<RowValue>,
          path: path,
          keyPath: keyPath,
          controller: controller,
        );
      case FieldType.select:
        final current = scope[def.key] as String? ?? '';
        return DropdownButtonFormField<String>(
          key: ValueKey('f:$keyPath'),
          initialValue: def.options.any((o) => o.value == current)
              ? current
              : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: _label,
            hintText: context.l10n.selectChoose,
            errorText: controller.errors[path],
            helperText: def.hint,
            helperMaxLines: 3,
          ),
          items: [
            for (final o in def.options)
              DropdownMenuItem(value: o.value, child: Text(o.label)),
          ],
          onChanged: (v) => controller.set(scope, def.key, v ?? '', path),
        );
      case FieldType.range:
        return _RangeField(
          key: ValueKey('f:$keyPath'),
          def: def,
          value: scope[def.key] as int? ?? def.rangeMin,
          onChanged: (v) => controller.set(scope, def.key, v, path),
        );
      case FieldType.color:
        return _ColorField(
          key: ValueKey('f:$keyPath'),
          def: def,
          scope: scope,
          path: path,
          controller: controller,
        );
      case FieldType.unknown:
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline),
          title: Text(context.l10n.unsupportedField(def.label)),
        );
    }
  }
}

/// Pratinjau Markdown di bawah isian Tentang (dihitung di perangkat dari teks
/// yang sedang diketik, jadi "###" tidak tampil mentah dan tidak perlu menunggu simpan).
class _MarkdownPreview extends StatelessWidget {
  const _MarkdownPreview({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      title: Text(l.markdownPreview),
      children: [
        if (text.trim().isEmpty)
          Text(l.markdownPreviewEmpty)
        else
          SimpleMarkdown(text),
      ],
    );
  }
}

class _RangeField extends StatelessWidget {
  const _RangeField({
    super.key,
    required this.def,
    required this.value,
    required this.onChanged,
  });

  final FieldDefModel def;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lo = def.rangeMin;
    // Slider mensyaratkan max > min; definisi aneh dari server tidak boleh membuat layar crash.
    final hi = def.rangeMax > lo ? def.rangeMax : lo + 1;
    final divisions = ((hi - lo) / def.rangeStep).round();
    final shown = '$value${def.suffix ?? ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                def.required ? '${def.label} *' : def.label,
                style: text.labelLarge,
              ),
            ),
            Text(shown, style: text.labelLarge),
          ],
        ),
        Slider(
          value: value.clamp(lo, hi).toDouble(),
          min: lo.toDouble(),
          max: hi.toDouble(),
          divisions: divisions > 0 ? divisions : null,
          label: shown,
          semanticFormatterCallback: (v) => '${v.round()}${def.suffix ?? ''}',
          onChanged: (v) => onChanged(v.round()),
        ),
        if (def.hint != null) Text(def.hint!, style: text.bodySmall),
      ],
    );
  }
}

/// Warna bawaan cepat: indigo + kunyit (identitas aplikasi) dan beberapa netral/aksen.
const _colorPresets = <String>[
  '#1d2b5f',
  '#f5b400',
  '#0b1020',
  '#000000',
  '#ffffff',
  '#b91c1c',
  '#15803d',
  '#0369a1',
  '#7e22ce',
];

/// Isian warna `#RRGGBB`: kolom heksa + pratinjau warna + pilihan cepat.
/// (Tanpa paket pemilih warna; bila nanti perlu, ganti isi widget ini saja.)
class _ColorField extends StatefulWidget {
  const _ColorField({
    super.key,
    required this.def,
    required this.scope,
    required this.path,
    required this.controller,
  });

  final FieldDefModel def;
  final Map<String, dynamic> scope;
  final String path;
  final DynamicFormController controller;

  @override
  State<_ColorField> createState() => _ColorFieldState();
}

class _ColorFieldState extends State<_ColorField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.scope[widget.def.key] as String? ?? '',
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _set(String v) {
    widget.controller.set(widget.scope, widget.def.key, v, widget.path);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final def = widget.def;
    final current = (widget.scope[def.key] as String? ?? '').toLowerCase();
    final parsed = parseHexColor(current);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _text,
          maxLength: 7,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
          ],
          decoration: InputDecoration(
            labelText: def.required ? '${def.label} *' : def.label,
            hintText: '#RRGGBB',
            counterText: '',
            errorText: widget.controller.errors[widget.path],
            helperText: def.hint,
            helperMaxLines: 3,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: parsed ?? Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outline),
                ),
              ),
            ),
          ),
          onChanged: (v) => _set(v.trim()),
        ),
        const SizedBox(height: 4),
        Wrap(
          children: [
            for (final hex in _colorPresets)
              Semantics(
                button: true,
                selected: hex == current,
                label: hex,
                child: InkResponse(
                  onTap: () {
                    _text.text = hex;
                    _set(hex);
                  },
                  radius: 24,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: parseHexColor(hex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hex == current
                                ? scheme.primary
                                : scheme.outlineVariant,
                            width: hex == current ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ImageField extends StatelessWidget {
  const _ImageField({
    required this.def,
    required this.value,
    required this.path,
    required this.controller,
  });

  final FieldDefModel def;
  final ImageValue value;
  final String path;
  final DynamicFormController controller;

  Future<void> _pick(BuildContext context) async {
    final l = context.l10n;
    final camera = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.pickCamera),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.pickGallery),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (camera == null) return;
    final maxKb = def.maxKb ?? 1024;
    final bytes = await ImageService().pick(camera: camera, maxKb: maxKb);
    if (bytes == null || !context.mounted) return;
    if (bytes.lengthInBytes > maxKb * 1024) {
      showToast(l.imageTooLarge(maxKb), kind: ToastKind.error);
      return;
    }
    value
      ..newBytes = bytes
      ..removed = false;
    controller.changed(path);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final error = controller.errors[path];

    Widget preview;
    if (value.newBytes != null) {
      preview = SizedBox.expand(
        child: Image.memory(value.newBytes!, fit: BoxFit.cover),
      );
    } else if (value.existingUrl != null && !value.removed) {
      preview = SizedBox.expand(
        child: CachedNetworkImage(
          imageUrl: resolveUrl(value.existingUrl!),
          fit: BoxFit.cover,
          placeholder: (_, _) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (_, _, _) =>
              const Center(child: Icon(Icons.broken_image_outlined, size: 40)),
        ),
      );
    } else {
      preview = Center(
        child: Icon(Icons.image_outlined, size: 40, color: scheme.outline),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          def.required ? '${def.label} *' : def.label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Semantics(
          image: true,
          label: def.label,
          child: Container(
            height: 160,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: error != null ? Border.all(color: scheme.error) : null,
            ),
            child: preview,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => _pick(context),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(l.chooseImage),
            ),
            if (value.hasImage)
              TextButton.icon(
                onPressed: () {
                  value
                    ..newBytes = null
                    ..removed = true;
                  controller.changed(path);
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(l.removeImage),
              ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error, style: TextStyle(color: scheme.error)),
          ),
      ],
    );
  }
}

class _RepeaterField extends StatelessWidget {
  const _RepeaterField({
    required this.def,
    required this.rows,
    required this.path,
    required this.keyPath,
    required this.controller,
  });

  final FieldDefModel def;
  final List<RowValue> rows;
  final String path;
  final String keyPath;
  final DynamicFormController controller;

  /// Judul ringkas satu baris untuk daftar "Pindah ke…": isian teks pertama
  /// yang terisi, atau "{label} {n}" bila semuanya masih kosong.
  String _rowSummary(BuildContext context, RowValue row, int index) {
    for (final c in def.children) {
      if (c.type == FieldType.text || c.type == FieldType.textarea) {
        final v = row.values[c.key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    return context.l10n.rowLabel(def.label, index + 1);
  }

  /// Setelah baris pindah: beri kabar posisi barunya dan gulirkan layar supaya
  /// kartu yang dipindah tetap terlihat (jari pengguna masih di tombol yang sama,
  /// sedangkan kartunya sudah berpindah tempat).
  void _afterMove(BuildContext cardContext, int newIndex) {
    showToast(cardContext.l10n.reorderMoved(newIndex + 1));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!cardContext.mounted) return;
      Scrollable.ensureVisible(
        cardContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    });
  }

  void _step(BuildContext cardContext, int i, bool up) {
    controller.moveRow(rows, i, up);
    _afterMove(cardContext, up ? i - 1 : i + 1);
  }

  Future<void> _pickPosition(BuildContext cardContext, int i) async {
    final titles = [
      for (var k = 0; k < rows.length; k++) _rowSummary(cardContext, rows[k], k),
    ];
    final chosen = await showModalBottomSheet<int>(
      context: cardContext,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _MoveToSheet(titles: titles, current: i),
    );
    if (chosen == null || chosen == i || !cardContext.mounted) return;
    controller.moveRowTo(rows, i, chosen);
    _afterMove(cardContext, chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final canAdd = def.maxItems == null || rows.length < def.maxItems!;
    final error = controller.errors[path];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                def.required ? '${def.label} *' : def.label,
                style: text.titleMedium,
              ),
            ),
            Text(
              def.maxItems != null
                  ? '${rows.length}/${def.maxItems}'
                  : '${rows.length}',
              style: text.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Penjelasan singkat untuk pengguna awam: urutan kartu = urutan tampil.
        if (rows.length > 1) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(l.reorderHint, style: text.bodySmall)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < rows.length; i++)
          KeyedSubtree(
            key: ValueKey('r:$keyPath#${rows[i].id}'),
            // Builder: context ini milik baris (ikut berpindah bersama barisnya).
            child: Builder(
              builder: (cardContext) => Card.outlined(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _OrderBadge(number: i + 1),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l.rowLabel(def.label, i + 1),
                              style: text.labelLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: l.removeRow,
                            icon: Icon(Icons.delete_outline, color: scheme.error),
                            onPressed: () => controller.removeRow(rows, i),
                          ),
                        ],
                      ),
                      if (rows.length > 1) ...[
                        const SizedBox(height: 8),
                        _ReorderBar(
                          position: i + 1,
                          total: rows.length,
                          onUp: i == 0 ? null : () => _step(cardContext, i, true),
                          onDown: i == rows.length - 1
                              ? null
                              : () => _step(cardContext, i, false),
                          onPick: () => _pickPosition(cardContext, i),
                        ),
                      ],
                      for (final c in def.children)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: FieldWidget(
                            def: c,
                            scope: rows[i].values,
                            path: '$path.$i.${c.key}',
                            keyPath: '$keyPath.${rows[i].id}.${c.key}',
                            controller: controller,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error, style: TextStyle(color: scheme.error)),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: canAdd
                ? () => controller.addRow(rows, def.children)
                : null,
            icon: const Icon(Icons.add),
            label: Text(l.addRow),
          ),
        ),
      ],
    );
  }
}

/// Lingkaran bernomor: menunjukkan posisi kartu saat ini (1, 2, 3, ...).
class _OrderBadge extends StatelessWidget {
  const _OrderBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
        child: Text(
          '$number',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Kontrol urutan satu kartu: tulisan "Urutan 2 dari 3", tombol Naik / Turun
/// berlabel (ikon + kata), dan "Pindah ke…" untuk loncat langsung ke posisi lain.
/// Tombol nonaktif (abu-abu) bila kartu sudah di paling atas / paling bawah.
class _ReorderBar extends StatelessWidget {
  const _ReorderBar({
    required this.position,
    required this.total,
    required this.onUp,
    required this.onDown,
    required this.onPick,
  });

  final int position;
  final int total;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    const buttonShape = TextStyle(fontWeight: FontWeight.w700);
    final style = FilledButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: buttonShape,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.swap_vert_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.reorderPosition(position, total),
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: onPick,
                child: Text(l.reorderMoveTo),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: l.moveUp,
                  child: FilledButton.tonalIcon(
                    style: style,
                    onPressed: onUp,
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                    label: Text(l.moveUpShort),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: l.moveDown,
                  child: FilledButton.tonalIcon(
                    style: style,
                    onPressed: onDown,
                    icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                    label: Text(l.moveDownShort),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lembar pilihan posisi: daftar 1..n dengan judul tiap kartu, ketuk untuk pindah.
/// Mengembalikan indeks 0-based posisi tujuan lewat Navigator.pop.
class _MoveToSheet extends StatelessWidget {
  const _MoveToSheet({required this.titles, required this.current});

  final List<String> titles;
  final int current;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                l.reorderSheetTitle,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l.reorderSheetHint,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: titles.length,
                itemBuilder: (context, k) {
                  final isCurrent = k == current;
                  return ListTile(
                    selected: isCurrent,
                    leading: _OrderBadge(number: k + 1),
                    title: Text(
                      titles[k],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isCurrent
                        ? Chip(
                            label: Text(l.reorderCurrent),
                            visualDensity: VisualDensity.compact,
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).pop(k),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
