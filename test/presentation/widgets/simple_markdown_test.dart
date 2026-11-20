import 'package:compro_builder/presentation/widgets/simple_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseMarkdown: judul, paragraf (baris tunggal tetap baris baru), daftar', () {
    final blocks = parseMarkdown(
      '### Visi\nKami **melayani**\nsetulus hati\n\n- satu\n- dua\n1. a\n2) b',
    );
    expect(blocks, const [
      MdBlock(MdBlockType.heading, 'Visi'),
      MdBlock(MdBlockType.paragraph, 'Kami **melayani**\nsetulus hati'),
      MdBlock(MdBlockType.bullet, 'satu'),
      MdBlock(MdBlockType.bullet, 'dua'),
      MdBlock(MdBlockType.numbered, 'a', number: 1),
      MdBlock(MdBlockType.numbered, 'b', number: 2),
    ]);
  });

  test('parseMarkdown: baris **tebal** bukan daftar, CRLF dan teks kosong aman', () {
    expect(parseMarkdown('**tebal** saja'), const [
      MdBlock(MdBlockType.paragraph, '**tebal** saja'),
    ]);
    expect(parseMarkdown('a\r\n\r\nb'), const [
      MdBlock(MdBlockType.paragraph, 'a'),
      MdBlock(MdBlockType.paragraph, 'b'),
    ]);
    expect(parseMarkdown('   \n\n'), isEmpty);
  });

  test('inlineSpans: penanda dibuang, gaya tebal/miring dipasang', () {
    final spans = inlineSpans('a **b** *c* `d` [e](https://x.id)', null);
    expect(TextSpan(children: spans).toPlainText(), 'a b c d e');
    final bold = spans.whereType<TextSpan>().firstWhere((s) => s.text == 'b');
    expect(bold.style?.fontWeight, FontWeight.w700);
    final italic = spans.whereType<TextSpan>().firstWhere((s) => s.text == 'c');
    expect(italic.style?.fontStyle, FontStyle.italic);
  });

  testWidgets('SimpleMarkdown: "###" tidak tampil mentah', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SimpleMarkdown('### Visi\n\nKami **melayani**\n\n- satu'),
        ),
      ),
    );
    expect(find.text('Visi'), findsOneWidget);
    expect(find.text('Kami melayani'), findsOneWidget);
    expect(find.text('•'), findsOneWidget);
    expect(find.text('satu'), findsOneWidget);
    expect(find.textContaining('###'), findsNothing);
  });
}
