import 'package:compro_builder/data/model/response/template_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TemplateOptionModel membaca palette dan preview_image', () {
    final t = TemplateOptionModel.fromMap({
      'code': 'gelap',
      'name': 'Gelap',
      'palette': {'brand': '#1E2A5E', 'bright': '#F2B01E', 'soft': '#F3F4F8'},
      'preview_image': 'http://192.168.1.137:8000/img/gelap.png',
    });
    expect(t.palette['brand'], '#1E2A5E');
    expect(t.previewImage, endsWith('gelap.png'));
  });

  test('tanpa palette/preview_image = nilai kosong, tidak error', () {
    final t = TemplateOptionModel.fromMap({'code': 'classic', 'name': 'Classic'});
    expect(t.palette, isEmpty);
    expect(t.previewImage, '');
  });
}
