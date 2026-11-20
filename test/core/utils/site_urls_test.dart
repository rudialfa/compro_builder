import 'package:compro_builder/core/utils/site_urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = 'http://192.168.1.137:8000';

  test('url server yang valid dipakai apa adanya (tanpa garis miring akhir)', () {
    expect(publicSiteUrl('https://toko.com/', base, 'toko'), 'https://toko.com');
  });

  test('url kosong -> basis app + slug', () {
    expect(publicSiteUrl(null, base, 'toko'), '$base/toko');
    expect(publicSiteUrl('  ', base, 'toko'), '$base/toko');
  });

  test('url server 127.0.0.1/localhost diganti host app bila app bukan loopback', () {
    expect(publicSiteUrl('http://127.0.0.1:8000/toko', base, 'toko'), '$base/toko');
    expect(publicSiteUrl('http://localhost:8000/toko', base, 'toko'), '$base/toko');
  });

  test('bila app juga loopback, url server tetap dipakai', () {
    expect(
      publicSiteUrl('http://127.0.0.1:8000/toko', 'http://127.0.0.1:8000', 'toko'),
      'http://127.0.0.1:8000/toko',
    );
  });

  group('decideNavigation (pindah halaman di WebView pratinjau)', () {
    final site = Uri.parse('http://192.168.1.137:8000/maman-corp');

    test('halaman lain di situs yang sama tetap di WebView', () {
      for (final path in [
        '/maman-corp',
        '/maman-corp/layanan',
        '/maman-corp/layanan/kopi-susu',
        '/maman-corp/galeri/suasana-toko',
        '/maman-corp/kontak',
        '/maman-corp#tentang',
      ]) {
        final target = Uri.parse('http://192.168.1.137:8000$path');
        expect(decideNavigation(target, site), NavDecision.allow, reason: path);
      }
    });

    test('host lain dibuka di luar; tel/mailto/wa ke aplikasi luar', () {
      expect(decideNavigation(Uri.parse('https://wa.me/62812'), site), NavDecision.external);
      expect(decideNavigation(Uri.parse('https://instagram.com/x'), site), NavDecision.external);
      expect(decideNavigation(Uri.parse('tel:+62812'), site), NavDecision.external);
      expect(decideNavigation(Uri.parse('mailto:a@b.id'), site), NavDecision.external);
    });

    test('skema berbahaya diblokir', () {
      expect(decideNavigation(Uri.parse('javascript:alert(1)'), site), NavDecision.block);
      expect(decideNavigation(Uri.parse('file:///etc/passwd'), site), NavDecision.block);
      expect(decideNavigation(Uri.parse('intent://x#Intent;end'), site), NavDecision.block);
    });

    test('port berbeda dianggap situs lain', () {
      expect(
        decideNavigation(Uri.parse('http://192.168.1.137:9000/maman-corp'), site),
        NavDecision.external,
      );
    });
  });

  group('needsAuthHeader (situs draft)', () {
    final api = Uri.parse('http://192.168.1.137:8000');

    test('draft + host API -> bawa token', () {
      expect(needsAuthHeader(Uri.parse('http://192.168.1.137:8000/toko/layanan'), api, draft: true), isTrue);
    });

    test('sudah tayang -> tanpa token', () {
      expect(needsAuthHeader(Uri.parse('http://192.168.1.137:8000/toko/layanan'), api, draft: false), isFalse);
    });

    test('host lain tidak pernah menerima token', () {
      expect(needsAuthHeader(Uri.parse('https://toko.com/layanan'), api, draft: true), isFalse);
      expect(needsAuthHeader(Uri.parse('tel:+62812'), api, draft: true), isFalse);
    });
  });

  test('isSamePageIgnoringFragment: hanya beda #anchor = halaman sama', () {
    expect(
      isSamePageIgnoringFragment(Uri.parse('http://h/toko#kontak'), Uri.parse('http://h/toko')),
      isTrue,
    );
    expect(
      isSamePageIgnoringFragment(Uri.parse('http://h/toko/layanan'), Uri.parse('http://h/toko')),
      isFalse,
    );
  });
}
