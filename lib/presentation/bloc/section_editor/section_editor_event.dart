part of 'section_editor_bloc.dart';

/// Membangun payload dari state form. [fetch] mengunduh bytes gambar lama
/// (dipakai saat baris repeater berpindah indeks).
typedef SectionPayloadBuilder = Future<Map<String, dynamic>> Function(
  Future<Uint8List> Function(String url) fetch,
);

@blocFreezed
sealed class SectionEditorEvent with _$SectionEditorEvent {

  /// Muat section terbaru dari server.
  const factory SectionEditorEvent.load() = _Load;

  /// Simpan. Pembangunan payload (bisa mengunduh gambar) dilakukan bloc.
  const factory SectionEditorEvent.save(SectionPayloadBuilder build) = _Save;
}
