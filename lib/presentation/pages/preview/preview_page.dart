import 'dart:async';

import 'package:compro_builder/core/constants/variables.dart';
import 'package:compro_builder/core/helper/link_opener.dart';
import 'package:compro_builder/core/helper/share_helper.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/utils/site_urls.dart';
import 'package:compro_builder/data/datasources/auth_local_datasource.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/presentation/bloc/sections/sections_bloc.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/pages/publish/publish_page.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Pratinjau situs dalam WebView + bagikan tautan. Tanpa datasource/bloc sendiri:
/// tidak ada panggilan API; nama, URL, dan status dibaca dari [SitesBloc].
///
/// Situs draft dijawab 404 untuk pengunjung tanpa sesi. WebView tidak memakai
/// sesi web, jadi untuk draft permintaan PERTAMA membawa header Bearer (backend
/// menerima token Sanctum di semua rute, lihat ResolveTenant). Header hanya
/// dikirim ke host API sendiri.
class PreviewPage extends StatefulWidget {
  final String slug;

  /// Tampilkan tombol "Publikasi" pada banner draft. Matikan bila halaman ini
  /// dibuka dari halaman Publikasi supaya tidak menumpuk dua halaman Publikasi.
  final bool canOpenPublish;

  const PreviewPage({
    super.key,
    required this.slug,
    this.canOpenPublish = true,
  });

