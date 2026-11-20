import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/billing_remote_datasource.dart';
import 'package:compro_builder/data/model/response/billing_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/presentation/bloc/billing_pay/billing_pay_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements BillingRemoteDatasource {}

const _choose = BillingOrderModel(
  id: 7,
  number: 'CB-1',
  step: BillingOrderStep.choose,
  months: 12,
  amount: 490000,
  planCode: 'medium',
  planName: 'Medium',
);

const _waiting = BillingOrderModel(
  id: 7,
  number: 'CB-1',
  step: BillingOrderStep.instructions,
  months: 12,
  amount: 490000,
  planCode: 'medium',
  planName: 'Medium',
  method: 'bca_va',
  methodLabel: 'BCA Virtual Account',
  details: BillingPayDetails(
    type: BillingDetailsType.va,
    bank: 'BCA',
    number: '123',
  ),
);

BillingPayBloc _bloc(MockRemote r, BillingOrderModel o) =>
    BillingPayBloc(r, slug: 'toko', order: o);

Matcher _ready(bool Function(BillingPayData d) test) =>
    predicate<BillingPayState>(
      (s) => s.when(ready: test),
      'ready yang memenuhi syarat',
    );

void main() {
  late MockRemote remote;
  setUp(() => remote = MockRemote());

  test('state awal = order yang diberikan', () {
    final b = _bloc(remote, _choose);
    expect(b.state.when(ready: (d) => d.order.id), 7);
    b.close();
  });

  blocTest<BillingPayBloc, BillingPayState>(
    'charge sukses: isCharging lalu order instructions + details',
    setUp: () => when(() => remote.charge('toko', 7, 'bca_va'))
        .thenAnswer((_) async => const Right(_waiting)),
    build: () => _bloc(remote, _choose),
    act: (b) => b.add(const BillingPayEvent.charge('bca_va')),
    expect: () => [
      _ready((d) => d.isCharging),
      _ready(
        (d) =>
            !d.isCharging &&
            d.order.step == BillingOrderStep.instructions &&
            d.order.details?.number == '123',
      ),
    ],
  );

  blocTest<BillingPayBloc, BillingPayState>(
    'charge ditolak (422): chargeFailure, lalu sinkron status ke choose',
    setUp: () {
      when(() => remote.charge('toko', 7, 'bca_va')).thenAnswer(
        (_) async => const Left(ApiFailure('Ditolak gateway.', statusCode: 422)),
      );
      // Server membatalkan tagihan lama sebelum memanggil gateway.
      when(() => remote.status('toko', 7)).thenAnswer(
        (_) async => const Right(
          BillingStatusModel(status: 'pending', step: BillingOrderStep.choose),
        ),
      );
    },
    build: () => _bloc(remote, _waiting),
    act: (b) => b.add(const BillingPayEvent.charge('bca_va')),
    expect: () => [
      _ready((d) => d.isCharging),
      _ready((d) => !d.isCharging && d.chargeFailure?.message == 'Ditolak gateway.'),
      _ready(
        (d) =>
            d.order.step == BillingOrderStep.choose &&
            d.order.details == null &&
            d.chargeFailure == null,
      ),
    ],
  );

  blocTest<BillingPayBloc, BillingPayState>(
    'charge diabaikan bila order sudah lunas',
    build: () => _bloc(remote, _waiting.applyStatus(
      const BillingStatusModel(status: 'paid', paid: true, step: BillingOrderStep.paid),
    )),
    act: (b) => b.add(const BillingPayEvent.charge('bca_va')),
    expect: () => <BillingPayState>[],
    verify: (_) => verifyNever(() => remote.charge(any(), any(), any())),
  );

  blocTest<BillingPayBloc, BillingPayState>(
    'poll lunas: order paid + paidNow + tenant terbaru (satu emisi)',
    setUp: () => when(() => remote.status('toko', 7)).thenAnswer(
      (_) async => const Right(
        BillingStatusModel(
          status: 'paid',
          paid: true,
          step: BillingOrderStep.paid,
          tenant: TenantModel(
            id: 1,
            name: 'Toko',
            slug: 'toko',
            plan: PlanSummaryModel(code: 'medium', name: 'Medium', level: 2),
          ),
        ),
      ),
    ),
    build: () => _bloc(remote, _waiting),
    act: (b) => b.add(const BillingPayEvent.poll()),
    expect: () => [
      _ready(
        (d) =>
            d.order.isPaid &&
            d.order.paidAt != null &&
            d.order.details == null &&
            d.paidNow &&
            d.paidTenant?.plan?.code == 'medium',
      ),
    ],
  );

  blocTest<BillingPayBloc, BillingPayState>(
    'poll masih pending: tidak ada emisi',
    setUp: () => when(() => remote.status('toko', 7)).thenAnswer(
      (_) async => const Right(
        BillingStatusModel(status: 'pending', step: BillingOrderStep.instructions),
      ),
    ),
    build: () => _bloc(remote, _waiting),
    act: (b) => b.add(const BillingPayEvent.poll()),
    expect: () => <BillingPayState>[],
  );

  blocTest<BillingPayBloc, BillingPayState>(
    'poll: batas waktu lewat -> choose + timedOut, details dibuang',
    setUp: () => when(() => remote.status('toko', 7)).thenAnswer(
      (_) async => const Right(
        BillingStatusModel(
          status: 'pending',
          expired: true,
          step: BillingOrderStep.choose,
        ),
      ),
    ),
    build: () => _bloc(remote, _waiting),
    act: (b) => b.add(const BillingPayEvent.poll()),
    expect: () => [
      _ready(
        (d) =>
            d.order.step == BillingOrderStep.choose &&
            d.order.timedOut &&
            d.order.details == null &&
            !d.paidNow,
      ),
    ],
  );

  blocTest<BillingPayBloc, BillingPayState>(
    'poll gagal (jaringan): diam, tidak ada emisi',
    setUp: () => when(() => remote.status('toko', 7))
        .thenAnswer((_) async => const Left(ApiFailure('offline'))),
    build: () => _bloc(remote, _waiting),
    act: (b) => b.add(const BillingPayEvent.poll()),
    expect: () => <BillingPayState>[],
  );

  blocTest<BillingPayBloc, BillingPayState>(
    'poll beruntun: hanya satu pemanggilan jaringan yang berjalan',
    setUp: () => when(() => remote.status('toko', 7)).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return const Right(
        BillingStatusModel(status: 'pending', step: BillingOrderStep.instructions),
      );
    }),
    build: () => _bloc(remote, _waiting),
    act: (b) {
      b.add(const BillingPayEvent.poll());
      b.add(const BillingPayEvent.poll());
      b.add(const BillingPayEvent.poll());
    },
    wait: const Duration(milliseconds: 100),
    expect: () => <BillingPayState>[],
    verify: (_) => verify(() => remote.status('toko', 7)).called(1),
  );

  blocTest<BillingPayBloc, BillingPayState>(
    'poll diabaikan saat order sudah lunas',
    build: () => _bloc(remote, _waiting.applyStatus(
      const BillingStatusModel(status: 'paid', paid: true, step: BillingOrderStep.paid),
    )),
    act: (b) => b.add(const BillingPayEvent.poll()),
    expect: () => <BillingPayState>[],
    verify: (_) => verifyNever(() => remote.status(any(), any())),
  );
}
