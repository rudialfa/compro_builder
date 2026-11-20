import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/checklist_remote_datasource.dart';
import 'package:compro_builder/data/model/response/checklist_response_model.dart';
import 'package:compro_builder/presentation/bloc/checklist/checklist_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements ChecklistRemoteDatasource {}

const _report = ChecklistResponseModel(percent: 60, total: 5);
const _report2 = ChecklistResponseModel(percent: 80, total: 5);
const _fail = ApiFailure('Gagal memuat kelengkapan situs.', statusCode: 500);

Matcher _loaded(bool Function(ChecklistViewData v) check) =>
    predicate<ChecklistState>(
      (s) => s.maybeWhen(loaded: check, orElse: () => false),
      'loaded',
    );

void main() {
  late MockRemote remote;
  setUp(() => remote = MockRemote());

  ChecklistBloc build() => ChecklistBloc(remote, slug: 'toko');

  blocTest<ChecklistBloc, ChecklistState>(
    'load sukses: loading lalu loaded',
    setUp: () => when(() => remote.get('toko'))
        .thenAnswer((_) async => const Right(_report)),
    build: build,
    act: (b) => b.add(const ChecklistEvent.load()),
    expect: () => [
      predicate<ChecklistState>(
        (s) => s.maybeWhen(loading: () => true, orElse: () => false),
      ),
      _loaded((v) => v.data.percent == 60 && v.refreshFailure == null),
    ],
  );

  blocTest<ChecklistBloc, ChecklistState>(
    'load gagal: loading lalu error',
    setUp: () => when(() => remote.get('toko'))
        .thenAnswer((_) async => const Left(_fail)),
    build: build,
    act: (b) => b.add(const ChecklistEvent.load()),
    expect: () => [
      isA<ChecklistState>(),
      predicate<ChecklistState>(
        (s) => s.maybeWhen(
          error: (f) => f.statusCode == 500,
          orElse: () => false,
        ),
      ),
    ],
  );

  blocTest<ChecklistBloc, ChecklistState>(
    'refresh sesudah loaded: data lama dipertahankan saat gagal',
    setUp: () {
      var call = 0;
      when(() => remote.get('toko')).thenAnswer(
        (_) async => call++ == 0 ? const Right(_report) : const Left(_fail),
      );
    },
    build: build,
    act: (b) async {
      b.add(const ChecklistEvent.load());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      b.add(const ChecklistEvent.refresh());
    },
    expect: () => [
      isA<ChecklistState>(), // loading
      _loaded((v) => v.data.percent == 60),
      _loaded((v) => v.data.percent == 60 && v.refreshFailure != null),
    ],
  );

  blocTest<ChecklistBloc, ChecklistState>(
    'refresh sukses: data diganti tanpa loading',
    setUp: () {
      var call = 0;
      when(() => remote.get('toko')).thenAnswer(
        (_) async => call++ == 0 ? const Right(_report) : const Right(_report2),
      );
    },
    build: build,
    act: (b) async {
      b.add(const ChecklistEvent.load());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      b.add(const ChecklistEvent.refresh());
    },
    expect: () => [
      isA<ChecklistState>(), // loading
      _loaded((v) => v.data.percent == 60),
      _loaded((v) => v.data.percent == 80),
    ],
  );

  blocTest<ChecklistBloc, ChecklistState>(
    'refresh tanpa data sebelumnya: loading lalu loaded',
    setUp: () => when(() => remote.get('toko'))
        .thenAnswer((_) async => const Right(_report)),
    build: build,
    act: (b) => b.add(const ChecklistEvent.refresh()),
    expect: () => [
      predicate<ChecklistState>(
        (s) => s.maybeWhen(loading: () => true, orElse: () => false),
      ),
      _loaded((v) => v.data.percent == 60),
    ],
  );

  test('respons basi ditolak bila muat ulang yang lebih baru sudah dimulai', () async {
    final first = Completer<Either<ApiFailure, ChecklistResponseModel>>();
    var call = 0;
    when(() => remote.get('toko')).thenAnswer(
      (_) => call++ == 0 ? first.future : Future.value(const Right(_report2)),
    );

    final bloc = build();
    bloc.add(const ChecklistEvent.load()); // menggantung
    await Future<void>.delayed(Duration.zero);
    bloc.add(const ChecklistEvent.refresh()); // lebih baru, selesai duluan
    await Future<void>.delayed(const Duration(milliseconds: 10));
    first.complete(const Right(_report)); // basi: tidak boleh menimpa
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(bloc.state.maybeWhen(loaded: (v) => v.data.percent, orElse: () => -1), 80);
    await bloc.close();
  });
}
