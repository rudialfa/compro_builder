import 'dart:convert';

import 'package:compro_builder/data/model/response/billing_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _order({
  String state = 'choose',
  String status = 'pending',
  Object? details,
  String? method,
  String? expiresAt,
  bool timedOut = false,
}) => {
  'id': 7,
  'number': 'CB-20261109-AB12CD',
  'status': status,
  'state': state,
  'months': 12,
  'amount': 490000,
  'plan': {'code': 'medium', 'name': 'Medium', 'level': 2},
  'method': method,
  'method_label': method == null ? null : 'BCA Virtual Account',
  'details': details,
  'expires_at': expiresAt,
  'timed_out': timedOut,
  'paid_at': null,
  'created_at': '2026-11-09T01:00:00+00:00',
  'web_pay_url': 'https://platform.com/dashboard/tenants/1/billing/orders/7',
};

void main() {
  group('BillingOverviewModel', () {
    final body = {
      'data': {
        'current': {
          'code': 'standar',
          'name': 'Standar',
          'level': 1,
          'expires_at': null,
          'expires_in_days': null,
        },
        'email_verified': true,
        'in_app_payment': true,
        'driver': 'midtrans',
        'methods': [
          {'code': 'bca_va', 'label': 'BCA Virtual Account', 'group': 'va'},
          {'code': 'other_qris', 'label': 'QRIS', 'group': 'qris'},
        ],
        'periods': [
          {'months': 1, 'label': '1 bulan', 'multiplier': 1},
          {'months': 12, 'label': '12 bulan', 'multiplier': 10},
        ],
        'plans': [
          {
            'code': 'standar',
            'name': 'Standar',
            'level': 1,
            'price': 0,
            'limits': {'max_sections': 5},
            'current': true,
            'buyable': false,
            'quotes': [],
          },
          {
            'code': 'medium',
            'name': 'Medium',
            'level': 2,
            'price': 49000,
            'limits': {'max_sections': 10, 'contact_form': true},
            'current': false,
            'buyable': true,
            'quotes': [
              {'months': 1, 'amount': 49000},
              {'months': 12, 'amount': 490000},
            ],
          },
        ],
        'pending_order': null,
        'web_billing_url': 'https://platform.com/dashboard/tenants/1/billing',
      },
    };

    test('membaca bentuk kontrak API.md 6.8', () {
      final m = BillingOverviewModel.fromJson(jsonEncode(body));
      expect(m.current.code, 'standar');
      expect(m.emailVerified, isTrue);
      expect(m.inAppPayment, isTrue);
      expect(m.methods.map((e) => e.code), ['bca_va', 'other_qris']);
      expect(m.methods.last.group, 'qris');
      expect(m.periods.map((e) => e.months), [1, 12]);
      expect(m.plans, hasLength(2));
      expect(m.pendingOrder, isNull);
      expect(m.webBillingUrl, endsWith('/billing'));
    });

    test('buyablePlans dan amountFor mengikuti server', () {
      final m = BillingOverviewModel.fromJson(jsonEncode(body));
      expect(m.buyablePlans.map((p) => p.code), ['medium']);
      final medium = m.plans.last;
      expect(medium.amountFor(12), 490000);
      expect(medium.amountFor(3), isNull);
      expect(m.plans.first.amountFor(1), isNull);
      expect(medium.limitRows.map((r) => r.key), ['max_sections', 'contact_form']);
    });

    test('pending_order dibaca sebagai order', () {
      final withPending = {
        'data': {
          ...(body['data'] as Map<String, dynamic>),
          'pending_order': _order(
            state: 'instructions',
            method: 'bca_va',
            details: {'type': 'va', 'bank': 'BCA', 'number': '123'},
            expiresAt: '2026-11-10T03:00:00+00:00',
          ),
        },
      };
      final m = BillingOverviewModel.fromJson(jsonEncode(withPending));
      expect(m.pendingOrder?.id, 7);
      expect(m.pendingOrder?.step, BillingOrderStep.instructions);
      expect(m.pendingOrder?.details?.number, '123');
    });

    test('bukan objek -> FormatException', () {
      expect(() => BillingOverviewModel.fromJson('[]'), throwsFormatException);
    });
  });

  group('BillingOrderModel', () {
    test('checkout: state choose tanpa details', () {
      final o = BillingOrderModel.fromJson(jsonEncode({'data': _order()}));
      expect(o.id, 7);
      expect(o.step, BillingOrderStep.choose);
      expect(o.isPayable, isTrue);
      expect(o.planName, 'Medium');
      expect(o.months, 12);
      expect(o.amount, 490000);
      expect(o.details, isNull);
      expect(o.webPayUrl, contains('/billing/orders/7'));
    });

    test('details per metode: va, bill, qris', () {
      BillingPayDetails parse(Map<String, dynamic> d) => BillingOrderModel.fromMap(
        _order(state: 'instructions', details: d, method: 'x'),
      ).details!;

      final va = parse({'type': 'va', 'bank': 'BCA', 'number': '1234567890123'});
      expect(va.type, BillingDetailsType.va);
      expect(va.bank, 'BCA');
      expect(va.number, '1234567890123');

      final bill = parse({'type': 'bill', 'biller_code': '70012', 'bill_key': '99'});
      expect(bill.type, BillingDetailsType.bill);
      expect(bill.billerCode, '70012');
      expect(bill.billKey, '99');

      final qris = parse({'type': 'qris', 'qr_string': '0002...', 'qr_url': 'https://q/x.png'});
      expect(qris.type, BillingDetailsType.qris);
      expect(qris.qrString, '0002...');
      expect(qris.qrUrl, 'https://q/x.png');

      expect(parse({'type': 'aneh'}).type, BillingDetailsType.unknown);
    });

    test('tanpa id -> FormatException', () {
      expect(
        () => BillingOrderModel.fromMap({'number': 'x'}),
        throwsFormatException,
      );
    });

    test('state tak dikenal + pending -> ditebak dari status (choose, payable)', () {
      final o = BillingOrderModel.fromMap(_order(state: 'baru'));
      expect(o.step, BillingOrderStep.choose);
      expect(o.isPayable, isTrue);
    });

    test('applyStatus lunas: step paid, details dibuang, paidAt terisi', () {
      final o = BillingOrderModel.fromMap(
        _order(
          state: 'instructions',
          method: 'bca_va',
          details: {'type': 'va', 'bank': 'BCA', 'number': '1'},
        ),
      );
      final s = BillingStatusModel.fromMap({
        'status': 'paid',
        'paid': true,
        'expired': false,
        'state': 'paid',
      });
      final next = o.applyStatus(s, now: DateTime(2026, 11, 9));
      expect(next.isPaid, isTrue);
      expect(next.status, 'paid');
      expect(next.details, isNull);
      expect(next.paidAt, DateTime(2026, 11, 9));
      expect(next.id, o.id);
      expect(next.amount, o.amount);
    });

    test('applyStatus lewat batas waktu: kembali ke choose + timedOut', () {
      final o = BillingOrderModel.fromMap(
        _order(
          state: 'instructions',
          method: 'bca_va',
          details: {'type': 'va', 'bank': 'BCA', 'number': '1'},
        ),
      );
      final s = BillingStatusModel.fromMap({
        'status': 'pending',
        'paid': false,
        'expired': true,
        'state': 'choose',
      });
      final next = o.applyStatus(s);
      expect(next.step, BillingOrderStep.choose);
      expect(next.timedOut, isTrue);
      expect(next.details, isNull);
    });
  });

  group('BillingStatusModel', () {
    test('pending', () {
      final s = BillingStatusModel.fromJson(
        jsonEncode({
          'data': {
            'status': 'pending',
            'paid': false,
            'expired': false,
            'state': 'instructions',
          },
        }),
      );
      expect(s.paid, isFalse);
      expect(s.step, BillingOrderStep.instructions);
      expect(s.tenant, isNull);
    });

    test('lunas membawa tenantSummary terbaru', () {
      final s = BillingStatusModel.fromJson(
        jsonEncode({
          'data': {
            'status': 'paid',
            'paid': true,
            'expired': false,
            'state': 'paid',
            'tenant': {
              'id': 1,
              'name': 'Kopi Kita',
              'slug': 'kopikita',
              'status': 'draft',
              'plan': {
                'code': 'medium',
                'name': 'Medium',
                'level': 2,
                'expires_at': '2027-11-09T00:00:00+00:00',
                'expires_in_days': 365,
              },
            },
          },
        }),
      );
      expect(s.paid, isTrue);
      expect(s.step, BillingOrderStep.paid);
      expect(s.tenant?.slug, 'kopikita');
      expect(s.tenant?.plan?.code, 'medium');
      expect(s.tenant?.plan?.expiresAt, isNotNull);
    });

    test('paid true selalu menjadi step paid walau state hilang', () {
      final s = BillingStatusModel.fromMap({'status': 'paid', 'paid': true});
      expect(s.step, BillingOrderStep.paid);
    });
  });

  group('BillingOrdersPageModel', () {
    test('data + meta', () {
      final p = BillingOrdersPageModel.fromJson(
        jsonEncode({
          'data': [_order(), _order(state: 'paid', status: 'paid')],
          'meta': {'page': 1, 'last_page': 3, 'total': 45},
        }),
      );
      expect(p.orders, hasLength(2));
      expect(p.orders.last.isPaid, isTrue);
      expect(p.page, 1);
      expect(p.lastPage, 3);
      expect(p.total, 45);
      expect(p.hasMore, isTrue);
    });

    test('tanpa meta: satu halaman', () {
      final p = BillingOrdersPageModel.fromJson(jsonEncode({'data': []}));
      expect(p.hasMore, isFalse);
      expect(p.orders, isEmpty);
    });

    test('data bukan daftar -> FormatException', () {
      expect(
        () => BillingOrdersPageModel.fromJson(jsonEncode({'data': 1})),
        throwsFormatException,
      );
    });
  });
}
