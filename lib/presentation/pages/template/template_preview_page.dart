import 'dart:async';

import 'package:compro_builder/core/helper/link_opener.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Pratinjau SATU template di WebView memakai URL bertanda tangan dari server
/// (preview-link, berlaku 10 menit). Tidak membawa header Authorization dan
/// tidak ada yang disimpan. Hanya halaman pratinjau itu yang dimuat di sini;
/// tautan lain dibuka di aplikasi luar.
class TemplatePreviewPage extends StatefulWidget {
  final String name;
  final String url;

  /// Template terkunci (paket belum cukup) / sedang dipakai.
  final bool locked;
  final bool active;

  /// Aksi di bilah bawah. Layar ini ditutup dulu, baru aksinya dijalankan.
  final VoidCallback? onUse;
  final VoidCallback? onUpgrade;

  const TemplatePreviewPage({
    super.key,
    required this.name,
    required this.url,
    this.locked = false,
    this.active = false,
    this.onUse,
    this.onUpgrade,
  });

  static Future<void> open(
    BuildContext context, {
    required String name,
    required String url,
    bool locked = false,
    bool active = false,
    VoidCallback? onUse,
    VoidCallback? onUpgrade,
  }) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => TemplatePreviewPage(
        name: name,
        url: url,
        locked: locked,
        active: active,
        onUse: onUse,
        onUpgrade: onUpgrade,
      ),
    ),
  );

  @override
  State<TemplatePreviewPage> createState() => _TemplatePreviewPageState();
}

class _TemplatePreviewPageState extends State<TemplatePreviewPage> {
  late final WebViewController _web;
  late final Uri _uri;
  int _progress = 0;
  bool _failed = false;
  bool _loaded = false;

  /// Rincian galat; hanya tampil pada build debug.
  String? _errorDetail;

  @override
  void initState() {
    super.initState();
    _uri = Uri.parse(widget.url);
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _failed = false);
          },
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loaded = true);
          },
          onWebResourceError: (e) {
            if (e.isForMainFrame != false && mounted) {
              setState(() {
                _failed = true;
                _errorDetail = '${e.errorCode}: ${e.description}';
              });
            }
          },
          // URL bertanda tangan kedaluwarsa dijawab 403 (bukan galat jaringan).
          onHttpError: (e) {
            final isPage = e.request?.uri.path == _uri.path;
            final code = e.response?.statusCode ?? 0;
            if (isPage && code >= 400 && mounted) {
              setState(() {
                _failed = true;
                _errorDetail = 'HTTP $code';
              });
            }
          },
          onNavigationRequest: _onNavigation,
        ),
      );
    unawaited(_web.loadRequest(_uri));
  }

  bool _samePage(Uri u) =>
      u.host.toLowerCase() == _uri.host.toLowerCase() &&
      u.port == _uri.port &&
      u.path == _uri.path;

  NavigationDecision _onNavigation(NavigationRequest req) {
    final uri = Uri.tryParse(req.url);
    if (uri == null) return NavigationDecision.prevent;
    if (!req.isMainFrame) return NavigationDecision.navigate;
    if (uri.scheme == 'about' || _samePage(uri)) {
      return NavigationDecision.navigate;
    }
    // Tautan lain (situs asli, WhatsApp, email, dll.) dibuka di luar; halaman
    // lain tidak punya tanda tangan sehingga tidak bisa dimuat di sini.
    unawaited(openContactLink(uri));
    return NavigationDecision.prevent;
  }

  void _reload() {
    setState(() {
      _failed = false;
      _loaded = false;
      _progress = 0;
    });
    unawaited(_web.loadRequest(_uri));
  }

  void _runAndClose(VoidCallback action) {
    Navigator.of(context).pop();
    // Jalankan setelah layar tertutup supaya dialog konfirmasi muncul di halaman daftar.
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  Widget? _bottomBar(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget? action;
    if (widget.locked && widget.onUpgrade != null) {
      action = FilledButton.icon(
        onPressed: () => _runAndClose(widget.onUpgrade!),
        icon: const Icon(Icons.workspace_premium_outlined, size: 18),
        label: Text(l.planViewPlans),
      );
    } else if (widget.active) {
      action = FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: Text(l.templateActive),
      );
    } else if (widget.onUse != null) {
      action = FilledButton(
        onPressed: () => _runAndClose(widget.onUse!),
        child: Text('${l.templateUse} ${widget.name}'),
      );
    }
    if (action == null) return null;
    return Material(
      elevation: 8,
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SizedBox(width: double.infinity, child: action),
        ),
      ),
    );
  }

  Future<void> _openBrowser() async {
    final ok = await openExternalLink(_uri);
    if (!ok && mounted) {
      showToast(context.l10n.cannotOpenLink, kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text('${l.templatePreview}: ${widget.name}'),
        actions: [
          IconButton(
            tooltip: l.previewReload,
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          IconButton(
            tooltip: l.previewOpenBrowser,
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openBrowser,
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
      bottomNavigationBar: _bottomBar(context),
      body: _failed
          ? ErrorView(
              message: kDebugMode && _errorDetail != null
                  ? '${l.templatePreviewFailed}\n\n$_errorDetail'
                  : l.templatePreviewFailed,
              retryLabel: l.actionBack,
              onRetry: () => Navigator.of(context).pop(),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _web),
                // Latar putih + spinner sampai halaman selesai dimuat, supaya
                // pengguna tidak melihat halaman setengah jadi (tanpa gaya).
                if (!_loaded)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.white,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
    );
  }
}
