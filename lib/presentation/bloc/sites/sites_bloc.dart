import 'package:bloc/bloc.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/core/helper/bloc_freezed.dart';
import 'package:compro_builder/data/datasources/sites_local_datasource.dart';
import 'package:compro_builder/data/datasources/sites_remote_datasource.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sites_event.dart';
part 'sites_state.dart';
part 'sites_bloc.freezed.dart';

/// Daftar situs milik pengguna + situs aktif. Global (dipasang di main.dart)
/// karena halaman yang ditumpuk lewat Navigator berada di luar pohon shell.
///
/// Offline-first: bila jaringan gagal (ApiFailure tanpa statusCode) dan ada
/// cache, tampilkan cache dengan `fromCache = true`.
class SitesBloc extends Bloc<SitesEvent, SitesState> {
  final SitesRemoteDatasource remoteDatasource;
  final SitesLocalDatasource localDatasource;

  /// Menolak respons basi (fetch/refresh yang lebih lama, atau sebelum reset).
  int _requestId = 0;

  SitesBloc(this.remoteDatasource, this.localDatasource)
      : super(const SitesState.initial()) {
    on<_Fetch>(_onFetch);
    on<_Refresh>(_onRefresh);
    on<_Select>(_onSelect);
    on<_TenantUpdated>(_onTenantUpdated);
    on<_Reset>(_onReset);
  }

  Future<void> _onFetch(_Fetch event, Emitter<SitesState> emit) async {
    final requestId = ++_requestId;
    emit(const SitesState.loading());
    await _load(requestId, emit, previous: null);
  }

  Future<void> _onRefresh(_Refresh event, Emitter<SitesState> emit) async {
    final requestId = ++_requestId;
    final current = state;
    final previous = current is _Loaded ? current.data : null;
    if (previous == null) emit(const SitesState.loading());
    await _load(requestId, emit, previous: previous);
  }

  Future<void> _load(
    int requestId,
    Emitter<SitesState> emit, {
    required SitesData? previous,
  }) async {
    final result = await remoteDatasource.tenants();
    if (requestId != _requestId) return;

    await result.fold<Future<void>>(
      (failure) async {
        if (previous != null) {
          // Data lama tetap tampil; galat hanya untuk snackbar.
          emit(SitesState.loaded(previous.copyWith(refreshFailure: failure)));
          return;
        }
        if (failure.statusCode == null) {
          final cached = await _readCache();
          if (requestId != _requestId) return;
          if (cached != null) {
            final slug = await _readActiveSlug();
            if (requestId != _requestId) return;
            emit(SitesState.loaded(
              SitesData.resolve(cached, slug, fromCache: true),
            ));
            return;
          }
        }
        emit(SitesState.error(failure));
      },
      (response) async {
        final tenants = response.data;
        await _writeCache(tenants);
        final slug = await _readActiveSlug();
        if (requestId != _requestId) return;
        emit(SitesState.loaded(SitesData.resolve(tenants, slug)));
      },
    );
  }

  Future<void> _onSelect(_Select event, Emitter<SitesState> emit) async {
    final current = state;
    if (current is! _Loaded) return;
    if (!current.data.tenants.any((t) => t.slug == event.slug)) return;
    emit(SitesState.loaded(current.data.copyWith(activeSlug: event.slug)));
    try {
      await localDatasource.writeActiveSlug(event.slug);
    } catch (_) {
      // Gagal menyimpan pilihan tidak boleh mengganggu layar.
    }
  }

  Future<void> _onTenantUpdated(
    _TenantUpdated event,
    Emitter<SitesState> emit,
  ) async {
    final current = state;
    if (current is! _Loaded) return;
    final incoming = event.tenant;

    var replaced = false;
    String? activeSlug = current.data.activeSlug;
    final tenants = current.data.tenants.map((old) {
      final same = (incoming.id != null && old.id != null)
          ? incoming.id == old.id
          : old.slug == incoming.slug;
      if (!same) return old;
      replaced = true;
      if (old.slug == activeSlug) activeSlug = incoming.slug;
      // Respons non-/me/tenants membawa unreadMessages null: pertahankan nilai lama.
      return incoming.copyWith(
        unreadMessages: incoming.unreadMessages ?? old.unreadMessages,
      );
    }).toList(growable: false);
    if (!replaced) return;

    emit(SitesState.loaded(
      current.data.copyWith(tenants: tenants, activeSlug: activeSlug),
    ));
    await _writeCache(tenants);
    // Alamat (slug) situs aktif berganti: simpan juga pilihan aktif, kalau tidak
    // pembukaan berikutnya jatuh ke situs lain karena slug lama sudah tidak ada.
    if (activeSlug != null && activeSlug != current.data.activeSlug) {
      try {
        await localDatasource.writeActiveSlug(activeSlug!);
      } catch (_) {
        // Gagal menyimpan pilihan tidak boleh mengganggu layar.
      }
    }
  }

  Future<void> _onReset(_Reset event, Emitter<SitesState> emit) async {
    _requestId++;
    emit(const SitesState.initial());
    try {
      await localDatasource.clear();
    } catch (_) {
      // Cache gagal dihapus tidak boleh menahan proses keluar.
    }
  }

  Future<List<TenantModel>?> _readCache() async {
    try {
      return await localDatasource.readTenants();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _readActiveSlug() async {
    try {
      return await localDatasource.readActiveSlug();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(List<TenantModel> tenants) async {
    try {
      await localDatasource.writeTenants(tenants);
    } catch (_) {
      // Cache bersifat tambahan; abaikan galat tulis.
    }
  }
}
