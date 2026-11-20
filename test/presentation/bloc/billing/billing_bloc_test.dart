import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/billing_remote_datasource.dart';
import 'package:compro_builder/data/model/response/billing_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/presentation/bloc/billing/billing_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements BillingRemoteDatasource {}

const _overview = BillingOverviewModel(
  current: PlanSummaryModel(code: 'standar', name: 'Standar', level: 1),
  emailVerified: true,
  inAppPayment: true,
);

const _order = BillingOrderModel(
  id: 7,
  number: 'CB-1',
  step: BillingOrderStep.choose,
  months: 12,
  amount: 490000,
  planCode: 'medium',
  planName: 'Medium',
);

Matcher _loaded(bool Function(BillingViewData d) test) =>
    predicate<BillingState>(
      (s) => s.maybeWhen(loaded: test, orElse: () => false),
      'loaded yang memenuhi syarat',
    );

void main() {
  late MockRemote remote;
  setUp(() => remote = MockRemote());

  BillingBloc build() => BillingBloc(remote, slug: 'toko');

  blocTest<BillingBloc, BillingState>(
    'load sukses: loading lalu loaded',
    setUp: () => when(() => remote.overview('toko'))
        .thenAnswer((_) async => const Right(_overview)),
    build: build,
    act: (b) => b.add(const BillingEvent.load()),
    expect: () => [
      isA<BillingState>(),
      _loaded((d) => d.overview.current.code == 'standar' && !d.isCheckingOut),
    ],
  );

  blocTest<BillingBloc, BillingState>(
    'load gagal -> error',
    setUp: () => when(() => remote.overview('toko')).thenAnswer(
      (_) async => const Left(ApiFailure('x', statusCode: 403)),
    ),
    build: build,
    act: (b) => b.add(const BillingEvent.load()),
    expect: () => [
      isA<BillingState>(),
      predicate<BillingState>(
        (s) => s.maybeWhen(error: (f) => f.statusCode == 403, orElse: () => false),
      ),
    ],
  );

  blocTest<BillingBloc, BillingState>(
    'refresh gagal: data lama tetap + refreshFailure, tanpa loading',
    setUp: () => when(() => remote.overview('toko'))
        .thenAnswer((_) async => const Left(ApiFailure('offline'))),
    build: build,
    seed: () => const BillingState.loaded(BillingViewData(overview: _overview)),
    act: (b) => b.add(const BillingEvent.refresh()),
    expect: () => [
      _loaded((d) => d.overview.current.name == 'Standar' && d.refreshFailure != null),
    ],
  );

  blocTest<BillingBloc, BillingState>(
    'checkout sukses: isCheckingOut lalu createdOrder (satu emisi)',
    setUp: () => when(
      () => remote.checkout('toko', plan: 'medium', months: 12),
    ).thenAnswer((_) async => const Right(_order)),
    build: build,
    seed: () => const BillingState.loaded(BillingViewData(overview: _overview)),
    act: (b) => b.add(const BillingEvent.checkout(plan: 'medium', months: 12)),
    expect: () => [
      _loaded((d) => d.isCheckingOut && d.createdOrder == null),
      _loaded((d) => !d.isCheckingOut && d.createdOrder?.id == 7),
    ],
    verify: (_) => verify(
      () => remote.checkout('toko', plan: 'medium', months: 12),
    ).called(1),
  );

  blocTest<BillingBloc, BillingState>(
    'checkout 403 email_unverified: checkoutFailure, tanpa order',
    setUp: () => when(
      () => remote.checkout('toko', plan: 'medium', months: 1),
    ).thenAnswer(
      (_) async => const Left(
        ApiFailure('Verifikasi email.', statusCode: 403, code: 'email_unverified'),
      ),
    ),
    build: build,
    seed: () => const BillingState.loaded(BillingViewData(overview: _overview)),
    act: (b) => b.add(const BillingEvent.checkout(plan: 'medium', months: 1)),
    expect: () => [
      _loaded((d) => d.isCheckingOut),
      _loaded(
        (d) =>
            !d.isCheckingOut &&
            d.createdOrder == null &&
            d.checkoutFailure?.isEmailUnverified == true,
      ),
    ],
  );

  blocTest<BillingBloc, BillingState>(
    'checkout ditolak bila belum termuat',
    build: build,
    act: (b) => b.add(const BillingEvent.checkout(plan: 'medium', months: 1)),
    expect: () => <BillingState>[],
    verify: (_) => verifyNever(
      () => remote.checkout(any(), plan: any(named: 'plan'), months: any(named: 'months')),
    ),
  );

  blocTest<BillingBloc, BillingState>(
    'refresh diabaikan saat order sedang dibuat',
    build: build,
    seed: () => const BillingState.loaded(
      BillingViewData(overview: _overview, isCheckingOut: true),
    ),
    act: (b) => b.add(const BillingEvent.refresh()),
    expect: () => <BillingState>[],
    verify: (_) => verifyNever(() => remote.overview(any())),
  );
}
