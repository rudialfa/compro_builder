import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Contoh tampilan (thumbnail) satu template, digambar langsung dengan widget
/// Flutter supaya tidak butuh WebView, internet, atau CSS dari server.
/// Bentuknya meniru thumbnail Blade di web (resources/views/templates/{code}/thumb).
///
/// [palette] berisi hex `brand`, `bright`, `soft` dari server; kosong = warna bawaan.
/// Kode template yang tidak dikenal memakai tampilan Classic.
class TemplateThumb extends StatelessWidget {
  final String code;
  final Map<String, String> palette;
  final String? imageUrl;
  final double aspectRatio;
  final BorderRadius borderRadius;

  const TemplateThumb({
    super.key,
    required this.code,
    this.palette = const {},
    this.imageUrl,
    this.aspectRatio = 16 / 10,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final p = _Pal(
      brand: _hex(palette['brand'], const Color(0xFF1E2A5E)),
      bright: _hex(palette['bright'], const Color(0xFFF2B01E)),
      soft: _hex(palette['soft'], const Color(0xFFF3F4F8)),
    );
    final url = imageUrl;
    return ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _drawn(p),
              )
            : _drawn(p),
      ),
    );
  }

  Widget _drawn(_Pal p) => LayoutBuilder(
    builder: (context, c) => _Canvas(
      w: c.maxWidth,
      h: c.maxHeight,
      children: (cv) => _layout(code, cv, p),
    ),
  );
}

// ─── Utilitas ────────────────────────────────────────────────────────────────

class _Pal {
  final Color brand, bright, soft;
  const _Pal({required this.brand, required this.bright, required this.soft});
}

Color _hex(String? v, Color fallback) {
  if (v == null) return fallback;
  var s = v.trim().replaceFirst('#', '');
  if (s.length == 3) s = s.split('').map((c) => '$c$c').join();
  if (s.length == 6) s = 'FF$s';
  final n = int.tryParse(s, radix: 16);
  return (s.length == 8 && n != null) ? Color(n) : fallback;
}

Color _a(Color c, double o) => c.withValues(alpha: o);

/// Kanvas dengan ukuran piksel; semua elemen memakai pecahan 0..1 dari lebar/tinggi.
class _Canvas extends StatelessWidget {
  final double w, h;
  final List<Widget> Function(_Cv cv) children;
  const _Canvas({required this.w, required this.h, required this.children});

  @override
  Widget build(BuildContext context) =>
      Stack(clipBehavior: Clip.hardEdge, children: children(_Cv(w, h)));
}

class _Cv {
  final double w, h;
  const _Cv(this.w, this.h);

  /// Kotak berposisi mutlak. Semua angka pecahan dari lebar (x, w) / tinggi (y, h).
  Widget box(
    double x,
    double y,
    double bw,
    double bh, {
    Color? color,
    Gradient? gradient,
    double radius = 3,
    Border? border,
    List<BoxShadow>? shadow,
    double rotate = 0,
    BoxShape shape = BoxShape.rectangle,
    Widget? child,
  }) {
    Widget b = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        border: border,
        boxShadow: shadow,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(radius),
      ),
      child: child,
    );
    if (rotate != 0) b = Transform.rotate(angle: rotate * math.pi / 180, child: b);
    return Positioned(
      left: x * w,
      top: y * h,
      width: math.max(1.0, bw * w),
      height: math.max(1.0, bh * h),
      child: b,
    );
  }

  /// Kotak rata tengah horizontal.
  Widget mid(
    double y,
    double bw,
    double bh, {
    Color? color,
    Gradient? gradient,
    double radius = 3,
    Border? border,
    List<BoxShadow>? shadow,
  }) => box(
    (1 - bw) / 2,
    y,
    bw,
    bh,
    color: color,
    gradient: gradient,
    radius: radius,
    border: border,
    shadow: shadow,
  );

  Widget fill(Widget child) =>
      Positioned.fill(child: child);

  Widget blob(double x, double y, double size, Color c, {double blur = 0}) {
    final d = size * w;
    Widget circle = DecoratedBox(
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
    if (blur > 0) {
      circle = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: circle,
      );
    }
    return Positioned(left: x * w, top: y * h, width: d, height: d, child: circle);
  }
}

Gradient _radial(Alignment at, Color c, {double r = 0.9}) => RadialGradient(
  center: at,
  radius: r,
  colors: [c, _a(c, 0)],
  stops: const [0, 1],
);

