import 'package:flutter/material.dart';

/// Ikon per tipe section; tipe baru/tak dikenal memakai ikon cadangan.
IconData sectionIcon(String type) => switch (type) {
  'hero' => Icons.panorama_outlined,
  'about' => Icons.info_outline,
  'services' => Icons.handyman_outlined,
  'menu' => Icons.restaurant_menu,
  'contact' => Icons.contact_phone_outlined,
  'features' => Icons.star_outline,
  'gallery' => Icons.photo_library_outlined,
  'testimonials' => Icons.format_quote,
  'faq' => Icons.help_outline,
  'team' => Icons.groups_outlined,
  'map' => Icons.map_outlined,
  'footer' => Icons.vertical_align_bottom,
  _ => Icons.widgets_outlined,
};

/// Nama section untuk ditampilkan di aplikasi. Hanya label: kode tipe (`hero`) dan
/// nama dari server tidak berubah. Tipe `hero` tampil sebagai "Banner Utama".
String sectionLabel(String type, String name) =>
    type == 'hero' ? 'Banner Utama' : name;
