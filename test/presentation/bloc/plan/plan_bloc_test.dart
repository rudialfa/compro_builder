import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/plan_remote_datasource.dart';
import 'package:compro_builder/data/model/response/plan_info_model.dart';
import 'package:compro_builder/presentation/bloc/plan/plan_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements PlanRemoteDatasource {}

const _plan = PlanInfoModel(code: 'medium', name: 'Medium', level: 2);

Matcher _loaded(bool Function(PlanViewData d) test) => predicate<PlanState>(
  (s) => s.maybeWhen(loaded: test, orElse: () => false),
  'loaded yang memenuhi syarat',
);

void main() {
  late MockRemote remote;
  setUp(() => remote = MockRemote());

  PlanBloc build() => PlanBloc(remote, slug: 'toko');

  blocTest<PlanBloc, PlanState>(
    'load sukses',
    setUp: () =>
        when(() => remote.get('toko'))
            .thenAnswer((_) async => const Right(_plan)),
    build: build,
    act: (b) => b.add(const PlanEvent.load()),
    expect: () => [
      isA<PlanState>(),
      _loaded((d) => d.plan.name == 'Medium' && !d.refreshed),
    ],
  );

  blocTest<PlanBloc, PlanState>(
    'refresh announce: data baru + refreshed sesaat, tanpa loading',
    setUp: () =>
        when(() => remote.get('toko'))
            .thenAnswer((_) async => const Right(_plan)),
    build: build,
    seed: () => const PlanState.loaded(PlanViewData(plan: _plan)),
    act: (b) => b.add(const PlanEvent.refresh(announce: true)),
    expect: () => [_loaded((d) => d.refreshed)],
  );

  blocTest<PlanBloc, PlanState>(
    'refresh gagal: data lama tetap + refreshFailure',
    setUp: () =>
        when(() => remote.get('toko'))
            .thenAnswer((_) async => const Left(ApiFailure('offline'))),
    build: build,
    seed: () => const PlanState.loaded(PlanViewData(plan: _plan)),
    act: (b) => b.add(const PlanEvent.refresh()),
    expect: () => [
      _loaded((d) => d.plan.name == 'Medium' && d.refreshFailure != null),
    ],
  );

  blocTest<PlanBloc, PlanState>(
    'load gagal -> error',
    setUp: () => when(() => remote.get('toko'))
        .thenAnswer((_) async => const Left(ApiFailure('x', statusCode: 403))),
    build: build,
    act: (b) => b.add(const PlanEvent.load()),
    expect: () => [
      isA<PlanState>(),
      predicate<PlanState>(
        (s) =>
            s.maybeWhen(error: (f) => f.statusCode == 403, orElse: () => false),
      ),
    ],
  );
}
