import 'dart:typed_data';

/// File gambar baru yang akan diunggah (multipart).
class UploadFile {
  final Uint8List bytes;
  final String filename;
  const UploadFile(this.bytes, this.filename);
}

class FlatPayload {
  final List<MapEntry<String, String>> fields;
  final List<MapEntry<String, UploadFile>> files;
  const FlatPayload(this.fields, this.files);
}

/// Meratakan payload ke kunci multipart ala PHP: `items[0][image]`, `items[0][title]`.
/// Boolean dikirim sebagai '1'/'0'; nilai null dilewati.
FlatPayload flattenPayload(Map<String, dynamic> payload) {
  final fields = <MapEntry<String, String>>[];
  final files = <MapEntry<String, UploadFile>>[];

  void walk(String key, Object? v) {
    switch (v) {
      case null:
        break;
      case UploadFile f:
        files.add(MapEntry(key, f));
      case Map m:
        m.forEach((k, val) => walk('$key[$k]', val));
      case List l:
        for (var i = 0; i < l.length; i++) {
          walk('$key[$i]', l[i]);
        }
      case bool b:
        fields.add(MapEntry(key, b ? '1' : '0'));
      default:
        fields.add(MapEntry(key, '$v'));
    }
  }

  payload.forEach(walk);
  return FlatPayload(fields, files);
}
