import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/publish_remote_datasource.dart';
import 'package:compro_builder/data/model/response/site_status_response_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';
import 'package:compro_builder/presentation/bloc/publish/publish_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements PublishRemoteDatasource {}

const _tenant = TenantModel(
  id: 7,
  name: 'Kopi Kita',
  slug: 'toko',
  status: SiteStatus.published,
);

void main() {
  late MockRemote remote;
  setUpAll(() => registerFallbackValue(SiteStatus.draft));
  setUp(() => remote = MockRemote());

  PublishBloc build({SiteStatus status = SiteStatus.draft}) =>
      PublishBloc(remote, slug: 'toko', initialStatus: status);

  blocTest<PublishBloc, PublishState>(
    'tayangkan sukses: isChanging lalu status + notice + updatedTenant',
    setUp: () => when(() => remote.setStatus('toko', SiteStatus.published))
        .thenAnswer((_) async => const Right(
          SiteStatusResponseModel(status: SiteStatus.published, tenant: _tenant),
        )),
    build: build,
    act: (b) => b.add(const PublishEvent.setStatus(SiteStatus.published)),
    expect: () => [
      predicate<PublishState>((s) => s.isChanging && s.status == SiteStatus.draft),
      predicate<PublishState>(
        (s) =>
            !s.isChanging &&
            s.isPublished &&
            s.notice == PublishNotice.published &&
            s.updatedTenant?.slug == 'toko',
      ),
    ],
  );

  blocTest<PublishBloc, PublishState>(
    'balasan tanpa status: memakai status yang diminta',
    setUp: () => when(() => remote.setStatus('toko', SiteStatus.draft))
        .thenAnswer((_) async => const Right(SiteStatusResponseModel())),
    build: () => build(status: SiteStatus.published),
    act: (b) => b.add(const PublishEvent.setStatus(SiteStatus.draft)),
    expect: () => [
      isA<PublishState>(),
      predicate<PublishState>(
        (s) => s.status == SiteStatus.draft && s.notice == PublishNotice.drafted && s.updatedTenant == null,
      ),
    ],
  );

  blocTest<PublishBloc, PublishState>(
    '403 verifikasi email -> block emailUnverified, status tidak berubah',
    setUp: () => when(() => remote.setStatus(any(), any())).thenAnswer(
      (_) async => const Left(ApiFailure(
        'Verifikasi email dulu sebelum menayangkan situs.',
        statusCode: 403,
      )),
    ),
    build: build,
    act: (b) => b.add(const PublishEvent.setStatus(SiteStatus.published)),
    expect: () => [
      isA<PublishState>(),
      predicate<PublishState>(
        (s) =>
            s.block == PublishBlock.emailUnverified &&
            s.failure == null &&
            s.status == SiteStatus.draft &&
            !s.isChanging,
      ),
    ],
  );

  blocTest<PublishBloc, PublishState>(
    '403 dinonaktifkan admin -> block siteDisabled + pesan server',
    setUp: () => when(() => remote.setStatus(any(), any())).thenAnswer(
      (_) async => const Left(
        ApiFailure('Situs ini dinonaktifkan oleh admin.', statusCode: 403),
      ),
    ),
    build: build,
    act: (b) => b.add(const PublishEvent.setStatus(SiteStatus.published)),
    verify: (b) {
      expect(b.state.block, PublishBlock.siteDisabled);
      expect(b.state.blockMessage, 'Situs ini dinonaktifkan oleh admin.');
    },
  );

  blocTest<PublishBloc, PublishState>(
    '403 lain -> block other',
    setUp: () => when(() => remote.setStatus(any(), any())).thenAnswer(
      (_) async => const Left(ApiFailure('Tidak boleh.', statusCode: 403)),
    ),
    build: build,
    act: (b) => b.add(const PublishEvent.setStatus(SiteStatus.published)),
    verify: (b) => expect(b.state.block, PublishBlock.other),
  );

  blocTest<PublishBloc, PublishState>(
    '429 -> failure dengan retryAfter (bukan block)',
    setUp: () => when(() => remote.setStatus(any(), any())).thenAnswer(
      (_) async => const Left(ApiFailure('Terlalu banyak', statusCode: 429, retryAfter: 30)),
    ),
    build: build,
    act: (b) => b.add(const PublishEvent.setStatus(SiteStatus.published)),
    verify: (b) {
      expect(b.state.failure?.retryAfter, 30);
      expect(b.state.block, isNull);
    },
  );

  blocTest<PublishBloc, PublishState>(
    'jaringan gagal -> failure, status lama dipertahankan',
    setUp: () => when(() => remote.setStatus(any(), any()))
        .thenAnswer((_) async => const Left(ApiFailure('offline'))),
    build: () => build(status: SiteStatus.published),
    act: (b) => b.add(const PublishEvent.setStatus(SiteStatus.draft)),
    verify: (b) {
      expect(b.state.failure?.message, 'offline');
      expect(b.state.isPublished, isTrue);
    },
  );

  blocTest<PublishBloc, PublishState>(
    'event kedua saat masih berjalan diabaikan (satu panggilan saja)',
    setUp: () => when(() => remote.setStatus(any(), any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return const Right(SiteStatusResponseModel(status: SiteStatus.published));
    }),
    build: build,
    act: (b) {
      b.add(const PublishEvent.setStatus(SiteStatus.published));
      b.add(const PublishEvent.setStatus(SiteStatus.published));
    },
    wait: const Duration(milliseconds: 60),
    verify: (_) => verify(() => remote.setStatus('toko', SiteStatus.published)).called(1),
  );

  blocTest<PublishBloc, PublishState>(
    'target unknown diabaikan',
    build: build,
    act: (b) => b.add(const PublishEvent.setStatus(SiteStatus.unknown)),
    expect: () => <PublishState>[],
    verify: (_) => verifyNever(() => remote.setStatus(any(), any())),
  );

  blocTest<PublishBloc, PublishState>(
    'dismissed menghapus block dan failure',
    build: build,
    seed: () => const PublishState(
      status: SiteStatus.draft,
      block: PublishBlock.other,
      blockMessage: 'x',
    ),
    act: (b) => b.add(const PublishEvent.dismissed()),
    verify: (b) {
      expect(b.state.block, isNull);
      expect(b.state.status, SiteStatus.draft);
    },
  );

  test('classifyForbidden membedakan penyebab dari pesan server', () {
    PublishBlock c(String m) => classifyForbidden(ApiFailure(m, statusCode: 403));
    expect(c('Situs ini dinonaktifkan oleh admin.'), PublishBlock.siteDisabled);
    expect(c('Situs ini sedang dinonaktifkan.'), PublishBlock.siteDisabled);
    expect(c('Verifikasi email dulu sebelum menayangkan situs.'), PublishBlock.emailUnverified);
    expect(c('Anda tidak memiliki akses.'), PublishBlock.other);
  });
}
