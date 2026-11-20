import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:compro_builder/data/datasources/theme_remote_datasource.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/bloc/theme/theme_bloc.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Warna situs: pilih satu dari palet server (sama dengan dashboard web),
/// lalu simpan. Hasilnya (tenantSummary) diteruskan ke [SitesBloc].
class ThemePage extends StatelessWidget {
  final String slug;
  const ThemePage({super.key, required this.slug});

  static Future<void> open(BuildContext context, {required String slug}) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ThemePage(slug: slug)));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ThemeBloc(ThemeRemoteDatasource(), slug: slug)
            ..add(const ThemeEvent.load()),
      child: const _ThemeView(),
    );
  }
}

class _ThemeView extends StatelessWidget {
  const _ThemeView();

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  void _onState(BuildContext context, ThemeState state) {
    final data = state.whenOrNull(loaded: (d) => d);
    if (data == null) return;

    final tenant = data.savedTenant;
    if (tenant != null) {
      context.read<SitesBloc>().add(SitesEvent.tenantUpdated(tenant));
      _snack(context.l10n.themeSaved, kind: ToastKind.success);
      Navigator.of(context).pop();
      return;
    }
    final failure = data.saveFailure;
    if (failure != null) _snack(failure.message, kind: ToastKind.error);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<ThemeBloc, ThemeState>(
      listener: _onState,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(l.themeTitle)),
        body: state.when(
          initial: () => const LoadingView(),
          loading: () => const LoadingView(),
          error: (failure) => ErrorView(
            message: failure.message,
            onRetry: () =>
                context.read<ThemeBloc>().add(const ThemeEvent.load()),
          ),
          loaded: (data) => SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppSurface(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const IconChip(
                              icon: Icons.palette_outlined,
                              color: AppTheme.violet,
                              size: 36,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l.themeIntro,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (data.themes.isEmpty)
                        EmptyView(
                          icon: Icons.palette_outlined,
                          title: l.themeEmpty,
                        )
                      else
                        ThemePicker(
                          themes: data.themes,
                          selected: data.selected,
                          onSelect: data.isSaving
                              ? null
                              : (code) => context.read<ThemeBloc>().add(
                                  ThemeEvent.select(code),
                                ),
                        ),
                    ],
                  ),
                ),
                BottomActionBar(
                  progress: data.isSaving,
                  child: FilledButton.icon(
                    onPressed: (data.isSaving || !data.isDirty)
                        ? null
                        : () => context.read<ThemeBloc>().add(
                            const ThemeEvent.save(),
                          ),
                    icon: const Icon(Icons.check),
                    label: Text(l.actionSave),
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
