import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/address_remote_datasource.dart';
import 'package:compro_builder/data/model/response/domain_response_model.dart';
import 'package:compro_builder/presentation/bloc/domain/domain_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements AddressRemoteDatasource {}

const _status = DomainStatusModel(allowed: true, featureReady: true, host: 'a.com');
const _fail = ApiFailure('Gagal.', statusCode: 500);

Matcher _loaded(bool Function(DomainViewData d) check) =>
    predicate<DomainState>(
      (s) => s.maybeWhen(loaded: check, orElse: () => false),
      'loaded',
    );

void main() {
  late MockRemote remote;
  setUp(() => remote = MockRemote());

  DomainBloc build() => DomainBloc(remote, slug: 'toko');

  blocTest<DomainBloc, DomainState>(
    'load sukses: loading lalu loaded',
    setUp: () => when(() => remote.domain('toko'))
        .thenAnswer((_) async => const Right(_status)),
    build: build,
    act: (b) => b.add(const DomainEvent.load()),
    expect: () => [
      predicate<DomainState>(
        (s) => s.maybeWhen(loading: () => true, orElse: () => false),
      ),
      _loaded((d) => d.status.host == 'a.com' && d.failure == null),
    ],
  );

  blocTest<DomainBloc, DomainState>(
    'load gagal pertama kali: loading lalu error',
    setUp: () => when(() => remote.domain('toko'))
        .thenAnswer((_) async => const Left(_fail)),
    build: build,
    act: (b) => b.add(const DomainEvent.load()),
    expect: () => [
      isA<DomainState>(),
      predicate<DomainState>(
        (s) => s.maybeWhen(
          error: (f) => f.statusCode == 500,
          orElse: () => false,
        ),
      ),
    ],
  );

  blocTest<DomainBloc, DomainState>(
    'muat ulang gagal: status lama dipertahankan, failure terisi',
    setUp: () => when(() => remote.domain('toko'))
        .thenAnswer((_) async => const Left(_fail)),
    build: build,
    seed: () => const DomainState.loaded(DomainViewData(status: _status)),
    act: (b) => b.add(const DomainEvent.load()),
    expect: () => [
      _loaded((d) => d.status.host == 'a.com' && d.failure?.statusCode == 500),
    ],
  );
}
