part of 'checklist_bloc.dart';

@blocFreezed
sealed class ChecklistEvent with _$ChecklistEvent {

  /// Muat pertama (menampilkan loading).
  const factory ChecklistEvent.load() = _Load;

  /// Muat ulang tanpa menghapus data yang tampil (tarik-untuk-muat-ulang,
  /// setelah mengedit section atau mengubah status tayang).
  const factory ChecklistEvent.refresh() = _Refresh;
}
