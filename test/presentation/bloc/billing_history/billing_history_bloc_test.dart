import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/billing_remote_datasource.dart';
import 'package:compro_builder/data/model/response/billing_response_model.dart';
import 'package:compro_builder/presentation/bloc/billing_history/billing_history_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements BillingRemoteDatasource {}

BillingOrderModel _o(int id) => BillingOrderModel(id: id, number: 'CB-$id');

Matcher _loaded(bool Function(BillingHistoryData d) test) =>
    predicate<BillingHistoryState>(
      (s) => s.maybeWhen(loaded: test, orElse: () => false),
      'loaded yang memenuhi syarat',
    );

void main() {
  late MockRemote remote;
  setUp(() => remote = MockRemote());

  BillingHistoryBloc build() => BillingHistoryBloc(remote, slug: 'toko');

  BillingOrdersPageModel page(List<int> ids, int p, int last) =>
      BillingOrdersPageModel(
        orders: ids.map(_o).toList(),
        page: p,
        lastPage: last,
        total: 30,
      );

  blocTest<BillingHistoryBloc, BillingHistoryState>(
    'load halaman 1',
    setUp: () => when(() => remote.orders('toko', page: 1, perPage: 20))
        .thenAnswer((_) async => Right(page([3, 2, 1], 1, 2))),
    build: build,
    act: (b) => b.add(const BillingHistoryEvent.load()),
    expect: () => [
      isA<BillingHistoryState>(),
      _loaded((d) => d.orders.length == 3 && d.hasMore && d.page == 1),
    ],
  );

  blocTest<BillingHistoryBloc, BillingHistoryState>(
    'load gagal -> error',
    setUp: () => when(() => remote.orders('toko', page: 1, perPage: 20))
        .thenAnswer((_) async => const Left(ApiFailure('x', statusCode: 500))),
    build: build,
    act: (b) => b.add(const BillingHistoryEvent.load()),
    expect: () => [
      isA<BillingHistoryState>(),
      predicate<BillingHistoryState>(
        (s) => s.maybeWhen(error: (f) => f.statusCode == 500, orElse: () => false),
      ),
    ],
  );

  blocTest<BillingHistoryBloc, BillingHistoryState>(
    'loadMore menambah tanpa duplikat dan memperbarui hasMore',
    setUp: () => when(() => remote.orders('toko', page: 2, perPage: 20))
        .thenAnswer((_) async => Right(page([2, 1, 0], 2, 2))),
    build: build,
    seed: () => BillingHistoryState.loaded(
      BillingHistoryData(
        orders: [_o(3), _o(2)],
        page: 1,
        hasMore: true,
        total: 30,
      ),
    ),
    act: (b) => b.add(const BillingHistoryEvent.loadMore()),
    expect: () => [
      _loaded((d) => d.isLoadingMore),
      _loaded(
        (d) =>
            !d.isLoadingMore &&
            d.orders.map((o) => o.id).toList().toString() == '[3, 2, 1, 0]' &&
            !d.hasMore &&
            d.page == 2,
      ),
    ],
  );

  blocTest<BillingHistoryBloc, BillingHistoryState>(
    'loadMore gagal: loadMoreFailure, daftar tetap',
    setUp: () => when(() => remote.orders('toko', page: 2, perPage: 20))
        .thenAnswer((_) async => const Left(ApiFailure('offline'))),
    build: build,
    seed: () => BillingHistoryState.loaded(
      BillingHistoryData(orders: [_o(1)], page: 1, hasMore: true, total: 30),
    ),
    act: (b) => b.add(const BillingHistoryEvent.loadMore()),
    expect: () => [
      _loaded((d) => d.isLoadingMore),
      _loaded((d) => !d.isLoadingMore && d.loadMoreFailure != null && d.orders.length == 1),
    ],
  );

  blocTest<BillingHistoryBloc, BillingHistoryState>(
    'loadMore diabaikan bila tidak ada halaman lagi',
    build: build,
    seed: () => BillingHistoryState.loaded(
      BillingHistoryData(orders: [_o(1)], page: 1, hasMore: false, total: 1),
    ),
    act: (b) => b.add(const BillingHistoryEvent.loadMore()),
    expect: () => <BillingHistoryState>[],
    verify: (_) => verifyNever(
      () => remote.orders(any(), page: any(named: 'page'), perPage: any(named: 'perPage')),
    ),
  );

  blocTest<BillingHistoryBloc, BillingHistoryState>(
    'refresh gagal: daftar lama tetap + refreshFailure',
    setUp: () => when(() => remote.orders('toko', page: 1, perPage: 20))
        .thenAnswer((_) async => const Left(ApiFailure('offline'))),
    build: build,
    seed: () => BillingHistoryState.loaded(
      BillingHistoryData(orders: [_o(1)], page: 1, hasMore: false, total: 1),
    ),
    act: (b) => b.add(const BillingHistoryEvent.refresh()),
    expect: () => [
      _loaded((d) => d.orders.length == 1 && d.refreshFailure != null),
    ],
  );
}
