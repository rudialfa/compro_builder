import 'package:compro_builder/data/model/response/billing_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _order({Object? state, String status = 'pending'}) => {
  'id': 1,
  'number': 'CB-1',
  'status': status,
  if (state != null) 'state': state,
  'months': 1,
  'amount': 49000,
  'plan': {'code': 'medium', 'name': 'Medium', 'level': 2},
};

void main() {
  test('tanpa state + pending -> choose (bukan tagihan tidak aktif)', () {
    final o = BillingOrderModel.fromMap(_order());
    expect(o.step, BillingOrderStep.choose);
    expect(o.isPayable, isTrue);
  });

  test('tanpa state + paid -> paid; failed -> closed', () {
    expect(BillingOrderModel.fromMap(_order(status: 'paid')).step, BillingOrderStep.paid);
    expect(BillingOrderModel.fromMap(_order(status: 'failed')).step, BillingOrderStep.closed);
  });

  test('state aneh + pending -> choose; state aneh + failed -> closed', () {
    expect(BillingOrderModel.fromMap(_order(state: 'baru')).step, BillingOrderStep.choose);
    expect(BillingOrderModel.fromMap(_order(state: 'baru', status: 'failed')).step, BillingOrderStep.closed);
  });

  test('state closed eksplisit dari server tetap dipercaya', () {
    expect(BillingOrderModel.fromMap(_order(state: 'closed')).step, BillingOrderStep.closed);
  });

  test('polling tanpa state tidak menutup order yang masih pending', () {
    final o = BillingOrderModel.fromMap(_order(state: 'choose'));
    final next = o.applyStatus(const BillingStatusModel(status: 'pending'));
    expect(next.step, BillingOrderStep.choose);
    expect(next.isPayable, isTrue);
  });

  test('polling tanpa state + status failed -> closed', () {
    final o = BillingOrderModel.fromMap(_order(state: 'choose'));
    expect(o.applyStatus(const BillingStatusModel(status: 'failed')).step, BillingOrderStep.closed);
  });
}
