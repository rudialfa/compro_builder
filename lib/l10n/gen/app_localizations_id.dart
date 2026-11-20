// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Compro Builder';

  @override
  String get retry => 'Coba lagi';

  @override
  String get loading => 'Memuat…';

  @override
  String get emptyDefault => 'Belum ada data';

  @override
  String get errorGeneric => 'Terjadi kesalahan. Silakan coba lagi.';

  @override
  String get loginTitle => 'Masuk';

  @override
  String get loginSubtitle => 'Kelola company profile Anda dari HP.';

  @override
  String get registerTitle => 'Buat akun';

  @override
  String get registerSubtitle => 'Daftar untuk mulai membuat situs Anda.';

  @override
  String get fieldName => 'Nama lengkap';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Kata sandi';

  @override
  String get fieldPasswordConfirm => 'Konfirmasi kata sandi';

  @override
  String get actionLogin => 'Masuk';

  @override
  String get actionRegister => 'Daftar';

  @override
  String get actionLogout => 'Keluar';

  @override
  String get noAccount => 'Belum punya akun? Daftar';

  @override
  String get haveAccount => 'Sudah punya akun? Masuk';

  @override
  String get showPassword => 'Tampilkan kata sandi';

  @override
  String get hidePassword => 'Sembunyikan kata sandi';

  @override
  String get validationRequired => 'Wajib diisi';

  @override
  String get validationEmail => 'Format email tidak valid';

  @override
  String validationPasswordMin(int min) {
    return 'Kata sandi minimal $min karakter';
  }

  @override
  String get validationPasswordMatch => 'Konfirmasi kata sandi tidak sama';

  @override
  String rateLimitedWait(int seconds) {
    return 'Terlalu banyak percobaan. Coba lagi dalam $seconds detik.';
  }

  @override
  String get homeTitle => 'Situs Saya';

  @override
  String homeWelcome(String name) {
    return 'Halo, $name!';
  }

  @override
  String get homePlaceholder => 'Daftar situs akan hadir di Fase 2.';

  @override
  String get sitesEmpty => 'Belum ada situs';

  @override
  String get sitesEmptyHint =>
      'Belum ada situs yang terhubung dengan akun ini. Tarik ke bawah untuk memuat ulang.';

  @override
  String get statusPublished => 'Tayang';

  @override
  String get statusDraft => 'Draft';

  @override
  String planLabel(String plan) {
    return 'Paket $plan';
  }

  @override
  String unreadMessages(int count) {
    return '$count pesan belum dibaca';
  }

  @override
  String get activeSite => 'Situs aktif';

  @override
  String siteSelected(String name) {
    return 'Situs aktif: $name';
  }

  @override
  String get offlineBanner =>
      'Menampilkan data tersimpan. Tarik ke bawah untuk memuat ulang saat online.';

  @override
  String get sectionsTitle => 'Section';

  @override
  String get sectionsEmpty => 'Belum ada section';

  @override
  String usageLabel(int used, int limit) {
    return '$used dari $limit section terpakai';
  }

  @override
  String usageUnlimited(int used) {
    return '$used section';
  }

  @override
  String get addSection => 'Tambah section';

  @override
  String get noAddable => 'Tidak ada section lain yang bisa ditambahkan.';

  @override
  String get limitReached =>
      'Batas jumlah section pada paket Anda sudah tercapai.';

  @override
  String get sectionAdded => 'Section ditambahkan';

  @override
  String get sampleBadge => 'Contoh';

  @override
  String get lockedTitle => 'Section terkunci';

  @override
  String get lockedMessage =>
      'Section ini hanya tersedia di paket yang lebih tinggi. Upgrade paket untuk membukanya.';

  @override
  String get ok => 'OK';

  @override
  String get moveUp => 'Naikkan';

  @override
  String get moveDown => 'Turunkan';

  @override
  String get moveUpShort => 'Naik';

  @override
  String get moveDownShort => 'Turun';

  @override
  String get orderLabel => 'Urutan';

  @override
  String get reorderHint =>
      'Urutan kartu di sini sama dengan urutan tampil di website. Pakai tombol Naik / Turun di tiap kartu untuk mengaturnya.';

  @override
  String reorderPosition(int n, int total) {
    return 'Urutan $n dari $total';
  }

  @override
  String get reorderMoveTo => 'Pindah ke…';

  @override
  String get reorderSheetTitle => 'Pindahkan ke urutan berapa?';

  @override
  String get reorderSheetHint =>
      'Pilih posisi baru. Kartu lain akan bergeser otomatis.';

  @override
  String get reorderCurrent => 'Sekarang';

  @override
  String reorderMoved(int n) {
    return 'Dipindah ke urutan $n';
  }

  @override
  String get accountStatSites => 'Situs';

  @override
  String get accountStatUnread => 'Pesan baru';

  @override
  String get accountActiveSite => 'Situs aktif';

  @override
  String get accountOpenSite => 'Buka';

  @override
  String get accountCopyLink => 'Salin';

  @override
  String get accountShare => 'Bagikan';

  @override
  String get accountSwitchSite => 'Ganti situs';

  @override
  String get accountManageTitle => 'Kelola situs';

  @override
  String get accountMoreTitle => 'Lainnya';

  @override
  String get accountAbout => 'Tentang aplikasi';

  @override
  String get accountAboutText =>
      'Compro Builder membantu Anda membuat website company profile sendiri tanpa perlu coding.';

  @override
  String get accountEmailCopied => 'Email disalin';

  @override
  String accountPlanName(String name) {
    return 'Paket $name';
  }

  @override
  String accountUnreadCount(int n) {
    return '$n pesan belum dibaca';
  }

  @override
  String get accountNoUnread => 'Tidak ada pesan baru';

  @override
  String get accountMenuBillingDesc =>
      'Perpanjang paket dan lihat riwayat bayar';

  @override
  String get accountMenuSettingsDesc => 'Nama, kontak, dan info situs';

  @override
  String get accountMenuThemeDesc => 'Ganti warna tampilan situs';

  @override
  String get visibilityToggle => 'Tampilkan section';

  @override
  String get deleteConfirmTitle => 'Hapus section?';

  @override
  String deleteConfirmMessage(String name) {
    return 'Section “$name” akan dihapus permanen.';
  }

  @override
  String get actionDelete => 'Hapus';

  @override
  String get actionCancel => 'Batal';

  @override
  String get actionSave => 'Simpan';

  @override
  String get saved => 'Perubahan tersimpan';

  @override
  String uploading(int percent) {
    return 'Mengunggah… $percent%';
  }

  @override
  String get pickCamera => 'Kamera';

  @override
  String get pickGallery => 'Galeri';

  @override
  String get chooseImage => 'Pilih gambar';

  @override
  String get removeImage => 'Hapus gambar';

  @override
  String imageTooLarge(int kb) {
    return 'Ukuran gambar masih melebihi $kb KB.';
  }

  @override
  String get addRow => 'Tambah baris';

  @override
  String get removeRow => 'Hapus baris';

  @override
  String rowLabel(String label, int n) {
    return '$label $n';
  }

  @override
  String validationMaxLength(int max) {
    return 'Maksimal $max karakter';
  }

  @override
  String validationMaxItems(int max) {
    return 'Maksimal $max baris';
  }

  @override
  String unsupportedField(String label) {
    return 'Isian “$label” belum didukung di aplikasi ini.';
  }

  @override
  String get fieldsEmpty => 'Section ini tidak punya isian.';

  @override
  String get validationColor => 'Pakai format #RRGGBB, contoh #1D2B5F';

  @override
  String get selectChoose => 'Pilih salah satu';

  @override
  String get markdownPreview => 'Pratinjau';

  @override
  String get markdownPreviewEmpty => 'Belum ada isi untuk dipratinjau.';

  @override
  String get settingsDisplay => 'Tampilan situs';

  @override
  String get settingsMultipage => 'Mode multi-halaman';

  @override
  String get settingsMultipageHint =>
      'Tiap section tampil di halamannya sendiri, bukan satu halaman panjang.';

  @override
  String get settingsMultipageLocked =>
      'Belum tersedia di paketmu. Tingkatkan paket untuk memakainya.';

  @override
  String get settingsTitle => 'Pengaturan situs';

  @override
  String get settingsGeneral => 'Umum';

  @override
  String get settingsSiteName => 'Nama situs';

  @override
  String get settingsLogo => 'Logo';

  @override
  String get settingsFavicon => 'Favicon';

  @override
  String get settingsSeo => 'SEO';

  @override
  String get settingsSeoTitle => 'Judul SEO';

  @override
  String get settingsSeoDescription => 'Deskripsi SEO';

  @override
  String get settingsSocial => 'Tautan sosial';

  @override
  String get settingsSocialHint =>
      'Isi tautan lengkap, mis. https://instagram.com/akun';

  @override
  String get settingsNotify => 'Notifikasi';

  @override
  String get settingsNotifyEmail => 'Email notifikasi pesan';

  @override
  String get settingsTheme => 'Warna tema';

  @override
  String get themeBrand => 'Brand';

  @override
  String get themeBright => 'Cerah';

  @override
  String get themeSoft => 'Lembut';

  @override
  String get settingsNoChanges => 'Belum ada perubahan';

  @override
  String get publishTitle => 'Publikasi';

  @override
  String get publishStatusPublished =>
      'Situs Anda sedang tayang dan bisa dilihat pengunjung.';

  @override
  String get publishStatusDraft =>
      'Situs Anda masih draft dan belum bisa dilihat pengunjung.';

  @override
  String get publishStatusUnknown => 'Status situs belum diketahui.';

  @override
  String get publishActionPublish => 'Tayangkan situs';

  @override
  String get publishActionDraft => 'Jadikan draft';

  @override
  String get checklistTitle => 'Kelengkapan situs';

  @override
  String get checklistAllGood => 'Semua section yang tampil sudah terisi.';

  @override
  String get checklistNoSections => 'Belum ada section yang ditampilkan.';

  @override
  String get checklistSample => 'Masih berisi contoh';

  @override
  String checklistMissing(String fields) {
    return 'Wajib diisi: $fields';
  }

  @override
  String get publishConfirmIssuesTitle => 'Tayangkan sekarang?';

  @override
  String publishConfirmIssues(int count) {
    return 'Masih ada $count hal yang belum lengkap. Tetap tayangkan?';
  }

  @override
  String get publishAnyway => 'Tetap tayangkan';

  @override
  String get publishConfirmDraftTitle => 'Jadikan draft?';

  @override
  String get publishConfirmDraft =>
      'Pengunjung tidak bisa melihat situs sampai Anda menayangkannya lagi.';

  @override
  String get publishedOk => 'Situs sudah tayang';

  @override
  String get draftOk => 'Situs dijadikan draft';

  @override
  String get blockEmailTitle => 'Verifikasi email dulu';

  @override
  String get blockEmailMessage =>
      'Situs baru bisa tayang setelah email Anda terverifikasi. Buka email, klik tautan verifikasi, lalu coba lagi.';

  @override
  String get blockDisabledTitle => 'Situs dinonaktifkan';

  @override
  String get blockDisabledMessage =>
      'Situs ini dinonaktifkan oleh admin. Hubungi admin untuk mengaktifkannya kembali.';

  @override
  String get blockOtherTitle => 'Tidak diizinkan';

  @override
  String get openEmail => 'Buka email';

  @override
  String get contactAdmin => 'Hubungi admin';

  @override
  String get cannotOpenLink => 'Tidak dapat membuka tautan.';

  @override
  String get messagesTitle => 'Pesan masuk';

  @override
  String get messagesEmpty => 'Belum ada pesan masuk.';

  @override
  String get messagesUpgradeTitle => 'Pesan masuk belum tersedia';

  @override
  String get messagesUpgradeMessage =>
      'Fitur pesan masuk tersedia untuk paket Medium ke atas. Tingkatkan paket untuk membaca pesan dari pengunjung situs Anda.';

  @override
  String get messageUnread => 'Belum dibaca';

  @override
  String get markRead => 'Tandai dibaca';

  @override
  String get markUnread => 'Tandai belum dibaca';

  @override
  String get messageDeleteTitle => 'Hapus pesan?';

  @override
  String messageDeleteConfirm(String name) {
    return 'Pesan dari $name akan dihapus permanen.';
  }

  @override
  String get messageDeleted => 'Pesan dihapus';

  @override
  String get replyWhatsapp => 'Balas via WhatsApp';

  @override
  String get replyEmail => 'Balas via email';

  @override
  String get replyCall => 'Telepon';

  @override
  String get loadMoreFailed => 'Gagal memuat pesan berikutnya.';

  @override
  String get messagePhone => 'Telepon';

  @override
  String get messageNotFound => 'Pesan tidak ditemukan.';

  @override
  String waGreeting(String name) {
    return 'Halo $name, terima kasih telah menghubungi kami.';
  }

  @override
  String get replySubject => 'Balasan atas pesan Anda';

  @override
  String get planTitle => 'Paket';

  @override
  String get planCurrent => 'Paket aktif';

  @override
  String get planPrice => 'Harga';

  @override
  String get planValidity => 'Masa berlaku';

  @override
  String get planNoExpiry => 'Tanpa batas waktu';

  @override
  String planExpiresOn(String date) {
    return 'Berlaku sampai $date';
  }

  @override
  String planDaysLeft(int days) {
    return '$days hari lagi';
  }

  @override
  String get planExpiresToday => 'berakhir hari ini';

  @override
  String get planExpired => 'Sudah berakhir';

  @override
  String get planLimits => 'Batas paket';

  @override
  String get planLimitsEmpty => 'Tidak ada informasi batas untuk paket ini.';

  @override
  String get limitUnlimited => 'Tanpa batas';

  @override
  String get valueYes => 'Ya';

  @override
  String get valueNo => 'Tidak';

  @override
  String get planUpgrade => 'Upgrade atau perpanjang';

  @override
  String get planUpgradeHint =>
      'Pilih paket dan bayar langsung di aplikasi. Paket dan masa berlaku diperbarui otomatis setelah pembayaran diterima.';

  @override
  String get planViewPlans => 'Lihat paket';

  @override
  String get planRefreshed => 'Data paket diperbarui';

  @override
  String get previewTitle => 'Pratinjau';

  @override
  String get previewReload => 'Muat ulang';

  @override
  String get previewShare => 'Bagikan tautan situs';

  @override
  String get previewCopy => 'Salin tautan';

  @override
  String get previewOpenBrowser => 'Buka di browser';

  @override
  String get previewCopied => 'Tautan disalin';

  @override
  String get previewLoadFailed =>
      'Pratinjau tidak dapat dimuat. Periksa koneksi internet Anda.';

  @override
  String get previewDraftBanner =>
      'Situs masih draft, jadi pengunjung belum bisa membuka tautannya.';

  @override
  String get previewGoPublish => 'Publikasi';

  @override
  String shareMessage(String name, String url) {
    return 'Kunjungi $name: $url';
  }

  @override
  String get moreActions => 'Menu lainnya';

  @override
  String get dashboardTitle => 'Beranda';

  @override
  String get dashboardLoading => 'Memuat situs...';

  @override
  String get dashboardNoSiteTitle => 'Belum ada situs aktif';

  @override
  String get dashboardNoSiteMessage =>
      'Buka tab Situs dan pilih situs yang ingin dikelola.';

  @override
  String get dashboardSwitchSite => 'Ganti situs';

  @override
  String get dashboardPlanExpiredTitle => 'Paket sudah berakhir';

  @override
  String get dashboardPlanExpiredMessage =>
      'Paket Anda sudah berakhir. Perpanjang supaya fitur paket aktif kembali.';

  @override
  String get dashboardPlanExpiringTitle => 'Paket segera berakhir';

  @override
  String get dashboardPlanExpiresToday =>
      'Paket Anda berakhir hari ini. Perpanjang supaya fitur paket tetap aktif.';

  @override
  String dashboardPlanExpiresIn(int days) {
    return 'Paket Anda berakhir $days hari lagi. Perpanjang supaya fitur paket tetap aktif.';
  }

  @override
  String get dashboardRenew => 'Perpanjang';

  @override
  String get dashboardCheckAndPublish => 'Cek & tayangkan';

  @override
  String get dashboardNeedsWork => 'Perlu dilengkapi';

  @override
  String dashboardMoreItems(int count) {
    return '+$count lainnya';
  }

  @override
  String get dashboardOpenSite => 'Buka situs';

  @override
  String get dashboardStatMessages => 'Pesan';

  @override
  String get dashboardStatPlanDays => 'Paket · hari';

  @override
  String get dashboardStatStatus => 'Status';

  @override
  String get dashboardManageTitle => 'Kelola situs';

  @override
  String completenessPercent(int percent) {
    return '$percent% lengkap';
  }

  @override
  String completenessCounts(int full, int partial, int empty) {
    return '$full lengkap · $partial sebagian · $empty kosong';
  }

  @override
  String get publishConfirmTitle => 'Tayangkan situs?';

  @override
  String get publishConfirm => 'Pengunjung akan bisa melihat situs Anda.';

  @override
  String get checklistSectionUnavailable =>
      'Section belum termuat. Coba lagi sebentar lagi.';

  @override
  String get actionBack => 'Kembali';

  @override
  String get actionNext => 'Lanjut';

  @override
  String get themeTitle => 'Warna situs';

  @override
  String get themeIntro =>
      'Pilih warna yang dipakai di seluruh situs Anda. Pilihan sama dengan dashboard web.';

  @override
  String get themeSaved => 'Warna situs diperbarui';

  @override
  String get themeEmpty => 'Belum ada pilihan warna.';

  @override
  String get onboardingTitle => 'Atur situs Anda';

  @override
  String get onboardingSkip => 'Lewati';

  @override
  String get onboardingSkipTitle => 'Lewati pengaturan awal?';

  @override
  String get onboardingSkipMessage =>
      'Anda tetap bisa mengisi nama, kontak, dan warna nanti lewat Pengaturan, tab Section, dan Warna situs di Beranda.';

  @override
  String get onboardingSkipped => 'Pengaturan awal dilewati';

  @override
  String get onboardingDone => 'Pengaturan awal tersimpan';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Langkah $current dari $total';
  }

  @override
  String get onboardingBusinessTitle => 'Tentang usaha Anda';

  @override
  String get onboardingBusinessHint =>
      'Nama dan kalimat singkat ini tampil di bagian paling atas situs.';

  @override
  String get onboardingName => 'Nama usaha';

  @override
  String get onboardingSubtitle => 'Kalimat singkat (opsional)';

  @override
  String get onboardingSubtitleHelp =>
      'Tampil di bawah nama usaha. Kosongkan untuk memakai teks contoh.';

  @override
  String get onboardingContactTitle => 'Kontak';

  @override
  String get onboardingContactHint =>
      'Pengunjung bisa langsung menghubungi Anda lewat WhatsApp.';

  @override
  String get onboardingWhatsapp => 'Nomor WhatsApp (opsional)';

  @override
  String get onboardingWhatsappHelp =>
      'Contoh: 0812 3456 7890. Awalan 0 diubah ke 62 otomatis.';

  @override
  String get onboardingWhatsappInvalid =>
      'Nomor tidak valid. Contoh: 0812 3456 7890.';

  @override
  String get onboardingThemeTitle => 'Pilih warna';

  @override
  String get onboardingThemeHint =>
      'Warna ini dipakai di seluruh situs dan bisa diganti kapan saja.';

  @override
  String get onboardingFinish => 'Selesai';

  @override
  String get onboardingCardTitle => 'Lengkapi pengaturan awal';

  @override
  String get onboardingCardMessage =>
      'Isi nama, kontak WhatsApp, dan warna situs dalam 3 langkah singkat.';

  @override
  String get onboardingStart => 'Mulai';

  @override
  String get templateTitle => 'Template tampilan';

  @override
  String get templateIntro =>
      'Pilih tampilan situs Anda. Isi situs tidak berubah saat template diganti.';

  @override
  String get templateEmpty => 'Belum ada template.';

  @override
  String get templateActive => 'Dipakai';

  @override
  String get templateTierClassic => 'Classic';

  @override
  String get templateTierMedium => 'Medium';

  @override
  String get templateTierPro => 'Pro';

  @override
  String templateLockedPlan(String plan) {
    return 'Tersedia di paket $plan';
  }

  @override
  String get templatePreview => 'Pratinjau';

  @override
  String get templateUse => 'Pakai';

  @override
  String get templateConfirmTitle => 'Ganti template?';

  @override
  String templateConfirmMessage(String name) {
    return 'Tampilan situs akan berganti ke $name. Isi situs Anda tidak berubah.';
  }

  @override
  String templateApplied(String name) {
    return 'Tampilan diganti ke $name';
  }

  @override
  String templateChosenInactive(String chosen, String active) {
    return 'Template pilihan Anda ($chosen) belum aktif karena paket belum mencukupi. Situs memakai $active sampai paket di-upgrade.';
  }

  @override
  String get templatePreviewFailed =>
      'Pratinjau tidak dapat dimuat atau tautannya sudah kedaluwarsa. Tutup lalu buka pratinjau lagi.';

  @override
  String get addressTitle => 'Alamat website';

  @override
  String get addressIntro =>
      'Alamat ini dipakai pengunjung untuk membuka situs Anda. Setelah diganti, link lama berhenti berfungsi.';

  @override
  String get addressCurrent => 'Alamat sekarang';

  @override
  String get addressInputLabel => 'Alamat baru';

  @override
  String get addressInputHint => 'contoh: kopikita';

  @override
  String get addressChecking => 'Memeriksa…';

  @override
  String get addressEmptyHelp => 'Tulis alamat yang Anda inginkan.';

  @override
  String addressUseSuggestion(String slug) {
    return 'Pakai $slug';
  }

  @override
  String get addressSubmit => 'Ganti alamat';

  @override
  String get addressConfirmTitle => 'Ganti alamat website?';

  @override
  String addressConfirmMessage(String oldUrl, String newUrl) {
    return 'Link lama ($oldUrl) akan berhenti berfungsi. Link baru: $newUrl. Bagikan ulang ke pelanggan Anda.';
  }

  @override
  String addressSaved(String slug) {
    return 'Alamat diganti ke $slug';
  }

  @override
  String get domainTitle => 'Domain sendiri';

  @override
  String get domainCurrentUrl => 'Alamat situs saat ini';

  @override
  String get domainLocked =>
      'Domain sendiri belum tersedia di paket Anda. Upgrade paket untuk memakainya.';

  @override
  String get domainNotReady =>
      'Server belum siap menerima domain sendiri. Coba lagi nanti.';

  @override
  String get domainNone => 'Belum ada domain sendiri';

  @override
  String get domainNoneHint => 'Daftarkan domain Anda lewat dashboard web.';

  @override
  String get domainStatusActive => 'Aktif';

  @override
  String get domainStatusPending => 'Menunggu verifikasi';

  @override
  String get domainStatusVerifiedInactive =>
      'Terverifikasi, tetapi paket tidak mengizinkan';

  @override
  String get domainDnsTitle => 'Pengaturan DNS';

  @override
  String get domainDnsHint =>
      'Tambahkan record berikut di pengelola DNS domain Anda, lalu cek verifikasi lewat dashboard web.';

  @override
  String get domainDnsTxtName => 'TXT: nama';

  @override
  String get domainDnsTxtValue => 'TXT: isi';

  @override
  String get domainDnsA => 'A: alamat server';

  @override
  String get domainDnsCname => 'CNAME: tujuan';

  @override
  String get domainCopied => 'Disalin';

  @override
  String get domainManageWeb => 'Kelola di web';

  @override
  String get domainWebHint =>
      'Menyetel, memverifikasi, dan melepas domain dilakukan di dashboard web. Setelah selesai, kembali ke aplikasi dan status diperbarui otomatis.';

  @override
  String get domainCopy => 'Salin';

  @override
  String get billingTitle => 'Paket dan pembayaran';

  @override
  String get billingHistoryTitle => 'Riwayat pembayaran';

  @override
  String get billingHistoryEmpty => 'Belum ada pembayaran.';

  @override
  String get billingLoadMore => 'Muat lebih banyak';

  @override
  String get billingEmailUnverifiedTitle => 'Verifikasi email dulu';

  @override
  String get billingEmailUnverifiedMessage =>
      'Membeli paket butuh email yang sudah terverifikasi. Buka tautan verifikasi di email Anda, lalu tarik layar ini ke bawah untuk memuat ulang.';

  @override
  String get billingPendingTitle => 'Pembayaran menunggu';

  @override
  String billingPendingMessage(String plan, String amount) {
    return '$plan · $amount. Lanjutkan pembayaran atau pilih paket lain.';
  }

  @override
  String get billingContinuePay => 'Lanjutkan pembayaran';

  @override
  String get billingPeriod => 'Lama langganan';

  @override
  String get billingPlansTitle => 'Pilih paket';

  @override
  String get billingNoPlans => 'Belum ada paket yang tersedia.';

  @override
  String get billingCreating => 'Membuat tagihan…';

  @override
  String get billingOpenWeb => 'Buka halaman tagihan di web';

  @override
  String get billingFree => 'Gratis';

  @override
  String get billingCurrentBadge => 'Paket aktif';

  @override
  String billingForPeriod(String period) {
    return 'untuk $period';
  }

  @override
  String get billingRenew => 'Perpanjang';

  @override
  String get billingBuy => 'Pilih paket';

  @override
  String get billingPayTitle => 'Pembayaran';

  @override
  String billingPlanMonths(String plan, int months) {
    return '$plan · $months bulan';
  }

  @override
  String billingOrderNumber(String number) {
    return 'No. tagihan $number';
  }

  @override
  String get billingChooseMethod => 'Pilih metode pembayaran';

  @override
  String get billingTimedOut =>
      'Batas waktu tagihan sebelumnya sudah habis. Pilih metode pembayaran lagi.';

  @override
  String get billingChangeMethod => 'Ganti metode';

  @override
  String get billingPayWeb => 'Bayar lewat web';

  @override
  String get billingWebHint =>
      'Tagihan ini dibayar di situs web. Setelah selesai, kembali ke aplikasi dan status diperbarui otomatis.';

  @override
  String get billingWebUnavailable =>
      'Tautan pembayaran tidak tersedia. Buka halaman tagihan di web dari daftar paket.';

  @override
  String get billingInstructionsTitle => 'Selesaikan pembayaran';

  @override
  String get billingDetailsMissing =>
      'Rincian pembayaran tidak tersedia. Pilih metode lain.';

  @override
  String get billingVaBank => 'Bank';

  @override
  String get billingVaNumber => 'Nomor virtual account';

  @override
  String get billingBillerCode => 'Kode perusahaan (biller)';

  @override
  String get billingBillKey => 'Kode pembayaran';

  @override
  String get billingQrHint =>
      'Pindai kode QR ini dengan aplikasi bank atau dompet digital yang mendukung QRIS.';

  @override
  String get billingQrSemantics => 'Kode QR pembayaran';

  @override
  String get billingQrMissing => 'Kode QR tidak tersedia. Pilih metode lain.';

  @override
  String billingPayBefore(String date) {
    return 'Bayar sebelum $date';
  }

  @override
  String billingTimeLeft(String time) {
    return 'Sisa waktu $time';
  }

  @override
  String get billingWaiting =>
      'Menunggu pembayaran. Status diperiksa otomatis.';

  @override
  String get billingCheckStatus => 'Cek status pembayaran';

  @override
  String get billingCopy => 'Salin';

  @override
  String get billingCopied => 'Disalin';

  @override
  String get billingPaidTitle => 'Pembayaran berhasil';

  @override
  String billingPaidMessage(String plan) {
    return 'Paket $plan sudah aktif.';
  }

  @override
  String get billingPaidDone => 'Selesai';

  @override
  String get billingPaidSnack => 'Pembayaran diterima. Paket diperbarui.';

  @override
  String get billingClosedTitle => 'Tagihan sudah tidak aktif';

  @override
  String get billingClosedMessage => 'Buat tagihan baru dari halaman paket.';

  @override
  String get billingBackToPlans => 'Kembali ke daftar paket';

  @override
  String get billingStatusPaid => 'Lunas';

  @override
  String get billingStatusPending => 'Menunggu pembayaran';

  @override
  String get billingStatusFailed => 'Gagal';

  @override
  String get billingStatusExpired => 'Kedaluwarsa';

  @override
  String get accountEmailLabel => 'Email';

  @override
  String get accountShowPassword => 'Tampilkan password';

  @override
  String get accountHidePassword => 'Sembunyikan password';

  @override
  String accountResendWait(int seconds) {
    return 'Kirim ulang dalam $seconds dtk';
  }

  @override
  String get accountResendVerification => 'Kirim ulang tautan verifikasi';

  @override
  String get accountResendSending => 'Mengirim…';

  @override
  String get forgotTitle => 'Lupa password';

  @override
  String get forgotIntro =>
      'Masukkan email akun Anda. Kami akan mengirim tautan untuk mengatur ulang password.';

  @override
  String get forgotSubmit => 'Kirim tautan';

  @override
  String get forgotResend => 'Kirim ulang tautan';

  @override
  String get forgotSentTitle => 'Cek email Anda';

  @override
  String get forgotHaveLink => 'Saya sudah punya tautan atau kode';

  @override
  String get forgotBack => 'Kembali ke halaman masuk';

  @override
  String get resetTitle => 'Atur ulang password';

  @override
  String get resetIntro =>
      'Salin tautan dari email atur ulang (atau kodenya), tempel di sini, lalu buat password baru. Tautan hanya berlaku sementara.';

  @override
  String get resetTokenLabel => 'Tautan atau kode dari email';

  @override
  String get resetPaste => 'Tempel dari papan klip';

  @override
  String get resetPasswordLabel => 'Password baru';

  @override
  String get resetConfirmLabel => 'Ulangi password baru';

  @override
  String get resetSubmit => 'Atur ulang password';

  @override
  String get authEmailRequired => 'Email wajib diisi.';

  @override
  String get authEmailInvalid => 'Format email belum benar.';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordRequired => 'Password wajib diisi.';

  @override
  String get authForgotLink => 'Lupa password?';

  @override
  String authRetryIn(int seconds) {
    return 'Coba lagi dalam $seconds dtk';
  }

  @override
  String get registerHeading => 'Buat akun pemilik situs';

  @override
  String get registerNameLabel => 'Nama';

  @override
  String get registerNameRequired => 'Nama wajib diisi.';

  @override
  String get registerNameMax => 'Nama maksimal 100 karakter.';

  @override
  String get registerCompanyRequired => 'Nama usaha wajib diisi.';

  @override
  String get registerCompanyMax => 'Nama usaha maksimal 100 karakter.';

  @override
  String get registerSlugLabel => 'Alamat situs (opsional)';

  @override
  String get registerSlugHelper =>
      'Kosongkan untuk dibuat otomatis dari nama usaha.';

  @override
  String get registerSlugLength => 'Alamat 3 sampai 40 karakter.';

  @override
  String get registerSlugChars => 'Hanya huruf kecil, angka, dan tanda hubung.';

  @override
  String get registerPasswordHelper => 'Minimal 8 karakter.';

  @override
  String get registerPasswordMin => 'Password minimal 8 karakter.';

  @override
  String get registerConfirmLabel => 'Ulangi password';

  @override
  String get registerConfirmMismatch => 'Konfirmasi password tidak sama.';

  @override
  String get registerCreated =>
      'Akun dibuat. Cek email Anda untuk verifikasi sebelum menayangkan situs.';

  @override
  String get shellLoggingOut => 'Keluar...';

  @override
  String get shellTabSites => 'Situs';

  @override
  String get shellTabAccount => 'Akun';

  @override
  String get accountLogoutTitle => 'Keluar?';

  @override
  String get accountLogoutMessage =>
      'Anda perlu masuk lagi untuk mengelola situs.';

  @override
  String get accountEmailUnverifiedTitle => 'Email belum diverifikasi';

  @override
  String get accountEmailUnverifiedMessage =>
      'Verifikasi email dibutuhkan untuk menayangkan situs.';

  @override
  String get accountEmailVerified => 'Email terverifikasi';

  @override
  String get statusDisabled => 'Nonaktif';

  @override
  String get sessionExpired => 'Sesi berakhir. Silakan masuk kembali.';
}