Widget _glow(_Cv cv, Alignment at, Color c, {double r = 0.9}) =>
    cv.fill(DecoratedBox(decoration: BoxDecoration(gradient: _radial(at, c, r: r))));

// ─── Tata letak per template ─────────────────────────────────────────────────

List<Widget> _layout(String code, _Cv v, _Pal p) {
  const white = Colors.white;
  switch (code) {
    case 'abstrak':
      return [
        v.fill(ColoredBox(color: p.brand)),
        _glow(v, const Alignment(-0.8, -0.9), const Color(0xFFFF4D8D), r: 1.1),
        _glow(v, const Alignment(1.0, -0.2), p.bright, r: 1.0),
        _glow(v, const Alignment(0.1, 1.2), const Color(0xFF7C3AED), r: 1.0),
        v.box(0.07, 0.2, 0.6, 0.1, color: _a(white, .92)),
        v.box(0.07, 0.36, 0.4, 0.1, color: _a(white, .92)),
        v.box(0.07, 0.78, 0.33, 0.045, color: _a(white, .7)),
        v.box(0.07, 0.88, 0.25, 0.045, color: _a(white, .7)),
      ];
    case 'aurora':
      return [
        v.fill(ColoredBox(color: p.brand)),
        _glow(v, const Alignment(0.9, -0.9), p.bright, r: 1.1),
        _glow(v, const Alignment(-0.9, 1.0), const Color(0xFF8B5CF6), r: 1.1),
        v.box(0.07, 0.2, 0.4, 0.09, color: white),
        v.box(0.07, 0.34, 0.25, 0.09, color: white),
        v.box(0.07, 0.68, 0.2, 0.15, color: white, radius: 20),
        v.box(
          0.57,
          0.14,
          0.36,
          0.62,
          color: _a(white, .2),
          radius: 14,
          border: Border.all(color: _a(white, .4)),
        ),
      ];
    case 'bersih':
      return [
        v.fill(const ColoredBox(color: white)),
        v.mid(0.2, 0.66, 0.09, color: p.brand),
        v.mid(0.34, 0.5, 0.09, color: p.brand),
        v.mid(0.5, 0.6, 0.04, color: const Color(0xFFD1D5DB)),
        v.mid(0.64, 0.28, 0.15, color: p.brand, radius: 6),
      ];
    case 'blueprint':
      return [
        v.fill(ColoredBox(color: p.brand)),
        v.fill(CustomPaint(painter: _GridPainter(_a(white, .12), v.w / 22))),
        v.box(0.07, 0.15, 0.25, 0.04, color: _a(white, .6)),
        v.box(0.07, 0.3, 0.4, 0.09, color: white),
        v.box(0.07, 0.44, 0.25, 0.09, color: white),
        v.box(0.07, 0.72, 0.22, 0.14, border: Border.all(color: white), radius: 0),
        v.box(
          0.55,
          0.15,
          0.38,
          0.6,
          border: Border.all(color: _a(white, .7)),
          radius: 0,
        ),
      ];
    case 'boho':
      const ink = Color(0xFF4B3A30);
      const terra = Color(0xFFB8654A);
      return [
        v.fill(const ColoredBox(color: Color(0xFFF1EAE0))),
        v.box(0.07, 0.12, 0.86, 0.001, color: _a(const Color(0xFF78553C), .35)),
        v.box(0.07, 0.04, 0.33, 0.08, color: ink),
        v.box(0.73, 0.06, 0.2, 0.06, color: _a(terra, .8)),
        v.box(0.12, 0.32, 0.3, 0.58, color: const Color(0xFFE1D2BF), radius: 60),
        v.box(0.07, 0.28, 0.3, 0.58, border: Border.all(color: terra), radius: 60),
        v.box(0.63, 0.7, 0.3, 0.04, color: _a(ink, .4)),
        v.box(0.69, 0.79, 0.24, 0.04, color: _a(ink, .4)),
      ];
    case 'botani':
      const leaf = Color(0xFF3F6B4A);
      const deep = Color(0xFF2F5238);
      return [
        v.fill(const ColoredBox(color: Color(0xFFEEF3E6))),
        v.blob(-0.05, -0.12, 0.2, _a(leaf, .2)),
        v.box(0.07, 0.2, 0.4, 0.09, color: deep),
        v.box(0.07, 0.34, 0.25, 0.09, color: deep),
        v.box(0.07, 0.68, 0.2, 0.15, color: leaf, radius: 20),
        v.box(
          0.55,
          0.1,
          0.38,
          0.62,
          color: leaf,
          radius: 60,
          border: Border.all(color: white, width: 4),
        ),
      ];
    case 'elegan':
      return [
        v.fill(ColoredBox(color: p.brand)),
        v.mid(0.17, 0.12, 0.004, color: p.bright),
        v.mid(0.27, 0.6, 0.09, color: white),
        v.mid(0.41, 0.4, 0.09, color: white),
        v.mid(0.56, 0.5, 0.04, color: _a(white, .5)),
        v.mid(0.68, 0.26, 0.15, border: Border.all(color: p.bright), radius: 0),
      ];
    case 'emas':
      const gold = Color(0xFFC9A24B);
      return [
        v.fill(const ColoredBox(color: Color(0xFF0E0C09))),
        v.box(0.05, 0.08, 0.9, 0.84, border: Border.all(color: gold), radius: 0),
        v.mid(0.2, 0.12, 0.02, color: gold),
        v.mid(0.3, 0.6, 0.1, color: const Color(0xFFE9D29A)),
        v.mid(0.45, 0.4, 0.1, color: const Color(0xFFE9D29A)),
        v.mid(0.62, 0.22, 0.14, border: Border.all(color: gold), radius: 0),
      ];
    case 'gelap':
      return [
        v.fill(const ColoredBox(color: Color(0xFF0B1020))),
        v.blob(0.75, -0.3, 0.4, _a(p.bright, .45), blur: 22),
        v.mid(0.16, 0.2, 0.07, color: _a(white, .1), radius: 20, border: Border.all(color: _a(white, .3))),
        v.mid(0.3, 0.6, 0.1, color: white),
        v.mid(0.44, 0.4, 0.1, color: p.bright),
        v.mid(
          0.62,
          0.26,
          0.15,
          color: p.bright,
          radius: 20,
          shadow: [BoxShadow(color: _a(p.bright, .7), blurRadius: 16)],
        ),
      ];
    case 'hangat':
      // Gaya musim gugur: latar persik, daun, bunga matahari, foto berbingkai, pita cokelat.
      const rust = Color(0xFFA63D12);
      const bark = Color(0xFF4A1D12);
      return [
        v.fill(const ColoredBox(color: Color(0xFFF6DCC6))),
        v.box(-0.06, -0.14, 0.22, 0.42, rotate: 14, radius: 40, color: const Color(0xFFD9822B)),
        v.box(0.86, -0.12, 0.2, 0.38, rotate: -14, radius: 40, color: const Color(0xFFC9561F)),
        v.blob(0.6, 0.04, 0.07, const Color(0xFFF2B632)),
        v.box(0.06, 0.34, 0.5, 0.1, color: rust, radius: 20),
        v.box(0.06, 0.5, 0.34, 0.1, color: rust, radius: 20),
        v.box(0.06, 0.7, 0.18, 0.14, color: const Color(0xFF6B3A1C), radius: 20),
        v.box(
          0.7,
          0.3,
          0.24,
          0.46,
          radius: 10,
          color: const Color(0xFFE8B98A),
          border: Border.all(color: white, width: 3),
          shadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
        ),
        v.box(0, 0.9, 1, 0.1, color: bark, radius: 0),
      ];
    case 'imersif':
      return [
        v.fill(
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.brand, Colors.black],
              ),
            ),
          ),
        ),
        _glow(v, const Alignment(0.8, -0.9), _a(p.bright, .6), r: 1.0),
        _glow(v, const Alignment(-1, 1), const Color(0xAA8B5CF6), r: 1.0),
        v.box(0.07, 0.14, 0.12, 0.02, color: _a(white, .6)),
        v.box(0.07, 0.22, 0.6, 0.1, color: white),
        v.box(0.07, 0.36, 0.4, 0.1, color: white),
        v.box(0.07, 0.52, 0.2, 0.12, color: p.bright, radius: 20),
        for (var i = 0; i < 3; i++)
          v.box(
            0.07 + i * 0.3,
            0.74,
            0.26,
            0.16,
            color: _a(white, .15),
            radius: 8,
            border: Border.all(color: _a(white, .3)),
          ),
      ];
    case 'inovasi':
      return [
        v.fill(const ColoredBox(color: white)),
        v.box(0.07, 0.2, 0.4, 0.09, color: const Color(0xFF111827)),
        v.box(
          0.07,
          0.34,
          0.24,
          0.09,
          gradient: LinearGradient(colors: [p.brand, p.bright]),
        ),
        v.box(0.07, 0.52, 0.2, 0.025, color: p.bright, radius: 4),
        v.box(0.07, 0.64, 0.2, 0.14, color: p.brand, radius: 20),
        v.box(
          0.58,
          0.14,
          0.14,
          0.62,
          rotate: -6,
          radius: 8,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.brand, p.bright],
          ),
        ),
        v.box(
          0.78,
          0.2,
          0.14,
          0.62,
          rotate: 6,
          radius: 8,
          color: p.soft,
          border: Border.all(color: p.bright),
        ),
        v.box(
          0.62,
          0.1,
          0.17,
          0.72,
          radius: 12,
          color: white,
          border: Border.all(color: const Color(0xFF111827), width: 4),
          shadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8)],
        ),
      ];
    case 'kolase':
      return [
        v.fill(const ColoredBox(color: Color(0xFFF6EFE2))),
        v.box(0.07, 0.2, 0.4, 0.09, color: const Color(0xFF2B2018)),
        v.box(0.07, 0.34, 0.25, 0.09, color: const Color(0xFF2B2018)),
        v.box(
          0.07,
          0.68,
          0.2,
          0.14,
          color: p.brand,
          radius: 0,
          shadow: const [BoxShadow(color: Color(0x40000000), offset: Offset(3, 3))],
        ),
        v.box(
          0.5,
          0.12,
          0.22,
          0.5,
          rotate: -9,
          radius: 0,
          color: white,
          shadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 5)],
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ColoredBox(color: p.bright),
          ),
        ),
        v.box(
          0.73,
          0.2,
          0.22,
          0.5,
          rotate: 8,
          radius: 0,
          color: white,
          shadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 5)],
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ColoredBox(color: p.brand),
          ),
        ),
      ];
    case 'korporat':
      return [
        v.fill(ColoredBox(color: p.brand)),
        v.box(0.07, 0.2, 0.006, 0.5, color: p.bright, radius: 0),
        v.box(0.12, 0.2, 0.16, 0.035, color: p.bright),
        v.box(0.12, 0.33, 0.45, 0.08, color: white),
        v.box(0.12, 0.47, 0.36, 0.08, color: white),
        v.box(0.12, 0.64, 0.2, 0.13, color: p.bright, radius: 3),
        v.box(0.65, 0.12, 0.28, 0.6, radius: 3, border: Border.all(color: _a(white, .3))),
        v.box(0, 0.975, 1, 0.025, color: p.bright, radius: 0),
      ];
    case 'kreatif':
      const ink = Color(0xFF111111);
      return [
        v.fill(ColoredBox(color: p.soft)),
        v.box(
          0.07,
          0.14,
          0.2,
          0.1,
          rotate: -2,
          radius: 0,
          color: p.bright,
          border: Border.all(color: ink, width: 2),
          shadow: const [BoxShadow(color: ink, offset: Offset(2, 2))],
        ),
        v.box(0.07, 0.34, 0.5, 0.08, color: p.brand),
        v.box(0.07, 0.48, 0.4, 0.08, color: p.brand),
        v.box(
          0.07,
          0.7,
          0.24,
          0.15,
          color: p.brand,
          radius: 8,
          border: Border.all(color: ink, width: 2),
          shadow: const [BoxShadow(color: ink, offset: Offset(3, 3))],
        ),
        v.box(
          0.6,
          0.14,
          0.34,
          0.62,
          rotate: 3,
          radius: 10,
          color: p.bright,
          border: Border.all(color: ink, width: 2),
          shadow: const [BoxShadow(color: ink, offset: Offset(4, 4))],
        ),
      ];
    case 'majalah':
      return [
        v.fill(const ColoredBox(color: white)),
        v.box(0.07, 0.1, 0.86, 0.001, color: p.brand, radius: 0),
        v.box(0.07, 0.17, 0.86, 0.001, color: p.brand, radius: 0),
        v.box(0.07, 0.125, 0.12, 0.02, color: p.brand),
        v.box(0.79, 0.125, 0.14, 0.02, color: p.brand),
        v.box(0.07, 0.3, 0.6, 0.13, color: p.brand),
        v.box(0.07, 0.48, 0.4, 0.13, color: p.brand),
        v.box(0.7, 0.62, 0.003, 0.28, color: p.brand, radius: 0),
        v.box(0.73, 0.64, 0.2, 0.035, color: const Color(0xFFD1D5DB)),
        v.box(0.73, 0.72, 0.16, 0.035, color: const Color(0xFFD1D5DB)),
        v.box(0.73, 0.8, 0.12, 0.035, color: const Color(0xFFD1D5DB)),
      ];
    case 'minimalis':
      // Gaya "Minimalist Business": krem, garis tipis atas-bawah, judul terpusat.
      const mnInk = Color(0xFF2B2B2B);
      return [
        v.fill(const ColoredBox(color: Color(0xFFF4F1EA))),
        v.box(0, 0.09, 1, 0.006, color: _a(mnInk, .75), radius: 0),
        v.box(0, 0.91, 1, 0.006, color: _a(mnInk, .75), radius: 0),
        v.box(0.04, 0.12, 0.3, 0.22, radius: 40, border: Border.all(color: _a(mnInk, .5))),
        v.box(0.66, 0.66, 0.3, 0.22, radius: 40, border: Border.all(color: _a(mnInk, .5))),
        v.mid(0.3, 0.6, 0.11, color: mnInk, radius: 2),
        v.mid(0.46, 0.4, 0.11, color: mnInk, radius: 2),
        v.mid(0.66, 0.25, 0.04, color: _a(mnInk, .4)),
      ];
    case 'modern':
      return [
        v.fill(ColoredBox(color: p.soft)),
        v.box(0.07, 0.2, 0.4, 0.08, color: p.brand),
        v.box(0.07, 0.33, 0.32, 0.08, color: p.brand),
        v.box(0.07, 0.48, 0.4, 0.04, color: const Color(0xFFD1D5DB)),
        v.box(
          0.07,
          0.64,
          0.2,
          0.15,
          color: p.brand,
          radius: 8,
          shadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
        ),
        v.box(0.54, 0.08, 0.4, 0.62, color: _a(p.bright, .6), radius: 16),
        v.box(
          0.51,
          0.12,
          0.4,
          0.62,
          color: p.brand,
          radius: 16,
          shadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 10)],
        ),
      ];
    case 'panorama':
      return [
        v.fill(
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.brand, Colors.black],
              ),
            ),
          ),
        ),
        _glow(v, const Alignment(0.8, -0.8), _a(p.bright, .53), r: 1.0),
        v.fill(ColoredBox(color: _a(Colors.black, .3))),
        v.mid(0.22, 0.6, 0.1, color: white),
        v.mid(0.36, 0.4, 0.1, color: white),
        v.mid(0.52, 0.5, 0.04, color: _a(white, .6)),
        v.mid(0.64, 0.26, 0.15, color: p.bright, radius: 20),
      ];
    case 'pastel':
      // Gaya "Falling Snow": periwinkle, tetesan putih di atas, titik jatuh, foto bulat.
      const snow = Color(0xFFFFFDFA);
      return [
        v.fill(const ColoredBox(color: Color(0xFF8497DC))),
        v.box(0, -0.06, 1, 0.2, color: snow, radius: 0),
        for (final d in const [
          [0.08, 0.08, 0.1],
          [0.3, 0.1, 0.12],
          [0.52, 0.08, 0.09],
          [0.74, 0.1, 0.11],
        ])
          v.blob(d[0], d[1], d[2], snow),
        v.blob(0.12, 0.38, 0.015, _a(white, .85)),
        v.blob(0.48, 0.8, 0.015, _a(white, .85)),
        v.blob(0.86, 0.3, 0.012, _a(white, .85)),
        v.box(0.06, 0.4, 0.4, 0.1, color: white, radius: 20),
        v.box(0.06, 0.55, 0.25, 0.1, color: white, radius: 20),
        v.box(0.06, 0.74, 0.18, 0.13, color: const Color(0xFFFFE08A), radius: 20),
        v.box(
          0.58,
          0.3,
          0.34,
          0.56,
          shape: BoxShape.circle,
          color: const Color(0xFFD4C8FF),
          border: Border.all(color: white, width: 4),
        ),
      ];
    case 'retro':
      return [
        v.fill(const ColoredBox(color: Color(0xFFFBF5E6))),
        v.box(
          0.05,
          0.08,
          0.9,
          0.84,
          radius: 12,
          border: Border.all(color: p.brand, width: 4),
        ),
        v.box(0.12, 0.2, 0.16, 0.07, radius: 20, border: Border.all(color: p.brand, width: 2)),
        v.box(0.12, 0.34, 0.5, 0.09, color: p.brand),
        v.box(0.12, 0.48, 0.4, 0.09, color: p.brand),
        v.box(0.66, 0.24, 0.24, 0.62, color: p.brand, radius: 60),
      ];
    case 'sinema':
      return [
        v.fill(
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.brand, Colors.black],
              ),
            ),
          ),
        ),
        _glow(v, const Alignment(0.5, -0.6), _a(p.bright, .47), r: 1.0),
        v.fill(
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [_a(Colors.black, .75), _a(Colors.black, .1)],
              ),
            ),
          ),
        ),
        v.box(0.07, 0.18, 0.12, 0.02, color: _a(white, .6)),
        v.box(0.07, 0.28, 0.6, 0.1, color: white),
        v.box(0.07, 0.42, 0.4, 0.1, color: white),
        v.box(0.07, 0.72, 0.2, 0.15, color: p.bright, radius: 8),
        v.box(0.32, 0.8, 0.15, 0.02, color: _a(white, .7)),
      ];
    case 'warisan':
      return [
        v.fill(const ColoredBox(color: Color(0xFF1A1411))),
        _glow(v, const Alignment(0.7, -0.8), _a(p.bright, .33), r: 1.0),
        v.fill(ColoredBox(color: _a(const Color(0xFF0F0A06), .5))),
        v.box(0.07, 0.14, 0.12, 0.02, color: _a(white, .5)),
        v.box(0.07, 0.28, 0.6, 0.09, color: _a(white, .9)),
        v.box(0.07, 0.42, 0.4, 0.09, color: _a(white, .9)),
        v.box(0.07, 0.78, 0.33, 0.04, color: _a(white, .5)),
        v.box(0.07, 0.88, 0.25, 0.04, color: _a(white, .5)),
        v.box(0.93, 0, 0.002, 1, color: _a(white, .4), radius: 0),
      ];
    case 'studio':
      // Studio Pop (Pro): poster neo-brutalis, bingkai tebal dan bayangan keras.
      const sInk = Color(0xFF111111);
      return [
        v.fill(const ColoredBox(color: Color(0xFFFFFAF0))),
        v.fill(CustomPaint(painter: _DotPainter(_a(sInk, .16), v.w / 24))),
        v.box(
          0.06,
          0.1,
          0.22,
          0.1,
          rotate: -3,
          radius: 20,
          color: const Color(0xFFFF7AB6),
          border: Border.all(color: sInk, width: 2),
        ),
        v.box(0.06, 0.34, 0.5, 0.1, color: sInk, radius: 0),
        v.box(
          0.06,
          0.5,
          0.34,
          0.1,
          rotate: -2,
          radius: 0,
          color: p.bright,
          border: Border.all(color: sInk, width: 2),
        ),
        v.box(
          0.06,
          0.7,
          0.2,
          0.14,
          radius: 6,
          color: sInk,
          shadow: [BoxShadow(color: p.bright, offset: const Offset(3, 3))],
        ),
        v.box(
          0.56,
          0.1,
          0.36,
          0.6,
          rotate: 3,
          radius: 8,
          color: p.brand,
          border: Border.all(color: sInk, width: 3),
          shadow: const [BoxShadow(color: sInk, offset: Offset(5, 5))],
        ),
        v.blob(0.84, 0.02, 0.1, const Color(0xFF7AE6C3)),
        v.box(0, 0.9, 1, 0.1, color: sInk, radius: 0),
      ];
    case 'classic':
    default:
      return [
        v.fill(ColoredBox(color: p.brand)),
        v.box(0.07, 0.22, 0.5, 0.09, color: white),
        v.box(0.07, 0.36, 0.4, 0.09, color: white),
        v.box(0.07, 0.54, 0.4, 0.04, color: _a(white, .6)),
        v.box(0.07, 0.68, 0.24, 0.14, color: p.bright, radius: 20),
      ];
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final double step;
  const _GridPainter(this.color, this.step);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.color != color || old.step != step;
}

class _DotPainter extends CustomPainter {
  final Color color;
  final double step;
  const _DotPainter(this.color, this.step);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double x = step / 2; x < size.width; x += step) {
      for (double y = step / 2; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter old) => old.color != color || old.step != step;
}
