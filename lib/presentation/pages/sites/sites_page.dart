import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/theme/app_theme.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/widgets/site_card.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Daftar situs milik pengguna. Mengetuk kartu memilih situs aktif.
/// (Fase 3: dari sini membuka daftar section situs terpilih.)
class SitesPage extends StatelessWidget {
  const SitesPage({super.key});

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<SitesBloc>();
    // Berlangganan sebelum add supaya emisi pertama tidak terlewat.
    final next = bloc.stream.first;
    bloc.add(const SitesEvent.refresh());
    await next.timeout(const Duration(seconds: 30), onTimeout: () => bloc.state);
  }

  void _showMessage(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.homeTitle)),
      body: BlocConsumer<SitesBloc, SitesState>(
        listenWhen: (_, current) =>
            current.whenOrNull(loaded: (d) => d.refreshFailure) != null,
        listener: (context, state) {
          final failure = state.whenOrNull(loaded: (d) => d.refreshFailure);
          if (failure != null) {
            _showMessage(failure.message, kind: ToastKind.error);
          }
        },
        builder: (context, state) => state.when(
          initial: () => const LoadingView(),
          loading: () => const SkeletonList(),
          error: (failure) => ErrorView(
            message: failure.message,
            onRetry: () =>
                context.read<SitesBloc>().add(const SitesEvent.fetch()),
          ),
          loaded: (data) => RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (data.fromCache)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Semantics(
                        container: true,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusTile),
                          ),
                          child: Row(
                            children: [
                              ExcludeSemantics(
                                child: Icon(
                                  Icons.cloud_off,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l.offlineBanner,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (data.tenants.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyView(
                      icon: Icons.web_asset_off,
                      title: l.sitesEmpty,
                      message: l.sitesEmptyHint,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    sliver: SliverList.builder(
                      itemCount: data.tenants.length,
                      itemBuilder: (context, i) {
                        final tenant = data.tenants[i];
                        return SiteCard(
                          tenant: tenant,
                          isActive: data.activeSlug == tenant.slug,
                          onTap: () {
                            context
                                .read<SitesBloc>()
                                .add(SitesEvent.select(tenant.slug));
                            _showMessage(
                              l.siteSelected(tenant.name),
                              kind: ToastKind.success,
                            );
                          },
                        );
                      },
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
