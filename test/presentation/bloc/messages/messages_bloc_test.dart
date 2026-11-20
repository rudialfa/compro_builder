import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/messages_remote_datasource.dart';
import 'package:compro_builder/data/model/response/contact_message_model.dart';
import 'package:compro_builder/presentation/bloc/messages/messages_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements MessagesRemoteDatasource {}

ContactMessageModel _m(int id, {bool read = false}) => ContactMessageModel(
  id: id,
  name: 'N$id',
  email: 'e@x.com',
  message: 'm',
  isRead: read,
);

MessagesPageModel _page(
  List<ContactMessageModel> items, {
  int page = 1,
  int last = 1,
  int? total,
}) => MessagesPageModel(
  items: items,
  page: page,
  lastPage: last,
  total: total ?? items.length,
);

const _fail = ApiFailure('gagal', statusCode: 500);

Matcher _loaded(bool Function(MessagesViewData v) test) =>
    predicate<MessagesState>(
      (s) => s.maybeWhen(loaded: test, orElse: () => false),
      'loaded yang memenuhi syarat',
    );

String _ids(MessagesViewData v) => v.items.map((m) => m.id).join(',');

void main() {
  late MockRemote remote;
  setUp(() => remote = MockRemote());

  MessagesBloc build() => MessagesBloc(remote, slug: 'toko');
  MessagesState seeded(
    List<ContactMessageModel> items, {
    bool hasMore = false,
    int page = 1,
  }) => MessagesState.loaded(
    MessagesViewData(
      items: items,
      page: page,
      hasMore: hasMore,
      total: items.length,
    ),
  );

  group('load / pagination', () {
    blocTest<MessagesBloc, MessagesState>(
      'load sukses',
      setUp: () => when(() => remote.list('toko', page: 1, perPage: 20))
          .thenAnswer((_) async => Right(_page([_m(1)], last: 2, total: 21))),
      build: build,
      act: (b) => b.add(const MessagesEvent.load()),
      expect: () => [
        isA<MessagesState>(),
        _loaded((v) => v.items.length == 1 && v.hasMore && v.total == 21),
      ],
    );

    blocTest<MessagesBloc, MessagesState>(
      '403: error dengan statusCode 403 (UI menampilkan ajakan upgrade)',
      setUp: () => when(
        () => remote.list('toko', page: 1, perPage: 20),
      ).thenAnswer((_) async => const Left(ApiFailure('x', statusCode: 403))),
      build: build,
      act: (b) => b.add(const MessagesEvent.load()),
      expect: () => [
        isA<MessagesState>(),
        predicate<MessagesState>(
          (s) => s.maybeWhen(error: (f) => f.isForbidden, orElse: () => false),
        ),
      ],
    );

    blocTest<MessagesBloc, MessagesState>(
      'loadMore menambah halaman berikutnya tanpa duplikat',
      setUp: () => when(() => remote.list('toko', page: 2, perPage: 20))
          .thenAnswer(
            (_) async =>
                Right(_page([_m(2), _m(3)], page: 2, last: 2, total: 3)),
          ),
      build: build,
      seed: () => seeded([_m(1), _m(2)], hasMore: true),
      act: (b) => b.add(const MessagesEvent.loadMore()),
      expect: () => [
        _loaded((v) => v.isLoadingMore),
        _loaded(
          (v) =>
              !v.isLoadingMore &&
              _ids(v) == '1,2,3' &&
              !v.hasMore &&
              v.page == 2,
        ),
      ],
    );

    blocTest<MessagesBloc, MessagesState>(
      'loadMore gagal: loadMoreFailure bertahan sampai dicoba lagi',
      setUp: () =>
          when(() => remote.list('toko', page: 2, perPage: 20))
              .thenAnswer((_) async => const Left(_fail)),
      build: build,
      seed: () => seeded([_m(1)], hasMore: true),
      act: (b) => b.add(const MessagesEvent.loadMore()),
      expect: () => [
        _loaded((v) => v.isLoadingMore),
        _loaded(
          (v) => !v.isLoadingMore && v.loadMoreFailure != null && v.hasMore,
        ),
      ],
    );

    blocTest<MessagesBloc, MessagesState>(
      'loadMore diabaikan bila tidak ada halaman berikutnya',
      build: build,
      seed: () => seeded([_m(1)]),
      act: (b) => b.add(const MessagesEvent.loadMore()),
      expect: () => <MessagesState>[],
      verify: (_) => verifyNever(
        () => remote.list(
          any(),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ),
    );

    blocTest<MessagesBloc, MessagesState>(
      'refresh gagal: data lama tetap + actionFailure',
      setUp: () =>
          when(() => remote.list('toko', page: 1, perPage: 20))
              .thenAnswer((_) async => const Left(_fail)),
      build: build,
      seed: () => seeded([_m(1)]),
      act: (b) => b.add(const MessagesEvent.refresh()),
      expect: () => [
        _loaded((v) => v.items.length == 1 && v.actionFailure != null),
      ],
    );
  });

  group('toggleRead', () {
    blocTest<MessagesBloc, MessagesState>(
      'optimistic lalu mengikuti nilai server; unreadChanged sesaat',
      setUp: () =>
          when(() => remote.toggleRead('toko', 1))
              .thenAnswer((_) async => const Right(true)),
      build: build,
      seed: () => seeded([_m(1)]),
      act: (b) => b.add(const MessagesEvent.toggleRead(1)),
      expect: () => [
        _loaded((v) => v.items.first.isRead && !v.unreadChanged),
        _loaded((v) => v.items.first.isRead && v.unreadChanged),
      ],
    );

    blocTest<MessagesBloc, MessagesState>(
      'gagal: rollback + actionFailure',
      setUp: () =>
          when(() => remote.toggleRead('toko', 1))
              .thenAnswer((_) async => const Left(_fail)),
      build: build,
      seed: () => seeded([_m(1)]),
      act: (b) => b.add(const MessagesEvent.toggleRead(1)),
      expect: () => [
        _loaded((v) => v.items.first.isRead),
        _loaded((v) => !v.items.first.isRead && v.actionFailure != null),
      ],
    );

    blocTest<MessagesBloc, MessagesState>(
      'onlyIfUnread pada pesan yang sudah dibaca: tidak memanggil server',
      build: build,
      seed: () => seeded([_m(1, read: true)]),
      act: (b) => b.add(const MessagesEvent.toggleRead(1, onlyIfUnread: true)),
      expect: () => <MessagesState>[],
      verify: (_) => verifyNever(() => remote.toggleRead(any(), any())),
    );

    blocTest<MessagesBloc, MessagesState>(
      'server berbeda dari dugaan: ikuti server',
      setUp: () =>
          when(() => remote.toggleRead('toko', 1))
              .thenAnswer((_) async => const Right(false)),
      build: build,
      seed: () => seeded([_m(1)]),
      act: (b) => b.add(const MessagesEvent.toggleRead(1)),
      expect: () => [
        _loaded((v) => v.items.first.isRead),
        _loaded((v) => !v.items.first.isRead && v.unreadChanged),
      ],
    );
  });

  group('delete', () {
    blocTest<MessagesBloc, MessagesState>(
      'optimistic: hapus + total turun, lalu notice deleted',
      setUp: () =>
          when(() => remote.delete('toko', 1))
              .thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => seeded([_m(1), _m(2)]),
      act: (b) => b.add(const MessagesEvent.delete(1)),
      expect: () => [
        _loaded((v) => _ids(v) == '2' && v.total == 1),
        _loaded((v) => v.notice == MessagesNotice.deleted && v.unreadChanged),
      ],
    );

    blocTest<MessagesBloc, MessagesState>(
      'gagal: pesan kembali ke posisi semula + actionFailure',
      setUp: () =>
          when(() => remote.delete('toko', 1))
              .thenAnswer((_) async => const Left(_fail)),
      build: build,
      seed: () => seeded([_m(1), _m(2)]),
      act: (b) => b.add(const MessagesEvent.delete(1)),
      expect: () => [
        _loaded((v) => _ids(v) == '2'),
        _loaded(
          (v) => _ids(v) == '1,2' && v.total == 2 && v.actionFailure != null,
        ),
      ],
    );
  });
}
