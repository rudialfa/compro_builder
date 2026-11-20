import 'package:flutter/material.dart';

/// Jenis blok Markdown sederhana yang didukung (sama dengan petunjuk di form
/// section Tentang: `### judul`, `**tebal**`, daftar `-` / `1.`, paragraf).
enum MdBlockType { heading, paragraph, bullet, numbered }

class MdBlock {
  final MdBlockType type;
  final String text;

  /// Nomor urut untuk [MdBlockType.numbered].
  final int? number;
  const MdBlock(this.type, this.text, {this.number});

  @override
  bool operator ==(Object other) =>
      other is MdBlock &&
      other.type == type &&
      other.text == text &&
      other.number == number;

  @override
  int get hashCode => Object.hash(type, text, number);

  @override
  String toString() => 'MdBlock($type, "$text", $number)';
}

final _headingRe = RegExp(r'^\s{0,3}#{1,6}\s+(.*?)\s*#*\s*$');
final _bulletRe = RegExp(r'^\s*[-*+]\s+(.*)$');
final _numberedRe = RegExp(r'^\s*(\d+)[.)]\s+(.*)$');

/// Memecah teks jadi blok. Baris kosong memisahkan paragraf; baris tunggal di
/// dalam paragraf tetap jadi baris baru (sama dengan perilaku server).
List<MdBlock> parseMarkdown(String source) {
  final blocks = <MdBlock>[];
  final para = <String>[];

  void flush() {
    if (para.isEmpty) return;
    blocks.add(MdBlock(MdBlockType.paragraph, para.join('\n')));
    para.clear();
  }

  for (final raw in source.replaceAll('\r\n', '\n').split('\n')) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) {
      flush();
      continue;
    }
    final h = _headingRe.firstMatch(line);
    if (h != null) {
      flush();
      blocks.add(MdBlock(MdBlockType.heading, h.group(1)!));
      continue;
    }
    final n = _numberedRe.firstMatch(line);
    if (n != null) {
      flush();
      blocks.add(
        MdBlock(
          MdBlockType.numbered,
          n.group(2)!,
          number: int.parse(n.group(1)!),
        ),
      );
      continue;
    }
    final b = _bulletRe.firstMatch(line);
    if (b != null) {
      flush();
      blocks.add(MdBlock(MdBlockType.bullet, b.group(1)!));
      continue;
    }
    para.add(line.trim());
  }
  flush();
  return blocks;
}

// **tebal** | *miring* | `kode` | [teks](tautan)
final _inlineRe = RegExp(
  r'\*\*(.+?)\*\*|\*(.+?)\*|`([^`]+)`|\[([^\]]+)\]\(([^)\s]+)\)',
);

/// Gaya inline. Tautan hanya ditampilkan sebagai teks bergaris bawah (tidak bisa
/// diketuk) karena ini pratinjau, bukan halaman pengunjung.
List<InlineSpan> inlineSpans(String text, TextStyle? base) {
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in _inlineRe.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
    }
    if (m.group(1) != null) {
      spans.add(
        TextSpan(
          text: m.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    } else if (m.group(2) != null) {
      spans.add(
        TextSpan(
          text: m.group(2),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    } else if (m.group(3) != null) {
      spans.add(
        TextSpan(
          text: m.group(3),
          style: const TextStyle(fontFamily: 'monospace'),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: m.group(4),
          style: const TextStyle(decoration: TextDecoration.underline),
        ),
      );
    }
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return spans;
}

/// Pratinjau Markdown sederhana (tanpa paket tambahan).
class SimpleMarkdown extends StatelessWidget {
  const SimpleMarkdown(this.source, {super.key});

  final String source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium;
    final blocks = parseMarkdown(source);

    Widget rich(String text, {TextStyle? style}) =>
        Text.rich(TextSpan(style: style ?? body, children: inlineSpans(text, body)));

    Widget item(String marker, String text) => Padding(
      padding: const EdgeInsets.only(top: 4, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, child: Text(marker, style: body)),
          Expanded(child: rich(text)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++)
          switch (blocks[i].type) {
            MdBlockType.heading => Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
              child: Semantics(
                header: true,
                child: rich(
                  blocks[i].text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            MdBlockType.paragraph => Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
              child: rich(blocks[i].text),
            ),
            MdBlockType.bullet => item('•', blocks[i].text),
            MdBlockType.numbered => item(
              '${blocks[i].number}.',
              blocks[i].text,
            ),
          },
      ],
    );
  }
}
