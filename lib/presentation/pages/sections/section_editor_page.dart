import 'dart:async';

import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/data/datasources/sections_remote_datasource.dart';
import 'package:compro_builder/data/model/response/section_model.dart';
import 'package:compro_builder/presentation/bloc/section_editor/section_editor_bloc.dart';
import 'package:compro_builder/presentation/bloc/sections/sections_bloc.dart';
import 'package:compro_builder/presentation/pages/sections/dynamic_form/dynamic_form.dart';
import 'package:compro_builder/presentation/pages/sections/dynamic_form/form_values.dart';
import 'package:compro_builder/presentation/pages/sections/dynamic_form/payload_builder.dart';
import 'package:compro_builder/presentation/widgets/section_icons.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Editor satu section. Form digerakkan oleh `section.fields` dari server.
class SectionEditorPage extends StatelessWidget {
  final String slug;
  final SectionModel section;
  const SectionEditorPage({
    super.key,
    required this.slug,
    required this.section,
  });

  /// Halaman yang ditumpuk Navigator berada di luar pohon [SectionsPage], jadi
  /// [SectionsBloc] diteruskan lewat BlocProvider.value.
  static Future<void> open(
    BuildContext context, {
    required String slug,
    required SectionModel section,
  }) {
    final sectionsBloc = context.read<SectionsBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: sectionsBloc,
          child: SectionEditorPage(slug: slug, section: section),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SectionEditorBloc(
        SectionsRemoteDatasource(),
        slug: slug,
        sectionId: section.id,
        initial: section,
      )..add(const SectionEditorEvent.load()),
      child: _EditorView(title: sectionLabel(section.type, section.name)),
    );
  }
}

class _EditorView extends StatefulWidget {
  final String title;
  const _EditorView({required this.title});

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  DynamicFormController? _form;
  String? _error;
  bool _blocked = false; // jeda setelah 429
  Timer? _unblock;

  @override
  void dispose() {
    _unblock?.cancel();
    _form?.dispose();
    super.dispose();
  }

  void _save() {
    final l = context.l10n;
    final form = _form;
    if (form == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    form.pruneEmptyRows();
    if (!form.validate(l)) return;

    context.read<SectionEditorBloc>().add(
      SectionEditorEvent.save((fetch) => buildPayload(form, fetch: fetch)),
    );
  }

  void _onState(BuildContext context, SectionEditorState state) {
    final data = state.whenOrNull(loaded: (d) => d);
    if (data == null) return;

    final saved = data.savedSection;
    if (saved != null) {
      context.read<SectionsBloc>().add(SectionsEvent.sectionReplaced(saved));
      showToast(context.l10n.saved, kind: ToastKind.success);
      Navigator.of(context).pop();
      return;
    }

    final failure = data.saveFailure;
    if (failure == null) return;
    if (failure.isValidation) _form?.setServerErrors(failure.fieldErrors);
    setState(() {
      _error = failure.message;
      if (failure.isRateLimited) {
        _blocked = true;
        _unblock?.cancel();
        _unblock = Timer(Duration(seconds: failure.retryAfter ?? 30), () {
          if (mounted) setState(() => _blocked = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<SectionEditorBloc, SectionEditorState>(
      listener: _onState,
      builder: (context, state) {
        final name = state.maybeWhen(
          loaded: (d) => sectionLabel(d.section.type, d.section.name),
          orElse: () => widget.title,
        );
        return Scaffold(
          appBar: AppBar(title: Text(name)),
          body: state.when(
            initial: () => const LoadingView(),
            loading: () => const LoadingView(),
            error: (failure) => ErrorView(
              message: failure.message,
              onRetry: () => context.read<SectionEditorBloc>().add(
                const SectionEditorEvent.load(),
              ),
            ),
            loaded: (data) {
              final section = data.section;
              final form = _form ??= DynamicFormController(
                section.fields,
                section.content,
              );
              return SafeArea(
                child: Column(
                  children: [
                    if (data.fromList)
                      MaterialBanner(
                        content: Text(l.offlineBanner),
                        leading: const Icon(Icons.cloud_off),
                        actions: const [SizedBox.shrink()],
                      ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          if (_error != null) ...[
                            _ErrorBox(_error!),
                            const SizedBox(height: 16),
                          ],
                          if (section.fields.isEmpty)
                            Text(l.fieldsEmpty)
                          else
                            DynamicForm(controller: form),
                        ],
                      ),
                    ),
                    if (data.isSaving)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: LinearProgressIndicator(),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: FilledButton(
                        onPressed:
                            (data.isSaving ||
                                _blocked ||
                                section.fields.isEmpty)
                            ? null
                            : _save,
                        child: Text(l.actionSave),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Kotak pesan galat non-field (mis. 429, 403, jaringan).
class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(Icons.error_outline, color: scheme.onErrorContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
