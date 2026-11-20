part of 'plan_bloc.dart';

@blocFreezed
sealed class PlanEvent with _$PlanEvent {

  /// Muat pertama (menampilkan loading).
  const factory PlanEvent.load() = _Load;

  /// Muat ulang tanpa menghapus data yang tampil. [announce] = tampilkan pesan
  /// "data diperbarui" (setelah kembali dari pembayaran di browser).
  const factory PlanEvent.refresh({@Default(false) bool announce}) = _Refresh;
}
