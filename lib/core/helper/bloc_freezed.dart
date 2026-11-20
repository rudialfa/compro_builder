import 'package:freezed_annotation/freezed_annotation.dart';

/// Konfigurasi freezed untuk semua event/state Bloc.
///
/// `when/maybeWhen/whenOrNull` diaktifkan eksplisit karena halaman-halaman
/// memakainya; dengan begini tidak bergantung pada nilai default versi freezed.
const blocFreezed = Freezed(when: FreezedWhenOptions.all);