  /// [SectionsBloc] diteruskan supaya tombol "Publikasi" bisa membuka [PublishPage].
  static Future<void> open(
    BuildContext context, {
    required String slug,
    bool canOpenPublish = true,
  }) {
    final sectionsBloc = context.read<SectionsBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: sectionsBloc,
          child: PreviewPage(slug: slug, canOpenPublish: canOpenPublish),
        ),
      ),
    );
  }

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  late final WebViewController _web;
  late final String _siteName;
  late final String _url;
  late final Uri _siteUri;
  late final Uri _apiUri;
  late final bool _draftAtOpen;
  int _progress = 0;
  bool _failed = false;

  /// Alamat halaman yang sedang dibuka di WebView (dipakai untuk muat ulang halaman ini, bukan beranda).
  Uri? _currentUri;

  /// Alamat yang sedang dimuat ulang oleh kita sendiri dengan header token (mencegah perulangan pada iOS).
  String? _authLoading;

  /// Rincian galat WebView; hanya ditampilkan pada build debug supaya mudah dilacak.
  String? _errorDetail;

  @override
  void initState() {
    super.initState();
    final tenant = _tenant();
    final base = Variables.apiUrl.replaceFirst(RegExp(r'/api$'), '');
    _apiUri = Uri.parse(base);
    _url = publicSiteUrl(tenant?.url, base, widget.slug);
    _siteUri = Uri.parse(_url);
    _siteName = (tenant?.name.isNotEmpty ?? false) ? tenant!.name : widget.slug;
    _draftAtOpen = tenant?.status == SiteStatus.draft;

    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _authLoading = null;
            _currentUri = Uri.tryParse(url) ?? _currentUri;
            if (mounted) setState(() => _failed = false);
          },
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onWebResourceError: (e) {
            if (e.isForMainFrame != false && mounted) {
              setState(() {
                _failed = true;
                _errorDetail = '${e.errorCode}: ${e.description}\n$_url';
              });
            }
          },
          onNavigationRequest: _onNavigation,
        ),
      );
    unawaited(_load());
  }

  TenantModel? _tenant() => context.read<SitesBloc>().state.maybeWhen(
    loaded: (d) => d.tenants.where((t) => t.slug == widget.slug).firstOrNull,
    orElse: () => null,
  );

  bool _sameHost(Uri a, Uri b) =>
      a.host.toLowerCase() == b.host.toLowerCase() && a.port == b.port;

  NavigationDecision _onNavigation(NavigationRequest req) {
    final uri = Uri.tryParse(req.url);
    if (uri == null) return NavigationDecision.prevent;
    switch (decideNavigation(uri, _siteUri)) {
      case NavDecision.allow:
        // Situs draft: pindah halaman harus membawa token lagi, kalau tidak server menjawab 404.
        if (req.isMainFrame &&
            needsAuthHeader(uri, _apiUri, draft: _draftAtOpen) &&
            !(_currentUri != null && isSamePageIgnoringFragment(uri, _currentUri!))) {
          if (_authLoading == uri.toString()) {
            _authLoading = null; // permintaan ini dari kita sendiri (sudah membawa token)
            return NavigationDecision.navigate;
          }
          unawaited(_loadUri(uri));
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      case NavDecision.external:
        // Alamat situs bisa berpindah antara /slug di host API dan domain sendiri.
        if (_sameHost(uri, _apiUri) &&
            (uri.scheme == 'http' || uri.scheme == 'https')) {
          return NavigationDecision.navigate;
        }
        unawaited(openContactLink(uri));
        return NavigationDecision.prevent;
      case NavDecision.block:
        return NavigationDecision.prevent;
    }
  }

  Future<void> _load() => _loadUri(_siteUri);

  /// Memuat [uri]; untuk situs draft di host API, permintaan membawa token pemilik.
  Future<void> _loadUri(Uri uri) async {
    final headers = <String, String>{};
    if (needsAuthHeader(uri, _apiUri, draft: _draftAtOpen)) {
      final token = await AuthLocalDatasource().getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    if (!mounted) return;
    // iOS memanggil onNavigationRequest juga untuk muatan dari kode; tandai supaya tidak dicegat lagi.
    if (headers.isNotEmpty) _authLoading = uri.toString();
    await _web.loadRequest(uri, headers: headers);
  }

  /// Muat ulang halaman yang sedang dibuka (bukan selalu beranda).
  void _reload() {
    setState(() {
      _failed = false;
      _progress = 0;
    });
    unawaited(_loadUri(_currentUri ?? _siteUri));
  }

  Future<void> _share() => shareText(
    context.l10n.shareMessage(_siteName, _url),
    subject: _siteName,
  );

  Future<void> _copy() async {
    final l = context.l10n;
    await Clipboard.setData(ClipboardData(text: _url));
    if (!mounted) return;
    showToast(l.previewCopied, kind: ToastKind.success);
  }

  Future<void> _openBrowser() async {
    final ok = await openExternalLink(_siteUri);
    if (!ok && mounted) {
      showToast(context.l10n.cannotOpenLink, kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Status terkini (bisa berubah setelah publikasi) untuk banner.
    final draft = context.select<SitesBloc, bool>(
      (b) =>
          b.state.maybeWhen(
            loaded: (d) => d.tenants
                .where((t) => t.slug == widget.slug)
                .firstOrNull
                ?.status,
            orElse: () => null,
          ) ==
          SiteStatus.draft,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Tombol kembali menelusuri riwayat WebView dulu, baru menutup layar.
        if (await _web.canGoBack()) {
          await _web.goBack();
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.previewTitle),
          actions: [
            IconButton(
              tooltip: l.previewReload,
              icon: const Icon(Icons.refresh),
              onPressed: _reload,
            ),
            IconButton(
              tooltip: l.previewShare,
              icon: const Icon(Icons.share_outlined),
              onPressed: _share,
            ),
            PopupMenuButton<String>(
              tooltip: l.moreActions,
              onSelected: (v) => v == 'copy' ? _copy() : _openBrowser(),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'copy',
                  child: ListTile(
                    leading: const Icon(Icons.link),
                    title: Text(l.previewCopy),
                  ),
                ),
                PopupMenuItem(
                  value: 'browser',
                  child: ListTile(
                    leading: const Icon(Icons.open_in_browser),
                    title: Text(l.previewOpenBrowser),
                  ),
                ),
              ],
            ),
          ],
          bottom: _progress < 100 && !_failed
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                  ),
                )
              : null,
        ),
        body: Column(
          children: [
            if (draft)
              MaterialBanner(
                leading: const Icon(Icons.edit_note),
                content: Text(l.previewDraftBanner),
                actions: [
                  if (widget.canOpenPublish)
                    TextButton(
                      onPressed: () =>
                          PublishPage.open(context, slug: widget.slug),
                      child: Text(l.previewGoPublish),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            Expanded(
              child: _failed
                  ? ErrorView(
                      message: kDebugMode && _errorDetail != null
                          ? '${l.previewLoadFailed}\n\n$_errorDetail'
                          : l.previewLoadFailed,
                      onRetry: _reload,
                    )
                  : WebViewWidget(controller: _web),
            ),
          ],
        ),
      ),
    );
  }
}
