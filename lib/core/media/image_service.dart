import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';


/// Memilih gambar (kamera/galeri) lalu mengompres di klien hingga <= [maxKb].
class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Mengembalikan bytes JPEG terkompres, atau null bila dibatalkan.
  /// Hasil bisa tetap melebihi [maxKb]; pemanggil wajib memeriksa.
  Future<Uint8List?> pick({required bool camera, required int maxKb}) async {
    final file = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
    );
    if (file == null) return null;

    var quality = 85;
    var size = 1920;
    Uint8List? out;
    while (true) {
      out = await FlutterImageCompress.compressWithFile(
        file.path,
        minWidth: size,
        minHeight: size,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (out == null) return null;
      if (out.lengthInBytes <= maxKb * 1024 || quality <= 40) return out;
      quality -= 15;
      size = (size * 0.8).round();
    }
  }
}
