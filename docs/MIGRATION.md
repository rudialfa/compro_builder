# Migrasi compro_builder: Riverpod + Dio + go_router → Bloc + Datasource + Either + http + Navigator

Acuan arsitektur: `lib.zip` (hanya polanya). Backend (`compro-builder-universal`) adalah sumber kebenaran API.
Satu fase per langkah; hapus file lama hanya setelah padanan barunya berjalan.

## Status fase

- [x] **Fase 0** – Audit + wiring (`main.dart` Bloc + Navigator, satu sumber token, sesi berakhir → login)
- [x] **Fase 1** – Auth (login, register, logout, profile, token di flutter_secure_storage)
- [x] **B1** – Backend: `company_name` + `slug` pada `POST /api/auth/register` (+ form register Flutter)
- [x] **Fase 2** – Sites + shell
- [ ] **Fase 3** – Sections (list/detail/add/toggle/move/delete/update, dynamic form, upload gambar, cache)
- [ ] **Fase 4** – Settings, Plan, Messages, Publish, Preview
- [ ] **Fase 5** – Pembersihan (hapus `features/`, `core/network`, `core/router`, riverpod, go_router, dio, freezed/build_runner)

## Peta file lama → baru

| Fitur | File lama (`lib/features/*`) | Datasource | Model | Bloc | Page | Fase |
|---|---|---|---|---|---|---|
| Auth | auth/data/auth_repository, auth/presentation/auth_controller, auth/domain/app_user*, login/register/splash | `data/datasources/auth_remote_datasource`, `auth_local_datasource` | `data/model/request/{login,register}_request_model`, `response/auth_response_model` | `presentation/auth/bloc/{login,logout,profile,register}` | `presentation/auth/*`, `presentation/splash_page` | 1 ✅ |
| Sites | sites/data/{sites_repository,sites_cache}, sites/domain/tenant, sites/presentation/{sites_controller,sites_page,widgets/site_card} | `SitesRemoteDatasource`, `SitesLocalDatasource` | `TenantModel` (+ `PlanSummaryModel`) | `SitesBloc` (global) | `pages/sites/sites_page`, `widgets/site_card` | 2 |
| Shell | core/router (`/sites`) | – | – | – | `bottom_navbar/main_shell_page` | 2 |
| Sections | sections/data/{sections_repository,sections_cache}, sections/domain/{section,field_def}, sections/presentation/{sections_controller,sections_page,section_editor_page,widgets/*,dynamic_form/*} | `SectionsRemoteDatasource`, `SectionsLocalDatasource` | `SectionModel`, `FieldDefModel`, `SectionsDataModel` | `SectionsBloc`, `SectionEditorBloc` (per halaman) | `pages/sections/*` (+ dynamic form di `pages/sections/dynamic_form/`) | 3 |
| Settings | settings/data/{settings_repository,settings_payload}, settings/domain/site_settings, settings/presentation/* | `SettingsRemoteDatasource` | `SiteSettingsModel` | `SettingsBloc` | `pages/settings/settings_page` | 4 |
| Plan | plan/data/plan_repository, plan/domain/plan_info, plan/presentation/* | `PlanRemoteDatasource` | `PlanInfoModel` | `PlanBloc` | `pages/plan/plan_page` | 4 |
| Messages | messages/data/messages_repository, messages/domain/{contact_message,reply_links}, messages/presentation/* | `MessagesRemoteDatasource` | `ContactMessageModel`, `MessagesPageModel` (meta) | `MessagesBloc`, `MessageDetailBloc` | `pages/messages/*` | 4 |
| Publish | publish/data/publish_repository, publish/domain/publish_checklist, publish/presentation/* | `PublishRemoteDatasource` | memakai `TenantModel` | `PublishBloc` | `pages/publish/publish_page` | 4 |
| Preview | preview/presentation/preview_page | – | – | – | `pages/preview/preview_page` (webview_flutter) | 4 |
| Routing | core/router/app_router, app.dart | – | – | – | `Navigator` + `MaterialPageRoute` | 0 (main) / 5 (hapus) |
| Jaringan/token lama | core/network/*, core/storage/token_storage | – | – | – | – | 5 (hapus) |

## Catatan Fase 0

- Token: satu sumber kebenaran = `AuthLocalDatasource`. `SecureTokenStorage` (kode lama) hanya meneruskan ke sana, tanpa cache memori sendiri.
- `ApiHelper.sessionExpired` didengarkan di `main.dart`: kembali ke `LoginPage` + snackbar.
- `Variables.apiUrl` sekarang membuang `/` di akhir `API_BASE_URL` (sebelumnya bisa jadi `//api`).
- Kode lama (`lib/features`, `core/router`, `core/network`, `app.dart`) masih ada tetapi tidak lagi dipasang dari `main.dart`.

## Hal terbuka

- `unread_messages` pada `tenantSummary` bisa `null` (hanya dimuat di `GET /me/tenants`); model Fase 2 harus toleran.
- Pastikan konfigurasi l10n (`generate: true` / `l10n.yaml`) ada di repo Anda; tidak ada di arsip yang dikirim.

## Catatan B1 (register + situs pertama)

- `POST /api/auth/register` menerima `company_name` (opsional, maks 100) dan `slug` (opsional; 3–40, `^[a-z0-9]+(?:-[a-z0-9]+)*$`, unik, bukan slug terlarang). `slug` tanpa `company_name` ditolak 422.
- Dengan `company_name`: user + tenant dibuat satu transaksi (TenantRegistrar); respons 201 `{user, token, tenant: tenantSummary}`. Tanpa `company_name`: `{user, token}` seperti sebelumnya.
- Flutter: `RegisterRequestModel.companyName/slug`, form register punya "Nama usaha" (wajib di UI) dan "Alamat situs" (opsional); galat 422 `slug` tampil di bawah field. `tenant` di respons belum diparse; daftar situs dimuat `SitesBloc` (Fase 2) dari `GET /me/tenants`.

## Catatan Fase 2 (Sites + shell)

- `SitesRemoteDatasource.tenants()` (`GET /me/tenants`), `SitesLocalDatasource` (cache offline; kunci `cache_tenants` dan `active_slug` sama dengan versi lama), `TenantModel`/`PlanSummaryModel`/`TenantsResponseModel`, `SitesBloc` (global di `main.dart`).
- `SitesBloc`: `fetch` (layar memuat), `refresh` (data lama tetap bila gagal), `select`, `tenantUpdated` (menjaga `unreadMessages` lama bila server mengirim null), `reset` (keluar / sesi berakhir: state + cache dikosongkan, respons yang masih jalan ditolak lewat `_requestId`).
- Offline-first: cache dipakai hanya bila galat tanpa `statusCode` (jaringan/timeout/format); 5xx/403 tidak memakai cache. `SitesData.fromCache` menampilkan banner offline.
- `MainShellPage`: `NavigationBar` (Situs, Akun) + `IndexedStack`; tombol keluar pindah ke tab Akun.
- Perbaikan dari versi lama: `Tenant.fromJson` membaca `unread_count`, padahal backend mengirim `unread_messages`, jadi badge pesan tidak pernah tampil. Model baru membaca `unread_messages` (dan `unread_count` dari cache lama).
- Teks UI Fase 2 ditulis langsung dalam Bahasa Indonesia seperti halaman Fase 1; ARB tidak diubah.
- Fase 3: cache section juga harus dikosongkan oleh alur `reset` (versi lama mengosongkan `sectionsCache` saat keluar).
- Dev dependency baru: `bloc_test` (untuk test `SitesBloc`); pasang dengan `flutter pub add --dev bloc_test`.
