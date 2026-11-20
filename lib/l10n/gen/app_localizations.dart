import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('id')];

  /// No description provided for @appName.
  ///
  /// In id, this message translates to:
  /// **'Compro Builder'**
  String get appName;

  /// No description provided for @retry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In id, this message translates to:
  /// **'Memuat…'**
  String get loading;

  /// No description provided for @emptyDefault.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data'**
  String get emptyDefault;

  /// No description provided for @errorGeneric.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan. Silakan coba lagi.'**
  String get errorGeneric;

  /// No description provided for @loginTitle.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Kelola company profile Anda dari HP.'**
  String get loginSubtitle;

  /// No description provided for @registerTitle.
  ///
  /// In id, this message translates to:
  /// **'Buat akun'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Daftar untuk mulai membuat situs Anda.'**
  String get registerSubtitle;

  /// No description provided for @fieldName.
  ///
  /// In id, this message translates to:
  /// **'Nama lengkap'**
  String get fieldName;

  /// No description provided for @fieldEmail.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi'**
  String get fieldPassword;

  /// No description provided for @fieldPasswordConfirm.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi kata sandi'**
  String get fieldPasswordConfirm;

  /// No description provided for @actionLogin.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get actionLogin;

  /// No description provided for @actionRegister.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get actionRegister;

  /// No description provided for @actionLogout.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get actionLogout;

  /// No description provided for @noAccount.
  ///
  /// In id, this message translates to:
  /// **'Belum punya akun? Daftar'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In id, this message translates to:
  /// **'Sudah punya akun? Masuk'**
  String get haveAccount;

  /// No description provided for @showPassword.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan kata sandi'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan kata sandi'**
  String get hidePassword;

  /// No description provided for @validationRequired.
  ///
  /// In id, this message translates to:
  /// **'Wajib diisi'**
  String get validationRequired;

  /// No description provided for @validationEmail.
  ///
  /// In id, this message translates to:
  /// **'Format email tidak valid'**
  String get validationEmail;

  /// No description provided for @validationPasswordMin.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi minimal {min} karakter'**
  String validationPasswordMin(int min);

  /// No description provided for @validationPasswordMatch.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi kata sandi tidak sama'**
  String get validationPasswordMatch;

  /// No description provided for @rateLimitedWait.
  ///
  /// In id, this message translates to:
  /// **'Terlalu banyak percobaan. Coba lagi dalam {seconds} detik.'**
  String rateLimitedWait(int seconds);

  /// No description provided for @homeTitle.
  ///
  /// In id, this message translates to:
  /// **'Situs Saya'**
  String get homeTitle;

  /// No description provided for @homeWelcome.
  ///
  /// In id, this message translates to:
  /// **'Halo, {name}!'**
  String homeWelcome(String name);

  /// No description provided for @homePlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Daftar situs akan hadir di Fase 2.'**
  String get homePlaceholder;

  /// No description provided for @sitesEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada situs'**
  String get sitesEmpty;

  /// No description provided for @sitesEmptyHint.
  ///
  /// In id, this message translates to:
  /// **'Belum ada situs yang terhubung dengan akun ini. Tarik ke bawah untuk memuat ulang.'**
  String get sitesEmptyHint;

  /// No description provided for @statusPublished.
  ///
  /// In id, this message translates to:
  /// **'Tayang'**
  String get statusPublished;

  /// No description provided for @statusDraft.
  ///
  /// In id, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @planLabel.
  ///
  /// In id, this message translates to:
  /// **'Paket {plan}'**
  String planLabel(String plan);

  /// No description provided for @unreadMessages.
  ///
  /// In id, this message translates to:
  /// **'{count} pesan belum dibaca'**
  String unreadMessages(int count);

  /// No description provided for @activeSite.
  ///
  /// In id, this message translates to:
  /// **'Situs aktif'**
  String get activeSite;

  /// No description provided for @siteSelected.
  ///
  /// In id, this message translates to:
  /// **'Situs aktif: {name}'**
  String siteSelected(String name);

  /// No description provided for @offlineBanner.
  ///
  /// In id, this message translates to:
  /// **'Menampilkan data tersimpan. Tarik ke bawah untuk memuat ulang saat online.'**
  String get offlineBanner;

  /// No description provided for @sectionsTitle.
  ///
  /// In id, this message translates to:
  /// **'Section'**
  String get sectionsTitle;

  /// No description provided for @sectionsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada section'**
  String get sectionsEmpty;

  /// No description provided for @usageLabel.
  ///
  /// In id, this message translates to:
  /// **'{used} dari {limit} section terpakai'**
  String usageLabel(int used, int limit);

  /// No description provided for @usageUnlimited.
  ///
  /// In id, this message translates to:
  /// **'{used} section'**
  String usageUnlimited(int used);

  /// No description provided for @addSection.
  ///
  /// In id, this message translates to:
  /// **'Tambah section'**
  String get addSection;

  /// No description provided for @noAddable.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada section lain yang bisa ditambahkan.'**
  String get noAddable;

  /// No description provided for @limitReached.
  ///
  /// In id, this message translates to:
  /// **'Batas jumlah section pada paket Anda sudah tercapai.'**
  String get limitReached;

  /// No description provided for @sectionAdded.
  ///
  /// In id, this message translates to:
  /// **'Section ditambahkan'**
  String get sectionAdded;

  /// No description provided for @sampleBadge.
  ///
  /// In id, this message translates to:
  /// **'Contoh'**
  String get sampleBadge;

  /// No description provided for @lockedTitle.
  ///
  /// In id, this message translates to:
  /// **'Section terkunci'**
  String get lockedTitle;

  /// No description provided for @lockedMessage.
  ///
  /// In id, this message translates to:
  /// **'Section ini hanya tersedia di paket yang lebih tinggi. Upgrade paket untuk membukanya.'**
  String get lockedMessage;

  /// No description provided for @ok.
  ///
  /// In id, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @moveUp.
  ///
  /// In id, this message translates to:
  /// **'Naikkan'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In id, this message translates to:
  /// **'Turunkan'**
  String get moveDown;

  /// No description provided for @moveUpShort.
  ///
  /// In id, this message translates to:
  /// **'Naik'**
  String get moveUpShort;

  /// No description provided for @moveDownShort.
  ///
  /// In id, this message translates to:
  /// **'Turun'**
  String get moveDownShort;

  /// No description provided for @orderLabel.
  ///
  /// In id, this message translates to:
  /// **'Urutan'**
  String get orderLabel;

  /// No description provided for @reorderHint.
  ///
  /// In id, this message translates to:
  /// **'Urutan kartu di sini sama dengan urutan tampil di website. Pakai tombol Naik / Turun di tiap kartu untuk mengaturnya.'**
  String get reorderHint;

  /// No description provided for @reorderPosition.
  ///
  /// In id, this message translates to:
  /// **'Urutan {n} dari {total}'**
  String reorderPosition(int n, int total);

  /// No description provided for @reorderMoveTo.
  ///
  /// In id, this message translates to:
  /// **'Pindah ke…'**
  String get reorderMoveTo;

  /// No description provided for @reorderSheetTitle.
  ///
  /// In id, this message translates to:
  /// **'Pindahkan ke urutan berapa?'**
  String get reorderSheetTitle;

  /// No description provided for @reorderSheetHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih posisi baru. Kartu lain akan bergeser otomatis.'**
  String get reorderSheetHint;

  /// No description provided for @reorderCurrent.
  ///
  /// In id, this message translates to:
  /// **'Sekarang'**
  String get reorderCurrent;

  /// No description provided for @reorderMoved.
  ///
  /// In id, this message translates to:
  /// **'Dipindah ke urutan {n}'**
  String reorderMoved(int n);

  /// No description provided for @accountStatSites.
  ///
  /// In id, this message translates to:
  /// **'Situs'**
  String get accountStatSites;

  /// No description provided for @accountStatUnread.
  ///
  /// In id, this message translates to:
  /// **'Pesan baru'**
  String get accountStatUnread;

  /// No description provided for @accountActiveSite.
  ///
  /// In id, this message translates to:
  /// **'Situs aktif'**
  String get accountActiveSite;

  /// No description provided for @accountOpenSite.
  ///
  /// In id, this message translates to:
  /// **'Buka'**
  String get accountOpenSite;

  /// No description provided for @accountCopyLink.
  ///
  /// In id, this message translates to:
  /// **'Salin'**
  String get accountCopyLink;

  /// No description provided for @accountShare.
  ///
  /// In id, this message translates to:
  /// **'Bagikan'**
  String get accountShare;

  /// No description provided for @accountSwitchSite.
  ///
  /// In id, this message translates to:
  /// **'Ganti situs'**
  String get accountSwitchSite;

  /// No description provided for @accountManageTitle.
  ///
  /// In id, this message translates to:
  /// **'Kelola situs'**
  String get accountManageTitle;

  /// No description provided for @accountMoreTitle.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get accountMoreTitle;

  /// No description provided for @accountAbout.
  ///
  /// In id, this message translates to:
  /// **'Tentang aplikasi'**
  String get accountAbout;

  /// No description provided for @accountAboutText.
  ///
  /// In id, this message translates to:
  /// **'Compro Builder membantu Anda membuat website company profile sendiri tanpa perlu coding.'**
  String get accountAboutText;

  /// No description provided for @accountEmailCopied.
  ///
  /// In id, this message translates to:
  /// **'Email disalin'**
  String get accountEmailCopied;

  /// No description provided for @accountPlanName.
  ///
  /// In id, this message translates to:
  /// **'Paket {name}'**
  String accountPlanName(String name);

  /// No description provided for @accountUnreadCount.
  ///
  /// In id, this message translates to:
  /// **'{n} pesan belum dibaca'**
  String accountUnreadCount(int n);

  /// No description provided for @accountNoUnread.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pesan baru'**
  String get accountNoUnread;

  /// No description provided for @accountMenuBillingDesc.
  ///
  /// In id, this message translates to:
  /// **'Perpanjang paket dan lihat riwayat bayar'**
  String get accountMenuBillingDesc;

  /// No description provided for @accountMenuSettingsDesc.
  ///
  /// In id, this message translates to:
  /// **'Nama, kontak, dan info situs'**
  String get accountMenuSettingsDesc;

  /// No description provided for @accountMenuThemeDesc.
  ///
  /// In id, this message translates to:
  /// **'Ganti warna tampilan situs'**
  String get accountMenuThemeDesc;

  /// No description provided for @visibilityToggle.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan section'**
  String get visibilityToggle;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus section?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In id, this message translates to:
  /// **'Section “{name}” akan dihapus permanen.'**
  String deleteConfirmMessage(String name);

  /// No description provided for @actionDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get actionDelete;

  /// No description provided for @actionCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get actionSave;

  /// No description provided for @saved.
  ///
  /// In id, this message translates to:
  /// **'Perubahan tersimpan'**
  String get saved;

  /// No description provided for @uploading.
  ///
  /// In id, this message translates to:
  /// **'Mengunggah… {percent}%'**
  String uploading(int percent);

  /// No description provided for @pickCamera.
  ///
  /// In id, this message translates to:
  /// **'Kamera'**
  String get pickCamera;

  /// No description provided for @pickGallery.
  ///
  /// In id, this message translates to:
  /// **'Galeri'**
  String get pickGallery;

  /// No description provided for @chooseImage.
  ///
  /// In id, this message translates to:
  /// **'Pilih gambar'**
  String get chooseImage;

  /// No description provided for @removeImage.
  ///
  /// In id, this message translates to:
  /// **'Hapus gambar'**
  String get removeImage;

  /// No description provided for @imageTooLarge.
  ///
  /// In id, this message translates to:
  /// **'Ukuran gambar masih melebihi {kb} KB.'**
  String imageTooLarge(int kb);

  /// No description provided for @addRow.
  ///
  /// In id, this message translates to:
  /// **'Tambah baris'**
  String get addRow;

  /// No description provided for @removeRow.
  ///
  /// In id, this message translates to:
  /// **'Hapus baris'**
  String get removeRow;

  /// No description provided for @rowLabel.
  ///
  /// In id, this message translates to:
  /// **'{label} {n}'**
  String rowLabel(String label, int n);

  /// No description provided for @validationMaxLength.
  ///
  /// In id, this message translates to:
  /// **'Maksimal {max} karakter'**
  String validationMaxLength(int max);

  /// No description provided for @validationMaxItems.
  ///
  /// In id, this message translates to:
  /// **'Maksimal {max} baris'**
  String validationMaxItems(int max);

  /// No description provided for @unsupportedField.
  ///
  /// In id, this message translates to:
  /// **'Isian “{label}” belum didukung di aplikasi ini.'**
  String unsupportedField(String label);

  /// No description provided for @fieldsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Section ini tidak punya isian.'**
  String get fieldsEmpty;

  /// No description provided for @validationColor.
  ///
  /// In id, this message translates to:
  /// **'Pakai format #RRGGBB, contoh #1D2B5F'**
  String get validationColor;

  /// No description provided for @selectChoose.
  ///
  /// In id, this message translates to:
  /// **'Pilih salah satu'**
  String get selectChoose;

  /// No description provided for @markdownPreview.
  ///
  /// In id, this message translates to:
  /// **'Pratinjau'**
  String get markdownPreview;

  /// No description provided for @markdownPreviewEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada isi untuk dipratinjau.'**
  String get markdownPreviewEmpty;

  /// No description provided for @settingsDisplay.
  ///
  /// In id, this message translates to:
  /// **'Tampilan situs'**
  String get settingsDisplay;

  /// No description provided for @settingsMultipage.
  ///
  /// In id, this message translates to:
  /// **'Mode multi-halaman'**
  String get settingsMultipage;

  /// No description provided for @settingsMultipageHint.
  ///
  /// In id, this message translates to:
  /// **'Tiap section tampil di halamannya sendiri, bukan satu halaman panjang.'**
  String get settingsMultipageHint;

  /// No description provided for @settingsMultipageLocked.
  ///
  /// In id, this message translates to:
  /// **'Belum tersedia di paketmu. Tingkatkan paket untuk memakainya.'**
  String get settingsMultipageLocked;

  /// No description provided for @settingsTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan situs'**
  String get settingsTitle;

  /// No description provided for @settingsGeneral.
  ///
  /// In id, this message translates to:
  /// **'Umum'**
  String get settingsGeneral;

  /// No description provided for @settingsSiteName.
  ///
  /// In id, this message translates to:
  /// **'Nama situs'**
  String get settingsSiteName;

  /// No description provided for @settingsLogo.
  ///
  /// In id, this message translates to:
  /// **'Logo'**
  String get settingsLogo;

  /// No description provided for @settingsFavicon.
  ///
  /// In id, this message translates to:
  /// **'Favicon'**
  String get settingsFavicon;

  /// No description provided for @settingsSeo.
  ///
  /// In id, this message translates to:
  /// **'SEO'**
  String get settingsSeo;

  /// No description provided for @settingsSeoTitle.
  ///
  /// In id, this message translates to:
  /// **'Judul SEO'**
  String get settingsSeoTitle;

  /// No description provided for @settingsSeoDescription.
  ///
  /// In id, this message translates to:
  /// **'Deskripsi SEO'**
  String get settingsSeoDescription;

  /// No description provided for @settingsSocial.
  ///
  /// In id, this message translates to:
  /// **'Tautan sosial'**
  String get settingsSocial;

  /// No description provided for @settingsSocialHint.
  ///
  /// In id, this message translates to:
  /// **'Isi tautan lengkap, mis. https://instagram.com/akun'**
  String get settingsSocialHint;

  /// No description provided for @settingsNotify.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi'**
  String get settingsNotify;

  /// No description provided for @settingsNotifyEmail.
  ///
  /// In id, this message translates to:
  /// **'Email notifikasi pesan'**
  String get settingsNotifyEmail;

  /// No description provided for @settingsTheme.
  ///
  /// In id, this message translates to:
  /// **'Warna tema'**
  String get settingsTheme;

  /// No description provided for @themeBrand.
  ///
  /// In id, this message translates to:
  /// **'Brand'**
  String get themeBrand;

  /// No description provided for @themeBright.
  ///
  /// In id, this message translates to:
  /// **'Cerah'**
  String get themeBright;

  /// No description provided for @themeSoft.
  ///
  /// In id, this message translates to:
  /// **'Lembut'**
  String get themeSoft;

  /// No description provided for @settingsNoChanges.
  ///
  /// In id, this message translates to:
  /// **'Belum ada perubahan'**
  String get settingsNoChanges;

  /// No description provided for @publishTitle.
  ///
  /// In id, this message translates to:
  /// **'Publikasi'**
  String get publishTitle;

  /// No description provided for @publishStatusPublished.
  ///
  /// In id, this message translates to:
  /// **'Situs Anda sedang tayang dan bisa dilihat pengunjung.'**
  String get publishStatusPublished;

  /// No description provided for @publishStatusDraft.
  ///
  /// In id, this message translates to:
  /// **'Situs Anda masih draft dan belum bisa dilihat pengunjung.'**
  String get publishStatusDraft;

  /// No description provided for @publishStatusUnknown.
  ///
  /// In id, this message translates to:
  /// **'Status situs belum diketahui.'**
  String get publishStatusUnknown;

  /// No description provided for @publishActionPublish.
  ///
  /// In id, this message translates to:
  /// **'Tayangkan situs'**
  String get publishActionPublish;

  /// No description provided for @publishActionDraft.
  ///
  /// In id, this message translates to:
  /// **'Jadikan draft'**
  String get publishActionDraft;

  /// No description provided for @checklistTitle.
  ///
  /// In id, this message translates to:
  /// **'Kelengkapan situs'**
  String get checklistTitle;

  /// No description provided for @checklistAllGood.
  ///
  /// In id, this message translates to:
  /// **'Semua section yang tampil sudah terisi.'**
  String get checklistAllGood;

  /// No description provided for @checklistNoSections.
  ///
  /// In id, this message translates to:
  /// **'Belum ada section yang ditampilkan.'**
  String get checklistNoSections;

  /// No description provided for @checklistSample.
  ///
  /// In id, this message translates to:
  /// **'Masih berisi contoh'**
  String get checklistSample;

  /// No description provided for @checklistMissing.
  ///
  /// In id, this message translates to:
  /// **'Wajib diisi: {fields}'**
  String checklistMissing(String fields);

  /// No description provided for @publishConfirmIssuesTitle.
  ///
  /// In id, this message translates to:
  /// **'Tayangkan sekarang?'**
  String get publishConfirmIssuesTitle;

  /// No description provided for @publishConfirmIssues.
  ///
  /// In id, this message translates to:
  /// **'Masih ada {count} hal yang belum lengkap. Tetap tayangkan?'**
  String publishConfirmIssues(int count);

  /// No description provided for @publishAnyway.
  ///
  /// In id, this message translates to:
  /// **'Tetap tayangkan'**
  String get publishAnyway;

  /// No description provided for @publishConfirmDraftTitle.
  ///
  /// In id, this message translates to:
  /// **'Jadikan draft?'**
  String get publishConfirmDraftTitle;

  /// No description provided for @publishConfirmDraft.
  ///
  /// In id, this message translates to:
  /// **'Pengunjung tidak bisa melihat situs sampai Anda menayangkannya lagi.'**
  String get publishConfirmDraft;

  /// No description provided for @publishedOk.
  ///
  /// In id, this message translates to:
  /// **'Situs sudah tayang'**
  String get publishedOk;

  /// No description provided for @draftOk.
  ///
  /// In id, this message translates to:
  /// **'Situs dijadikan draft'**
  String get draftOk;

  /// No description provided for @blockEmailTitle.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi email dulu'**
  String get blockEmailTitle;

  /// No description provided for @blockEmailMessage.
  ///
  /// In id, this message translates to:
  /// **'Situs baru bisa tayang setelah email Anda terverifikasi. Buka email, klik tautan verifikasi, lalu coba lagi.'**
  String get blockEmailMessage;

  /// No description provided for @blockDisabledTitle.
  ///
  /// In id, this message translates to:
  /// **'Situs dinonaktifkan'**
  String get blockDisabledTitle;

  /// No description provided for @blockDisabledMessage.
  ///
  /// In id, this message translates to:
  /// **'Situs ini dinonaktifkan oleh admin. Hubungi admin untuk mengaktifkannya kembali.'**
  String get blockDisabledMessage;

  /// No description provided for @blockOtherTitle.
  ///
  /// In id, this message translates to:
  /// **'Tidak diizinkan'**
  String get blockOtherTitle;

  /// No description provided for @openEmail.
  ///
  /// In id, this message translates to:
  /// **'Buka email'**
  String get openEmail;

  /// No description provided for @contactAdmin.
  ///
  /// In id, this message translates to:
  /// **'Hubungi admin'**
  String get contactAdmin;

  /// No description provided for @cannotOpenLink.
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat membuka tautan.'**
  String get cannotOpenLink;

  /// No description provided for @messagesTitle.
  ///
  /// In id, this message translates to:
  /// **'Pesan masuk'**
  String get messagesTitle;

  /// No description provided for @messagesEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pesan masuk.'**
  String get messagesEmpty;

  /// No description provided for @messagesUpgradeTitle.
  ///
  /// In id, this message translates to:
  /// **'Pesan masuk belum tersedia'**
  String get messagesUpgradeTitle;

  /// No description provided for @messagesUpgradeMessage.
  ///
  /// In id, this message translates to:
  /// **'Fitur pesan masuk tersedia untuk paket Medium ke atas. Tingkatkan paket untuk membaca pesan dari pengunjung situs Anda.'**
  String get messagesUpgradeMessage;

  /// No description provided for @messageUnread.
  ///
  /// In id, this message translates to:
  /// **'Belum dibaca'**
  String get messageUnread;

  /// No description provided for @markRead.
  ///
  /// In id, this message translates to:
  /// **'Tandai dibaca'**
  String get markRead;

  /// No description provided for @markUnread.
  ///
  /// In id, this message translates to:
  /// **'Tandai belum dibaca'**
  String get markUnread;

  /// No description provided for @messageDeleteTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus pesan?'**
  String get messageDeleteTitle;

  /// No description provided for @messageDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Pesan dari {name} akan dihapus permanen.'**
  String messageDeleteConfirm(String name);

  /// No description provided for @messageDeleted.
  ///
  /// In id, this message translates to:
  /// **'Pesan dihapus'**
  String get messageDeleted;

  /// No description provided for @replyWhatsapp.
  ///
  /// In id, this message translates to:
  /// **'Balas via WhatsApp'**
  String get replyWhatsapp;

  /// No description provided for @replyEmail.
  ///
  /// In id, this message translates to:
  /// **'Balas via email'**
  String get replyEmail;

  /// No description provided for @replyCall.
  ///
  /// In id, this message translates to:
  /// **'Telepon'**
  String get replyCall;

  /// No description provided for @loadMoreFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat pesan berikutnya.'**
  String get loadMoreFailed;

  /// No description provided for @messagePhone.
  ///
  /// In id, this message translates to:
  /// **'Telepon'**
  String get messagePhone;

  /// No description provided for @messageNotFound.
  ///
  /// In id, this message translates to:
  /// **'Pesan tidak ditemukan.'**
  String get messageNotFound;

  /// No description provided for @waGreeting.
  ///
  /// In id, this message translates to:
  /// **'Halo {name}, terima kasih telah menghubungi kami.'**
  String waGreeting(String name);

  /// No description provided for @replySubject.
  ///
  /// In id, this message translates to:
  /// **'Balasan atas pesan Anda'**
  String get replySubject;

  /// No description provided for @planTitle.
  ///
  /// In id, this message translates to:
  /// **'Paket'**
  String get planTitle;

  /// No description provided for @planCurrent.
  ///
  /// In id, this message translates to:
  /// **'Paket aktif'**
  String get planCurrent;

  /// No description provided for @planPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga'**
  String get planPrice;

  /// No description provided for @planValidity.
  ///
  /// In id, this message translates to:
  /// **'Masa berlaku'**
  String get planValidity;

  /// No description provided for @planNoExpiry.
  ///
  /// In id, this message translates to:
  /// **'Tanpa batas waktu'**
  String get planNoExpiry;

  /// No description provided for @planExpiresOn.
  ///
  /// In id, this message translates to:
  /// **'Berlaku sampai {date}'**
  String planExpiresOn(String date);

  /// No description provided for @planDaysLeft.
  ///
  /// In id, this message translates to:
  /// **'{days} hari lagi'**
  String planDaysLeft(int days);

  /// No description provided for @planExpiresToday.
  ///
  /// In id, this message translates to:
  /// **'berakhir hari ini'**
  String get planExpiresToday;

  /// No description provided for @planExpired.
  ///
  /// In id, this message translates to:
  /// **'Sudah berakhir'**
  String get planExpired;

  /// No description provided for @planLimits.
  ///
  /// In id, this message translates to:
  /// **'Batas paket'**
  String get planLimits;

  /// No description provided for @planLimitsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada informasi batas untuk paket ini.'**
  String get planLimitsEmpty;

  /// No description provided for @limitUnlimited.
  ///
  /// In id, this message translates to:
  /// **'Tanpa batas'**
  String get limitUnlimited;

  /// No description provided for @valueYes.
  ///
  /// In id, this message translates to:
  /// **'Ya'**
  String get valueYes;

  /// No description provided for @valueNo.
  ///
  /// In id, this message translates to:
  /// **'Tidak'**
  String get valueNo;

  /// No description provided for @planUpgrade.
  ///
  /// In id, this message translates to:
  /// **'Upgrade atau perpanjang'**
  String get planUpgrade;

  /// No description provided for @planUpgradeHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih paket dan bayar langsung di aplikasi. Paket dan masa berlaku diperbarui otomatis setelah pembayaran diterima.'**
  String get planUpgradeHint;

  /// No description provided for @planViewPlans.
  ///
  /// In id, this message translates to:
  /// **'Lihat paket'**
  String get planViewPlans;

  /// No description provided for @planRefreshed.
  ///
  /// In id, this message translates to:
  /// **'Data paket diperbarui'**
  String get planRefreshed;

  /// No description provided for @previewTitle.
  ///
  /// In id, this message translates to:
  /// **'Pratinjau'**
  String get previewTitle;

  /// No description provided for @previewReload.
  ///
  /// In id, this message translates to:
  /// **'Muat ulang'**
  String get previewReload;

  /// No description provided for @previewShare.
  ///
  /// In id, this message translates to:
  /// **'Bagikan tautan situs'**
  String get previewShare;

  /// No description provided for @previewCopy.
  ///
  /// In id, this message translates to:
  /// **'Salin tautan'**
  String get previewCopy;

  /// No description provided for @previewOpenBrowser.
  ///
  /// In id, this message translates to:
  /// **'Buka di browser'**
  String get previewOpenBrowser;

  /// No description provided for @previewCopied.
  ///
  /// In id, this message translates to:
  /// **'Tautan disalin'**
  String get previewCopied;

  /// No description provided for @previewLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Pratinjau tidak dapat dimuat. Periksa koneksi internet Anda.'**
  String get previewLoadFailed;

  /// No description provided for @previewDraftBanner.
  ///
  /// In id, this message translates to:
  /// **'Situs masih draft, jadi pengunjung belum bisa membuka tautannya.'**
  String get previewDraftBanner;

  /// No description provided for @previewGoPublish.
  ///
  /// In id, this message translates to:
  /// **'Publikasi'**
  String get previewGoPublish;

  /// No description provided for @shareMessage.
  ///
  /// In id, this message translates to:
  /// **'Kunjungi {name}: {url}'**
  String shareMessage(String name, String url);

  /// No description provided for @moreActions.
  ///
  /// In id, this message translates to:
  /// **'Menu lainnya'**
  String get moreActions;

  /// No description provided for @dashboardTitle.
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get dashboardTitle;

  /// No description provided for @dashboardLoading.
  ///
  /// In id, this message translates to:
  /// **'Memuat situs...'**
  String get dashboardLoading;

  /// No description provided for @dashboardNoSiteTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada situs aktif'**
  String get dashboardNoSiteTitle;

  /// No description provided for @dashboardNoSiteMessage.
  ///
  /// In id, this message translates to:
  /// **'Buka tab Situs dan pilih situs yang ingin dikelola.'**
  String get dashboardNoSiteMessage;

  /// No description provided for @dashboardSwitchSite.
  ///
  /// In id, this message translates to:
  /// **'Ganti situs'**
  String get dashboardSwitchSite;

  /// No description provided for @dashboardPlanExpiredTitle.
  ///
  /// In id, this message translates to:
  /// **'Paket sudah berakhir'**
  String get dashboardPlanExpiredTitle;

  /// No description provided for @dashboardPlanExpiredMessage.
  ///
  /// In id, this message translates to:
  /// **'Paket Anda sudah berakhir. Perpanjang supaya fitur paket aktif kembali.'**
  String get dashboardPlanExpiredMessage;

  /// No description provided for @dashboardPlanExpiringTitle.
  ///
  /// In id, this message translates to:
  /// **'Paket segera berakhir'**
  String get dashboardPlanExpiringTitle;

  /// No description provided for @dashboardPlanExpiresToday.
  ///
  /// In id, this message translates to:
  /// **'Paket Anda berakhir hari ini. Perpanjang supaya fitur paket tetap aktif.'**
  String get dashboardPlanExpiresToday;

  /// No description provided for @dashboardPlanExpiresIn.
  ///
  /// In id, this message translates to:
  /// **'Paket Anda berakhir {days} hari lagi. Perpanjang supaya fitur paket tetap aktif.'**
  String dashboardPlanExpiresIn(int days);

  /// No description provided for @dashboardRenew.
  ///
  /// In id, this message translates to:
  /// **'Perpanjang'**
  String get dashboardRenew;

  /// No description provided for @dashboardCheckAndPublish.
  ///
  /// In id, this message translates to:
  /// **'Cek & tayangkan'**
  String get dashboardCheckAndPublish;

  /// No description provided for @dashboardNeedsWork.
  ///
  /// In id, this message translates to:
  /// **'Perlu dilengkapi'**
  String get dashboardNeedsWork;

  /// No description provided for @dashboardMoreItems.
  ///
  /// In id, this message translates to:
  /// **'+{count} lainnya'**
  String dashboardMoreItems(int count);

  /// No description provided for @dashboardOpenSite.
  ///
  /// In id, this message translates to:
  /// **'Buka situs'**
  String get dashboardOpenSite;

  /// No description provided for @dashboardStatMessages.
  ///
  /// In id, this message translates to:
  /// **'Pesan'**
  String get dashboardStatMessages;

  /// No description provided for @dashboardStatPlanDays.
  ///
  /// In id, this message translates to:
  /// **'Paket · hari'**
  String get dashboardStatPlanDays;

  /// No description provided for @dashboardStatStatus.
  ///
  /// In id, this message translates to:
  /// **'Status'**
  String get dashboardStatStatus;

  /// No description provided for @dashboardManageTitle.
  ///
  /// In id, this message translates to:
  /// **'Kelola situs'**
  String get dashboardManageTitle;

  /// No description provided for @completenessPercent.
  ///
  /// In id, this message translates to:
  /// **'{percent}% lengkap'**
  String completenessPercent(int percent);

  /// No description provided for @completenessCounts.
  ///
  /// In id, this message translates to:
  /// **'{full} lengkap · {partial} sebagian · {empty} kosong'**
  String completenessCounts(int full, int partial, int empty);

  /// No description provided for @publishConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Tayangkan situs?'**
  String get publishConfirmTitle;

  /// No description provided for @publishConfirm.
  ///
  /// In id, this message translates to:
  /// **'Pengunjung akan bisa melihat situs Anda.'**
  String get publishConfirm;

  /// No description provided for @checklistSectionUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Section belum termuat. Coba lagi sebentar lagi.'**
  String get checklistSectionUnavailable;

  /// No description provided for @actionBack.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get actionBack;

  /// No description provided for @actionNext.
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get actionNext;

  /// No description provided for @themeTitle.
  ///
  /// In id, this message translates to:
  /// **'Warna situs'**
  String get themeTitle;

  /// No description provided for @themeIntro.
  ///
  /// In id, this message translates to:
  /// **'Pilih warna yang dipakai di seluruh situs Anda. Pilihan sama dengan dashboard web.'**
  String get themeIntro;

  /// No description provided for @themeSaved.
  ///
  /// In id, this message translates to:
  /// **'Warna situs diperbarui'**
  String get themeSaved;

  /// No description provided for @themeEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pilihan warna.'**
  String get themeEmpty;

  /// No description provided for @onboardingTitle.
  ///
  /// In id, this message translates to:
  /// **'Atur situs Anda'**
  String get onboardingTitle;

  /// No description provided for @onboardingSkip.
  ///
  /// In id, this message translates to:
  /// **'Lewati'**
  String get onboardingSkip;

  /// No description provided for @onboardingSkipTitle.
  ///
  /// In id, this message translates to:
  /// **'Lewati pengaturan awal?'**
  String get onboardingSkipTitle;

  /// No description provided for @onboardingSkipMessage.
  ///
  /// In id, this message translates to:
  /// **'Anda tetap bisa mengisi nama, kontak, dan warna nanti lewat Pengaturan, tab Section, dan Warna situs di Beranda.'**
  String get onboardingSkipMessage;

  /// No description provided for @onboardingSkipped.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan awal dilewati'**
  String get onboardingSkipped;

  /// No description provided for @onboardingDone.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan awal tersimpan'**
  String get onboardingDone;

  /// No description provided for @onboardingStepOf.
  ///
  /// In id, this message translates to:
  /// **'Langkah {current} dari {total}'**
  String onboardingStepOf(int current, int total);

  /// No description provided for @onboardingBusinessTitle.
  ///
  /// In id, this message translates to:
  /// **'Tentang usaha Anda'**
  String get onboardingBusinessTitle;

  /// No description provided for @onboardingBusinessHint.
  ///
  /// In id, this message translates to:
  /// **'Nama dan kalimat singkat ini tampil di bagian paling atas situs.'**
  String get onboardingBusinessHint;

  /// No description provided for @onboardingName.
  ///
  /// In id, this message translates to:
  /// **'Nama usaha'**
  String get onboardingName;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Kalimat singkat (opsional)'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingSubtitleHelp.
  ///
  /// In id, this message translates to:
  /// **'Tampil di bawah nama usaha. Kosongkan untuk memakai teks contoh.'**
  String get onboardingSubtitleHelp;

  /// No description provided for @onboardingContactTitle.
  ///
  /// In id, this message translates to:
  /// **'Kontak'**
  String get onboardingContactTitle;

  /// No description provided for @onboardingContactHint.
  ///
  /// In id, this message translates to:
  /// **'Pengunjung bisa langsung menghubungi Anda lewat WhatsApp.'**
  String get onboardingContactHint;

  /// No description provided for @onboardingWhatsapp.
  ///
  /// In id, this message translates to:
  /// **'Nomor WhatsApp (opsional)'**
  String get onboardingWhatsapp;

  /// No description provided for @onboardingWhatsappHelp.
  ///
  /// In id, this message translates to:
  /// **'Contoh: 0812 3456 7890. Awalan 0 diubah ke 62 otomatis.'**
  String get onboardingWhatsappHelp;

  /// No description provided for @onboardingWhatsappInvalid.
  ///
  /// In id, this message translates to:
  /// **'Nomor tidak valid. Contoh: 0812 3456 7890.'**
  String get onboardingWhatsappInvalid;

  /// No description provided for @onboardingThemeTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih warna'**
  String get onboardingThemeTitle;

  /// No description provided for @onboardingThemeHint.
  ///
  /// In id, this message translates to:
  /// **'Warna ini dipakai di seluruh situs dan bisa diganti kapan saja.'**
  String get onboardingThemeHint;

  /// No description provided for @onboardingFinish.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get onboardingFinish;

  /// No description provided for @onboardingCardTitle.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi pengaturan awal'**
  String get onboardingCardTitle;

  /// No description provided for @onboardingCardMessage.
  ///
  /// In id, this message translates to:
  /// **'Isi nama, kontak WhatsApp, dan warna situs dalam 3 langkah singkat.'**
  String get onboardingCardMessage;

  /// No description provided for @onboardingStart.
  ///
  /// In id, this message translates to:
  /// **'Mulai'**
  String get onboardingStart;

  /// No description provided for @templateTitle.
  ///
  /// In id, this message translates to:
  /// **'Template tampilan'**
  String get templateTitle;

  /// No description provided for @templateIntro.
  ///
  /// In id, this message translates to:
  /// **'Pilih tampilan situs Anda. Isi situs tidak berubah saat template diganti.'**
  String get templateIntro;

  /// No description provided for @templateEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada template.'**
  String get templateEmpty;

  /// No description provided for @templateActive.
  ///
  /// In id, this message translates to:
  /// **'Dipakai'**
  String get templateActive;

  /// No description provided for @templateTierClassic.
  ///
  /// In id, this message translates to:
  /// **'Classic'**
  String get templateTierClassic;

  /// No description provided for @templateTierMedium.
  ///
  /// In id, this message translates to:
  /// **'Medium'**
  String get templateTierMedium;

  /// No description provided for @templateTierPro.
  ///
  /// In id, this message translates to:
  /// **'Pro'**
  String get templateTierPro;

  /// No description provided for @templateLockedPlan.
  ///
  /// In id, this message translates to:
  /// **'Tersedia di paket {plan}'**
  String templateLockedPlan(String plan);

  /// No description provided for @templatePreview.
  ///
  /// In id, this message translates to:
  /// **'Pratinjau'**
  String get templatePreview;

  /// No description provided for @templateUse.
  ///
  /// In id, this message translates to:
  /// **'Pakai'**
  String get templateUse;

  /// No description provided for @templateConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Ganti template?'**
  String get templateConfirmTitle;

  /// No description provided for @templateConfirmMessage.
  ///
  /// In id, this message translates to:
  /// **'Tampilan situs akan berganti ke {name}. Isi situs Anda tidak berubah.'**
  String templateConfirmMessage(String name);

  /// No description provided for @templateApplied.
  ///
  /// In id, this message translates to:
  /// **'Tampilan diganti ke {name}'**
  String templateApplied(String name);

  /// No description provided for @templateChosenInactive.
  ///
  /// In id, this message translates to:
  /// **'Template pilihan Anda ({chosen}) belum aktif karena paket belum mencukupi. Situs memakai {active} sampai paket di-upgrade.'**
  String templateChosenInactive(String chosen, String active);

  /// No description provided for @templatePreviewFailed.
  ///
  /// In id, this message translates to:
  /// **'Pratinjau tidak dapat dimuat atau tautannya sudah kedaluwarsa. Tutup lalu buka pratinjau lagi.'**
  String get templatePreviewFailed;

  /// No description provided for @addressTitle.
  ///
  /// In id, this message translates to:
  /// **'Alamat website'**
  String get addressTitle;

  /// No description provided for @addressIntro.
  ///
  /// In id, this message translates to:
  /// **'Alamat ini dipakai pengunjung untuk membuka situs Anda. Setelah diganti, link lama berhenti berfungsi.'**
  String get addressIntro;

  /// No description provided for @addressCurrent.
  ///
  /// In id, this message translates to:
  /// **'Alamat sekarang'**
  String get addressCurrent;

  /// No description provided for @addressInputLabel.
  ///
  /// In id, this message translates to:
  /// **'Alamat baru'**
  String get addressInputLabel;

  /// No description provided for @addressInputHint.
  ///
  /// In id, this message translates to:
  /// **'contoh: kopikita'**
  String get addressInputHint;

  /// No description provided for @addressChecking.
  ///
  /// In id, this message translates to:
  /// **'Memeriksa…'**
  String get addressChecking;

  /// No description provided for @addressEmptyHelp.
  ///
  /// In id, this message translates to:
  /// **'Tulis alamat yang Anda inginkan.'**
  String get addressEmptyHelp;

  /// No description provided for @addressUseSuggestion.
  ///
  /// In id, this message translates to:
  /// **'Pakai {slug}'**
  String addressUseSuggestion(String slug);

  /// No description provided for @addressSubmit.
  ///
  /// In id, this message translates to:
  /// **'Ganti alamat'**
  String get addressSubmit;

  /// No description provided for @addressConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Ganti alamat website?'**
  String get addressConfirmTitle;

  /// No description provided for @addressConfirmMessage.
  ///
  /// In id, this message translates to:
  /// **'Link lama ({oldUrl}) akan berhenti berfungsi. Link baru: {newUrl}. Bagikan ulang ke pelanggan Anda.'**
  String addressConfirmMessage(String oldUrl, String newUrl);

  /// No description provided for @addressSaved.
  ///
  /// In id, this message translates to:
  /// **'Alamat diganti ke {slug}'**
  String addressSaved(String slug);

  /// No description provided for @domainTitle.
  ///
  /// In id, this message translates to:
  /// **'Domain sendiri'**
  String get domainTitle;

  /// No description provided for @domainCurrentUrl.
  ///
  /// In id, this message translates to:
  /// **'Alamat situs saat ini'**
  String get domainCurrentUrl;

  /// No description provided for @domainLocked.
  ///
  /// In id, this message translates to:
  /// **'Domain sendiri belum tersedia di paket Anda. Upgrade paket untuk memakainya.'**
  String get domainLocked;

  /// No description provided for @domainNotReady.
  ///
  /// In id, this message translates to:
  /// **'Server belum siap menerima domain sendiri. Coba lagi nanti.'**
  String get domainNotReady;

  /// No description provided for @domainNone.
  ///
  /// In id, this message translates to:
  /// **'Belum ada domain sendiri'**
  String get domainNone;

  /// No description provided for @domainNoneHint.
  ///
  /// In id, this message translates to:
  /// **'Daftarkan domain Anda lewat dashboard web.'**
  String get domainNoneHint;

  /// No description provided for @domainStatusActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get domainStatusActive;

  /// No description provided for @domainStatusPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu verifikasi'**
  String get domainStatusPending;

  /// No description provided for @domainStatusVerifiedInactive.
  ///
  /// In id, this message translates to:
  /// **'Terverifikasi, tetapi paket tidak mengizinkan'**
  String get domainStatusVerifiedInactive;

  /// No description provided for @domainDnsTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan DNS'**
  String get domainDnsTitle;

  /// No description provided for @domainDnsHint.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan record berikut di pengelola DNS domain Anda, lalu cek verifikasi lewat dashboard web.'**
  String get domainDnsHint;

  /// No description provided for @domainDnsTxtName.
  ///
  /// In id, this message translates to:
  /// **'TXT: nama'**
  String get domainDnsTxtName;

  /// No description provided for @domainDnsTxtValue.
  ///
  /// In id, this message translates to:
  /// **'TXT: isi'**
  String get domainDnsTxtValue;

  /// No description provided for @domainDnsA.
  ///
  /// In id, this message translates to:
  /// **'A: alamat server'**
  String get domainDnsA;

  /// No description provided for @domainDnsCname.
  ///
  /// In id, this message translates to:
  /// **'CNAME: tujuan'**
  String get domainDnsCname;

  /// No description provided for @domainCopied.
  ///
  /// In id, this message translates to:
  /// **'Disalin'**
  String get domainCopied;

  /// No description provided for @domainManageWeb.
  ///
  /// In id, this message translates to:
  /// **'Kelola di web'**
  String get domainManageWeb;

  /// No description provided for @domainWebHint.
  ///
  /// In id, this message translates to:
  /// **'Menyetel, memverifikasi, dan melepas domain dilakukan di dashboard web. Setelah selesai, kembali ke aplikasi dan status diperbarui otomatis.'**
  String get domainWebHint;

  /// No description provided for @domainCopy.
  ///
  /// In id, this message translates to:
  /// **'Salin'**
  String get domainCopy;

  /// No description provided for @billingTitle.
  ///
  /// In id, this message translates to:
  /// **'Paket dan pembayaran'**
  String get billingTitle;

  /// No description provided for @billingHistoryTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat pembayaran'**
  String get billingHistoryTitle;

  /// No description provided for @billingHistoryEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pembayaran.'**
  String get billingHistoryEmpty;

  /// No description provided for @billingLoadMore.
  ///
  /// In id, this message translates to:
  /// **'Muat lebih banyak'**
  String get billingLoadMore;

  /// No description provided for @billingEmailUnverifiedTitle.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi email dulu'**
  String get billingEmailUnverifiedTitle;

  /// No description provided for @billingEmailUnverifiedMessage.
  ///
  /// In id, this message translates to:
  /// **'Membeli paket butuh email yang sudah terverifikasi. Buka tautan verifikasi di email Anda, lalu tarik layar ini ke bawah untuk memuat ulang.'**
  String get billingEmailUnverifiedMessage;

  /// No description provided for @billingPendingTitle.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran menunggu'**
  String get billingPendingTitle;

  /// No description provided for @billingPendingMessage.
  ///
  /// In id, this message translates to:
  /// **'{plan} · {amount}. Lanjutkan pembayaran atau pilih paket lain.'**
  String billingPendingMessage(String plan, String amount);

  /// No description provided for @billingContinuePay.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan pembayaran'**
  String get billingContinuePay;

  /// No description provided for @billingPeriod.
  ///
  /// In id, this message translates to:
  /// **'Lama langganan'**
  String get billingPeriod;

  /// No description provided for @billingPlansTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih paket'**
  String get billingPlansTitle;

  /// No description provided for @billingNoPlans.
  ///
  /// In id, this message translates to:
  /// **'Belum ada paket yang tersedia.'**
  String get billingNoPlans;

  /// No description provided for @billingCreating.
  ///
  /// In id, this message translates to:
  /// **'Membuat tagihan…'**
  String get billingCreating;

  /// No description provided for @billingOpenWeb.
  ///
  /// In id, this message translates to:
  /// **'Buka halaman tagihan di web'**
  String get billingOpenWeb;

  /// No description provided for @billingFree.
  ///
  /// In id, this message translates to:
  /// **'Gratis'**
  String get billingFree;

  /// No description provided for @billingCurrentBadge.
  ///
  /// In id, this message translates to:
  /// **'Paket aktif'**
  String get billingCurrentBadge;

  /// No description provided for @billingForPeriod.
  ///
  /// In id, this message translates to:
  /// **'untuk {period}'**
  String billingForPeriod(String period);

  /// No description provided for @billingRenew.
  ///
  /// In id, this message translates to:
  /// **'Perpanjang'**
  String get billingRenew;

  /// No description provided for @billingBuy.
  ///
  /// In id, this message translates to:
  /// **'Pilih paket'**
  String get billingBuy;

  /// No description provided for @billingPayTitle.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get billingPayTitle;

  /// No description provided for @billingPlanMonths.
  ///
  /// In id, this message translates to:
  /// **'{plan} · {months} bulan'**
  String billingPlanMonths(String plan, int months);

  /// No description provided for @billingOrderNumber.
  ///
  /// In id, this message translates to:
  /// **'No. tagihan {number}'**
  String billingOrderNumber(String number);

  /// No description provided for @billingChooseMethod.
  ///
  /// In id, this message translates to:
  /// **'Pilih metode pembayaran'**
  String get billingChooseMethod;

  /// No description provided for @billingTimedOut.
  ///
  /// In id, this message translates to:
  /// **'Batas waktu tagihan sebelumnya sudah habis. Pilih metode pembayaran lagi.'**
  String get billingTimedOut;

  /// No description provided for @billingChangeMethod.
  ///
  /// In id, this message translates to:
  /// **'Ganti metode'**
  String get billingChangeMethod;

  /// No description provided for @billingPayWeb.
  ///
  /// In id, this message translates to:
  /// **'Bayar lewat web'**
  String get billingPayWeb;

  /// No description provided for @billingWebHint.
  ///
  /// In id, this message translates to:
  /// **'Tagihan ini dibayar di situs web. Setelah selesai, kembali ke aplikasi dan status diperbarui otomatis.'**
  String get billingWebHint;

  /// No description provided for @billingWebUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Tautan pembayaran tidak tersedia. Buka halaman tagihan di web dari daftar paket.'**
  String get billingWebUnavailable;

  /// No description provided for @billingInstructionsTitle.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan pembayaran'**
  String get billingInstructionsTitle;

  /// No description provided for @billingDetailsMissing.
  ///
  /// In id, this message translates to:
  /// **'Rincian pembayaran tidak tersedia. Pilih metode lain.'**
  String get billingDetailsMissing;

  /// No description provided for @billingVaBank.
  ///
  /// In id, this message translates to:
  /// **'Bank'**
  String get billingVaBank;

  /// No description provided for @billingVaNumber.
  ///
  /// In id, this message translates to:
  /// **'Nomor virtual account'**
  String get billingVaNumber;

  /// No description provided for @billingBillerCode.
  ///
  /// In id, this message translates to:
  /// **'Kode perusahaan (biller)'**
  String get billingBillerCode;

  /// No description provided for @billingBillKey.
  ///
  /// In id, this message translates to:
  /// **'Kode pembayaran'**
  String get billingBillKey;

  /// No description provided for @billingQrHint.
  ///
  /// In id, this message translates to:
  /// **'Pindai kode QR ini dengan aplikasi bank atau dompet digital yang mendukung QRIS.'**
  String get billingQrHint;

  /// No description provided for @billingQrSemantics.
  ///
  /// In id, this message translates to:
  /// **'Kode QR pembayaran'**
  String get billingQrSemantics;

  /// No description provided for @billingQrMissing.
  ///
  /// In id, this message translates to:
  /// **'Kode QR tidak tersedia. Pilih metode lain.'**
  String get billingQrMissing;

  /// No description provided for @billingPayBefore.
  ///
  /// In id, this message translates to:
  /// **'Bayar sebelum {date}'**
  String billingPayBefore(String date);

  /// No description provided for @billingTimeLeft.
  ///
  /// In id, this message translates to:
  /// **'Sisa waktu {time}'**
  String billingTimeLeft(String time);

  /// No description provided for @billingWaiting.
  ///
  /// In id, this message translates to:
  /// **'Menunggu pembayaran. Status diperiksa otomatis.'**
  String get billingWaiting;

  /// No description provided for @billingCheckStatus.
  ///
  /// In id, this message translates to:
  /// **'Cek status pembayaran'**
  String get billingCheckStatus;

  /// No description provided for @billingCopy.
  ///
  /// In id, this message translates to:
  /// **'Salin'**
  String get billingCopy;

  /// No description provided for @billingCopied.
  ///
  /// In id, this message translates to:
  /// **'Disalin'**
  String get billingCopied;

  /// No description provided for @billingPaidTitle.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran berhasil'**
  String get billingPaidTitle;

  /// No description provided for @billingPaidMessage.
  ///
  /// In id, this message translates to:
  /// **'Paket {plan} sudah aktif.'**
  String billingPaidMessage(String plan);

  /// No description provided for @billingPaidDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get billingPaidDone;

  /// No description provided for @billingPaidSnack.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran diterima. Paket diperbarui.'**
  String get billingPaidSnack;

  /// No description provided for @billingClosedTitle.
  ///
  /// In id, this message translates to:
  /// **'Tagihan sudah tidak aktif'**
  String get billingClosedTitle;

  /// No description provided for @billingClosedMessage.
  ///
  /// In id, this message translates to:
  /// **'Buat tagihan baru dari halaman paket.'**
  String get billingClosedMessage;

  /// No description provided for @billingBackToPlans.
  ///
  /// In id, this message translates to:
  /// **'Kembali ke daftar paket'**
  String get billingBackToPlans;

  /// No description provided for @billingStatusPaid.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get billingStatusPaid;

  /// No description provided for @billingStatusPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu pembayaran'**
  String get billingStatusPending;

  /// No description provided for @billingStatusFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal'**
  String get billingStatusFailed;

  /// No description provided for @billingStatusExpired.
  ///
  /// In id, this message translates to:
  /// **'Kedaluwarsa'**
  String get billingStatusExpired;

  /// No description provided for @accountEmailLabel.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get accountEmailLabel;

  /// No description provided for @accountShowPassword.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan password'**
  String get accountShowPassword;

  /// No description provided for @accountHidePassword.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan password'**
  String get accountHidePassword;

  /// No description provided for @accountResendWait.
  ///
  /// In id, this message translates to:
  /// **'Kirim ulang dalam {seconds} dtk'**
  String accountResendWait(int seconds);

  /// No description provided for @accountResendVerification.
  ///
  /// In id, this message translates to:
  /// **'Kirim ulang tautan verifikasi'**
  String get accountResendVerification;

  /// No description provided for @accountResendSending.
  ///
  /// In id, this message translates to:
  /// **'Mengirim…'**
  String get accountResendSending;

  /// No description provided for @forgotTitle.
  ///
  /// In id, this message translates to:
  /// **'Lupa password'**
  String get forgotTitle;

  /// No description provided for @forgotIntro.
  ///
  /// In id, this message translates to:
  /// **'Masukkan email akun Anda. Kami akan mengirim tautan untuk mengatur ulang password.'**
  String get forgotIntro;

  /// No description provided for @forgotSubmit.
  ///
  /// In id, this message translates to:
  /// **'Kirim tautan'**
  String get forgotSubmit;

  /// No description provided for @forgotResend.
  ///
  /// In id, this message translates to:
  /// **'Kirim ulang tautan'**
  String get forgotResend;

  /// No description provided for @forgotSentTitle.
  ///
  /// In id, this message translates to:
  /// **'Cek email Anda'**
  String get forgotSentTitle;

  /// No description provided for @forgotHaveLink.
  ///
  /// In id, this message translates to:
  /// **'Saya sudah punya tautan atau kode'**
  String get forgotHaveLink;

  /// No description provided for @forgotBack.
  ///
  /// In id, this message translates to:
  /// **'Kembali ke halaman masuk'**
  String get forgotBack;

  /// No description provided for @resetTitle.
  ///
  /// In id, this message translates to:
  /// **'Atur ulang password'**
  String get resetTitle;

  /// No description provided for @resetIntro.
  ///
  /// In id, this message translates to:
  /// **'Salin tautan dari email atur ulang (atau kodenya), tempel di sini, lalu buat password baru. Tautan hanya berlaku sementara.'**
  String get resetIntro;

  /// No description provided for @resetTokenLabel.
  ///
  /// In id, this message translates to:
  /// **'Tautan atau kode dari email'**
  String get resetTokenLabel;

  /// No description provided for @resetPaste.
  ///
  /// In id, this message translates to:
  /// **'Tempel dari papan klip'**
  String get resetPaste;

  /// No description provided for @resetPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Password baru'**
  String get resetPasswordLabel;

  /// No description provided for @resetConfirmLabel.
  ///
  /// In id, this message translates to:
  /// **'Ulangi password baru'**
  String get resetConfirmLabel;

  /// No description provided for @resetSubmit.
  ///
  /// In id, this message translates to:
  /// **'Atur ulang password'**
  String get resetSubmit;

  /// No description provided for @authEmailRequired.
  ///
  /// In id, this message translates to:
  /// **'Email wajib diisi.'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In id, this message translates to:
  /// **'Format email belum benar.'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordRequired.
  ///
  /// In id, this message translates to:
  /// **'Password wajib diisi.'**
  String get authPasswordRequired;

  /// No description provided for @authForgotLink.
  ///
  /// In id, this message translates to:
  /// **'Lupa password?'**
  String get authForgotLink;

  /// No description provided for @authRetryIn.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi dalam {seconds} dtk'**
  String authRetryIn(int seconds);

  /// No description provided for @registerHeading.
  ///
  /// In id, this message translates to:
  /// **'Buat akun pemilik situs'**
  String get registerHeading;

  /// No description provided for @registerNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get registerNameLabel;

  /// No description provided for @registerNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama wajib diisi.'**
  String get registerNameRequired;

  /// No description provided for @registerNameMax.
  ///
  /// In id, this message translates to:
  /// **'Nama maksimal 100 karakter.'**
  String get registerNameMax;

  /// No description provided for @registerCompanyRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama usaha wajib diisi.'**
  String get registerCompanyRequired;

  /// No description provided for @registerCompanyMax.
  ///
  /// In id, this message translates to:
  /// **'Nama usaha maksimal 100 karakter.'**
  String get registerCompanyMax;

  /// No description provided for @registerSlugLabel.
  ///
  /// In id, this message translates to:
  /// **'Alamat situs (opsional)'**
  String get registerSlugLabel;

  /// No description provided for @registerSlugHelper.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan untuk dibuat otomatis dari nama usaha.'**
  String get registerSlugHelper;

  /// No description provided for @registerSlugLength.
  ///
  /// In id, this message translates to:
  /// **'Alamat 3 sampai 40 karakter.'**
  String get registerSlugLength;

  /// No description provided for @registerSlugChars.
  ///
  /// In id, this message translates to:
  /// **'Hanya huruf kecil, angka, dan tanda hubung.'**
  String get registerSlugChars;

  /// No description provided for @registerPasswordHelper.
  ///
  /// In id, this message translates to:
  /// **'Minimal 8 karakter.'**
  String get registerPasswordHelper;

  /// No description provided for @registerPasswordMin.
  ///
  /// In id, this message translates to:
  /// **'Password minimal 8 karakter.'**
  String get registerPasswordMin;

  /// No description provided for @registerConfirmLabel.
  ///
  /// In id, this message translates to:
  /// **'Ulangi password'**
  String get registerConfirmLabel;

  /// No description provided for @registerConfirmMismatch.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi password tidak sama.'**
  String get registerConfirmMismatch;

  /// No description provided for @registerCreated.
  ///
  /// In id, this message translates to:
  /// **'Akun dibuat. Cek email Anda untuk verifikasi sebelum menayangkan situs.'**
  String get registerCreated;

  /// No description provided for @shellLoggingOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar...'**
  String get shellLoggingOut;

  /// No description provided for @shellTabSites.
  ///
  /// In id, this message translates to:
  /// **'Situs'**
  String get shellTabSites;

  /// No description provided for @shellTabAccount.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get shellTabAccount;

  /// No description provided for @accountLogoutTitle.
  ///
  /// In id, this message translates to:
  /// **'Keluar?'**
  String get accountLogoutTitle;

  /// No description provided for @accountLogoutMessage.
  ///
  /// In id, this message translates to:
  /// **'Anda perlu masuk lagi untuk mengelola situs.'**
  String get accountLogoutMessage;

  /// No description provided for @accountEmailUnverifiedTitle.
  ///
  /// In id, this message translates to:
  /// **'Email belum diverifikasi'**
  String get accountEmailUnverifiedTitle;

  /// No description provided for @accountEmailUnverifiedMessage.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi email dibutuhkan untuk menayangkan situs.'**
  String get accountEmailUnverifiedMessage;

  /// No description provided for @accountEmailVerified.
  ///
  /// In id, this message translates to:
  /// **'Email terverifikasi'**
  String get accountEmailVerified;

  /// No description provided for @statusDisabled.
  ///
  /// In id, this message translates to:
  /// **'Nonaktif'**
  String get statusDisabled;

  /// No description provided for @sessionExpired.
  ///
  /// In id, this message translates to:
  /// **'Sesi berakhir. Silakan masuk kembali.'**
  String get sessionExpired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
