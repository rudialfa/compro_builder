part of 'address_bloc.dart';

class AddressViewData {
  /// Isian mentah pengguna.
  final String input;

  /// Hasil cek server untuk [input] (null bila belum/sedang menunggu).
  final SlugCheckModel? check;

  /// Menunggu debounce atau jawaban cek.
  final bool checking;

  /// Galat saat cek (mis. 429 atau jaringan); bukan "alamat tidak tersedia".
  final ApiFailure? checkFailure;

  final bool isSaving;

  /// Galat simpan sesaat; 422 membawa fieldErrors['slug'].
  final ApiFailure? saveFailure;

  /// Situs terbaru setelah ganti alamat sukses (satu emisi); halaman
  /// meneruskannya ke SitesBloc lalu menutup diri.
  final TenantModel? savedTenant;

  /// Slug lama sebelum diganti (hanya bersama [savedTenant]).
  final String? oldSlug;

  const AddressViewData({
    this.input = '',
    this.check,
    this.checking = false,
    this.checkFailure,
    this.isSaving = false,
    this.saveFailure,
    this.savedTenant,
    this.oldSlug,
  });

  /// Isian sama dengan yang diperiksa server (huruf kecil, tanpa spasi tepi).
  bool get checkMatchesInput {
    final c = check;
    return c != null && c.slug == input.trim().toLowerCase();
  }

  bool get canSubmit =>
      !isSaving && !checking && checkMatchesInput && (check?.ok ?? false);

  /// [saveFailure], [savedTenant], dan [oldSlug] sengaja tidak dibawa (satu emisi).
  /// [clearCheck] membuang hasil cek lama.
  AddressViewData copyWith({
    String? input,
    SlugCheckModel? check,
    bool clearCheck = false,
    bool? checking,
    ApiFailure? checkFailure,
    bool clearCheckFailure = false,
    bool? isSaving,
    ApiFailure? saveFailure,
    TenantModel? savedTenant,
    String? oldSlug,
  }) => AddressViewData(
    input: input ?? this.input,
    check: clearCheck ? null : (check ?? this.check),
    checking: checking ?? this.checking,
    checkFailure:
        clearCheckFailure ? null : (checkFailure ?? this.checkFailure),
    isSaving: isSaving ?? this.isSaving,
    saveFailure: saveFailure,
    savedTenant: savedTenant,
    oldSlug: oldSlug,
  );
}

@blocFreezed
sealed class AddressState with _$AddressState {
  const factory AddressState.ready(AddressViewData data) = _Ready;
}
