import 'dart:convert';

import 'package:compro_builder/data/model/response/address_response_model.dart';
import 'package:compro_builder/data/model/response/domain_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SlugCheckModel', () {
    test('tersedia', () {
      final m = SlugCheckModel.fromJson(
        jsonEncode({
          'data': {
            'ok': true,
            'state': 'available',
            'message': 'Alamat ini tersedia.',
            'suggestion': null,
            'slug': 'toko-baru',
          },
        }),
      );
      expect(m.ok, isTrue);
      expect(m.status, SlugCheckStatus.available);
      expect(m.slug, 'toko-baru');
      expect(m.suggestion, isNull);
    });

    test('dipakai: membawa suggestion', () {
      final m = SlugCheckModel.fromMap({
        'data': {
          'ok': false,
          'state': 'taken',
          'message': 'Alamat ini sudah dipakai orang lain.',
          'suggestion': 'toko-2',
          'slug': 'toko',
        },
      });
      expect(m.ok, isFalse);
      expect(m.status, SlugCheckStatus.taken);
      expect(m.suggestion, 'toko-2');
    });

    test('semua state dikenal, selain itu unknown', () {
      SlugCheckStatus of(String s) => SlugCheckModel.fromMap({'state': s}).status;
      expect(of('empty'), SlugCheckStatus.empty);
      expect(of('invalid'), SlugCheckStatus.invalid);
      expect(of('same'), SlugCheckStatus.same);
      expect(of('reserved'), SlugCheckStatus.reserved);
      expect(of('lain'), SlugCheckStatus.unknown);
    });
  });

  group('SlugChangeResponseModel', () {
    test('membaca tenantSummary dan old_slug', () {
      final m = SlugChangeResponseModel.fromJson(
        jsonEncode({
          'data': {'id': 1, 'name': 'Kopi Kita', 'slug': 'kopi-baru'},
          'old_slug': 'kopikita',
        }),
      );
      expect(m.tenant.slug, 'kopi-baru');
      expect(m.oldSlug, 'kopikita');
    });

    test('tanpa slug -> FormatException', () {
      expect(
        () => SlugChangeResponseModel.fromJson(
          jsonEncode({'data': {'id': 1, 'name': 'X'}}),
        ),
        throwsFormatException,
      );
    });
  });

  group('DomainStatusModel', () {
    test('domain terdaftar belum terverifikasi: dns terisi', () {
      final m = DomainStatusModel.fromJson(
        jsonEncode({
          'data': {
            'allowed': true,
            'feature_ready': true,
            'host': 'kopikita.com',
            'verified': false,
            'verified_at': null,
            'active': false,
            'url': 'https://platform.com/kopikita',
            'web_url': 'https://platform.com/dashboard/tenants/1/domain',
            'dns': {
              'txt_name': '_compro-verify.kopikita.com',
              'txt_value': 'compro-verify=abc',
              'server_ip': '1.2.3.4',
              'cname_target': null,
            },
          },
        }),
      );
      expect(m.allowed, isTrue);
      expect(m.host, 'kopikita.com');
      expect(m.verified, isFalse);
      expect(m.dns?.txtName, '_compro-verify.kopikita.com');
      expect(m.dns?.serverIp, '1.2.3.4');
      expect(m.dns?.cnameTarget, isNull);
      expect(m.webUrl, contains('/domain'));
    });

    test('dns null atau kosong -> null; host kosong -> null', () {
      final a = DomainStatusModel.fromMap({
        'data': {'allowed': false, 'host': '', 'dns': null},
      });
      final b = DomainStatusModel.fromMap({
        'data': {'allowed': true, 'dns': <String, dynamic>{}},
      });
      expect(a.host, isNull);
      expect(a.dns, isNull);
      expect(b.dns, isNull);
    });

    test('terverifikasi: verifiedAt terbaca', () {
      final m = DomainStatusModel.fromMap({
        'data': {
          'host': 'a.com',
          'verified': true,
          'verified_at': '2026-11-01T00:00:00+00:00',
          'active': true,
        },
      });
      expect(m.verified, isTrue);
      expect(m.active, isTrue);
      expect(m.verifiedAt, isNotNull);
    });
  });

  group('TenantModel.domain', () {
    final json = {
      'id': 1,
      'name': 'Kopi Kita',
      'slug': 'kopikita',
      'domain': {'host': 'kopikita.com', 'verified': true, 'active': true},
    };

    test('membaca domain dari tenantSummary', () {
      final t = TenantModel.fromMap(json);
      expect(t.domain?.host, 'kopikita.com');
      expect(t.domain?.verified, isTrue);
      expect(t.domain?.active, isTrue);
    });

    test('host null = belum ada domain; cache lama tanpa domain = null', () {
      final a = TenantModel.fromMap({
        ...json,
        'domain': {'host': null, 'verified': false, 'active': false},
      });
      final b = TenantModel.fromMap({'id': 2, 'name': 'Lama', 'slug': 'lama'});
      expect(a.domain, isNotNull);
      expect(a.domain?.host, isNull);
      expect(b.domain, isNull);
    });

    test('toMap/fromMap dan copyWith menjaga domain', () {
      final t = TenantModel.fromMap(json);
      expect(TenantModel.fromJson(t.toJson()).domain?.host, 'kopikita.com');
      expect(t.copyWith(name: 'Baru').domain?.host, 'kopikita.com');
    });
  });
}
