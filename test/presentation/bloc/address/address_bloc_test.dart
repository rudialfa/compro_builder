import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/address_remote_datasource.dart';
import 'package:compro_builder/data/model/response/address_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/presentation/bloc/address/address_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements AddressRemoteDatasource {}

const _ok = SlugCheckModel(
  ok: true,
  status: SlugCheckStatus.available,
  message: 'Alamat ini tersedia.',
  slug: 'toko-baru',
);
const _taken = SlugCheckModel(
  ok: false,
  status: SlugCheckStatus.taken,
  message: 'Alamat ini sudah dipakai orang lain.',
  suggestion: 'toko-2',
  slug: 'toko',
);
const _tenant = TenantModel(id: 1, name: 'Kopi Kita', slug: 'toko-baru');

Matcher _ready(bool Function(AddressViewData d) check) =>
    predicate<AddressState>((s) => s.when(ready: check), 'ready');

AddressState _seed(SlugCheckModel check, String input) => AddressState.ready(
  AddressViewData(input: input, check: check),
);

void main() {
  late MockRemote remote;
  setUp(() => remote = MockRemote());

  // Debounce diperpendek supaya test cepat.
  AddressBloc build() => AddressBloc(
    remote,
    slug: 'kopikita',
    debounceDuration: const Duration(milliseconds: 10),
  );

  const wait = Duration(milliseconds: 80);

  blocTest<AddressBloc, AddressState>(
    'changed: checking lalu hasil cek; server menerima huruf kecil tanpa spasi tepi',
    setUp: () => when(() => remote.check('kopikita', 'toko-baru'))
        .thenAnswer((_) async => const Right(_ok)),
    build: build,
    act: (b) => b.add(const AddressEvent.changed('  Toko-Baru ')),
    wait: wait,
    expect: () => [
      _ready((d) => d.checking && d.check == null),
      _ready(
        (d) =>
            !d.checking && d.check?.ok == true && d.checkMatchesInput && d.canSubmit,
      ),
    ],
  );

  blocTest<AddressBloc, AddressState>(
    'changed kosong: tidak ke server, hasil cek dibuang',
    build: build,
    seed: () => _seed(_ok, 'toko-baru'),
    act: (b) => b.add(const AddressEvent.changed('   ')),
    wait: wait,
    expect: () => [_ready((d) => !d.checking && d.check == null && !d.canSubmit)],
    verify: (_) => verifyNever(() => remote.check(any(), any())),
  );

  blocTest<AddressBloc, AddressState>(
    'changed cepat berturut-turut: hanya isian terakhir yang diperiksa (debounce)',
    setUp: () => when(() => remote.check('kopikita', 'toko'))
        .thenAnswer((_) async => const Right(_taken)),
    build: build,
    act: (b) {
      b
        ..add(const AddressEvent.changed('t'))
        ..add(const AddressEvent.changed('to'))
        ..add(const AddressEvent.changed('toko'));
    },
    wait: wait,
    verify: (_) {
      verify(() => remote.check('kopikita', 'toko')).called(1);
      verifyNever(() => remote.check('kopikita', 't'));
      verifyNever(() => remote.check('kopikita', 'to'));
    },
  );

  blocTest<AddressBloc, AddressState>(
    'dipakai: ok false, suggestion terbawa, tidak bisa submit',
    setUp: () => when(() => remote.check('kopikita', 'toko'))
        .thenAnswer((_) async => const Right(_taken)),
    build: build,
    act: (b) => b.add(const AddressEvent.changed('toko')),
    wait: wait,
    skip: 1,
    expect: () => [
      _ready(
        (d) =>
            !d.canSubmit &&
            d.check?.status == SlugCheckStatus.taken &&
            d.check?.suggestion == 'toko-2',
      ),
    ],
  );

  blocTest<AddressBloc, AddressState>(
    'cek gagal (mis. 429): checkFailure terisi, tidak bisa submit',
    setUp: () => when(() => remote.check('kopikita', 'toko'))
        .thenAnswer((_) async => const Left(ApiFailure('Terlalu banyak.', statusCode: 429))),
    build: build,
    act: (b) => b.add(const AddressEvent.changed('toko')),
    wait: wait,
    skip: 1,
    expect: () => [
      _ready(
        (d) => !d.checking && d.checkFailure?.statusCode == 429 && !d.canSubmit,
      ),
    ],
  );

  blocTest<AddressBloc, AddressState>(
    'submit sukses: isSaving lalu savedTenant dan oldSlug terisi',
    setUp: () => when(() => remote.update('kopikita', 'toko-baru')).thenAnswer(
      (_) async => const Right(
        SlugChangeResponseModel(tenant: _tenant, oldSlug: 'kopikita'),
      ),
    ),
    build: build,
    seed: () => _seed(_ok, 'toko-baru'),
    act: (b) => b.add(const AddressEvent.submit()),
    expect: () => [
      _ready((d) => d.isSaving),
      _ready(
        (d) =>
            !d.isSaving &&
            d.savedTenant?.slug == 'toko-baru' &&
            d.oldSlug == 'kopikita',
      ),
    ],
    verify: (_) =>
        verify(() => remote.update('kopikita', 'toko-baru')).called(1),
  );

  blocTest<AddressBloc, AddressState>(
    'submit gagal 422: saveFailure terisi, isian dan hasil cek dipertahankan',
    setUp: () => when(() => remote.update('kopikita', 'toko-baru')).thenAnswer(
      (_) async => const Left(
        ApiFailure(
          'Alamat ini sudah dipakai orang lain.',
          statusCode: 422,
          fieldErrors: {'slug': ['Alamat ini sudah dipakai orang lain.']},
        ),
      ),
    ),
    build: build,
    seed: () => _seed(_ok, 'toko-baru'),
    act: (b) => b.add(const AddressEvent.submit()),
    expect: () => [
      _ready((d) => d.isSaving),
      _ready(
        (d) =>
            !d.isSaving &&
            d.saveFailure?.errorFor('slug') != null &&
            d.savedTenant == null &&
            d.input == 'toko-baru',
      ),
    ],
  );

  blocTest<AddressBloc, AddressState>(
    'submit tanpa hasil cek "tersedia" diabaikan',
    build: build,
    seed: () => _seed(_taken, 'toko'),
    act: (b) => b.add(const AddressEvent.submit()),
    expect: () => <Object>[],
    verify: (_) => verifyNever(() => remote.update(any(), any())),
  );

  blocTest<AddressBloc, AddressState>(
    'submit saat hasil cek milik isian lain diabaikan',
    build: build,
    seed: () => _seed(_ok, 'isian-lain'),
    act: (b) => b.add(const AddressEvent.submit()),
    expect: () => <Object>[],
    verify: (_) => verifyNever(() => remote.update(any(), any())),
  );
}
