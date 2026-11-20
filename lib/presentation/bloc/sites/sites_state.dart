part of 'sites_bloc.dart';

/// Data daftar situs + situs aktif.
class SitesData {
  final List<TenantModel> tenants;

  /// Slug situs aktif (tersimpan bila masih ada di daftar, jika tidak situs pertama).
  final String? activeSlug;

  /// True bila data berasal dari cache (offline-first).
  final bool fromCache;

  /// Galat muat-ulang yang bersifat sesaat (untuk snackbar); data lama tetap tampil.
  final ApiFailure? refreshFailure;

  const SitesData({
    required this.tenants,
    this.activeSlug,
    this.fromCache = false,
    this.refreshFailure,
  });

  TenantModel? get activeTenant {
    for (final t in tenants) {
      if (t.slug == activeSlug) return t;
    }
    return null;
  }

  /// [refreshFailure] sengaja tidak dibawa: ia hanya berlaku untuk satu emisi.
  SitesData copyWith({
    List<TenantModel>? tenants,
    String? activeSlug,
    bool? fromCache,
    ApiFailure? refreshFailure,
  }) =>
      SitesData(
        tenants: tenants ?? this.tenants,
        activeSlug: activeSlug ?? this.activeSlug,
        fromCache: fromCache ?? this.fromCache,
        refreshFailure: refreshFailure,
      );

  static SitesData resolve(
    List<TenantModel> tenants,
    String? persistedSlug, {
    bool fromCache = false,
  }) {
    final hasPersisted = persistedSlug != null &&
        tenants.any((t) => t.slug == persistedSlug);
    return SitesData(
      tenants: tenants,
      activeSlug: hasPersisted
          ? persistedSlug
          : (tenants.isEmpty ? null : tenants.first.slug),
      fromCache: fromCache,
    );
  }
}

@blocFreezed
sealed class SitesState with _$SitesState {
  const factory SitesState.initial() = _Initial;
  const factory SitesState.loading() = _Loading;
  const factory SitesState.loaded(SitesData data) = _Loaded;
  const factory SitesState.error(ApiFailure failure) = _Error;
}
