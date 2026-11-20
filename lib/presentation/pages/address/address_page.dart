import 'package:compro_builder/core/config/env.dart';
import 'package:compro_builder/core/l10n/l10n.dart';
import 'package:compro_builder/core/utils/site_urls.dart';
import 'package:compro_builder/data/datasources/address_remote_datasource.dart';
import 'package:compro_builder/presentation/bloc/address/address_bloc.dart';
import 'package:compro_builder/presentation/bloc/sites/sites_bloc.dart';
import 'package:compro_builder/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Ganti alamat website (slug). Aturan dan pengecekan dari server (cek live);
/// konfirmasi dulu karena link lama berhenti berfungsi. Hasilnya (tenantSummary
/// dengan slug baru) diteruskan ke [SitesBloc], yang ikut memindahkan situs aktif.
class AddressPage extends StatelessWidget {
  final String slug;
  const AddressPage({super.key, required this.slug});

  static Future<void> open(BuildContext context, {required String slug}) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddressPage(slug: slug)),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddressBloc(AddressRemoteDatasource(), slug: slug),
      child: _AddressView(slug: slug),
    );
  }
}

class _AddressView extends StatefulWidget {
  final String slug;
  const _AddressView({required this.slug});

  @override
  State<_AddressView> createState() => _AddressViewState();
}

class _AddressViewState extends State<_AddressView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snack(String message, {ToastKind kind = ToastKind.info}) {
    showToast(message, kind: kind);
  }

  void _onState(BuildContext context, AddressState state) {
    final data = state.when(ready: (d) => d);
    final tenant = data.savedTenant;
    if (tenant != null) {
      context.read<SitesBloc>().add(SitesEvent.tenantUpdated(tenant));
      _snack(context.l10n.addressSaved(tenant.slug), kind: ToastKind.success);
      Navigator.of(context).pop();
      return;
    }
    final failure = data.saveFailure;
    if (failure != null) _snack(failure.errorFor('slug') ?? failure.message, kind: ToastKind.error);
  }

  Future<void> _confirm(BuildContext context, String newSlug) async {
    final l = context.l10n;
    final bloc = context.read<AddressBloc>();
    final oldUrl = siteUrl(Env.siteBaseUrl, widget.slug);
    final newUrl = siteUrl(Env.siteBaseUrl, newSlug);
    final ok = await showConfirmDialog(
      context,
      title: l.addressConfirmTitle,
      message: l.addressConfirmMessage(oldUrl, newUrl),
      confirmLabel: l.addressSubmit,
    );
    if (ok && !bloc.isClosed) bloc.add(const AddressEvent.submit());
  }

  /// Teks bantu / galat di bawah isian, dari jawaban server.
  ({String? helper, String? error, bool good}) _feedback(
    BuildContext context,
    AddressViewData d,
  ) {
    final l = context.l10n;
    if (d.input.trim().isEmpty) {
      return (helper: l.addressEmptyHelp, error: null, good: false);
    }
    if (d.checking) return (helper: l.addressChecking, error: null, good: false);
    final failure = d.checkFailure;
    if (failure != null) return (helper: null, error: failure.message, good: false);
    final c = d.check;
    if (c == null) return (helper: null, error: null, good: false);
    return c.ok
        ? (helper: c.message, error: null, good: true)
        : (helper: null, error: c.message, good: false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final host = Uri.tryParse(Env.siteBaseUrl)?.host ?? '';

    return BlocConsumer<AddressBloc, AddressState>(
      listener: _onState,
      builder: (context, state) {
        final d = state.when(ready: (d) => d);
        final fb = _feedback(context, d);
        final suggestion = d.checkMatchesInput && !(d.check?.ok ?? false)
            ? d.check?.suggestion
            : null;

        return Scaffold(
          appBar: AppBar(title: Text(l.addressTitle)),
          body: SafeArea(
            child: Column(
              children: [
                if (d.isSaving) const LinearProgressIndicator(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        l.addressIntro,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(Icons.link),
                          title: Text(l.addressCurrent),
                          subtitle: SelectableText('$host/${widget.slug}'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _controller,
                        enabled: !d.isSaving,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: l.addressInputLabel,
                          hintText: l.addressInputHint,
                          prefixText: '$host/',
                          helperText: fb.helper,
                          helperStyle: fb.good
                              ? TextStyle(color: scheme.primary)
                              : null,
                          errorText: fb.error,
                          errorMaxLines: 3,
                          suffixIcon: d.checking
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : (fb.good
                                  ? Icon(Icons.check_circle, color: scheme.primary)
                                  : null),
                        ),
                        onChanged: (v) =>
                            context.read<AddressBloc>().add(AddressEvent.changed(v)),
                      ),
                      if (suggestion != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ActionChip(
                            avatar: const Icon(Icons.lightbulb_outline, size: 18),
                            label: Text(l.addressUseSuggestion(suggestion)),
                            onPressed: d.isSaving
                                ? null
                                : () {
                                    _controller.text = suggestion;
                                    _controller.selection =
                                        TextSelection.collapsed(
                                          offset: suggestion.length,
                                        );
                                    context.read<AddressBloc>().add(
                                      AddressEvent.changed(suggestion),
                                    );
                                  },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: d.canSubmit
                          ? () => _confirm(context, d.check!.slug)
                          : null,
                      child: Text(l.addressSubmit),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
