import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/data/datasources/sections_remote_datasource.dart';
import 'package:compro_builder/data/model/response/section_model.dart';
import 'package:compro_builder/presentation/bloc/section_editor/section_editor_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements SectionsRemoteDatasource {}

const _listCopy = SectionModel(id: 1, type: 'about', name: 'Dari daftar');
const _server = SectionModel(id: 1, type: 'about', name: 'Dari server');

Matcher _loaded(bool Function(SectionEditorData d) test) =>
    predicate<SectionEditorState>(
      (s) => s.maybeWhen(loaded: test, orElse: () => false),
      'loaded yang memenuhi syarat',
    );

final _loading = predicate<SectionEditorState>(
  (s) => s.maybeWhen(loading: () => true, orElse: () => false),
  'loading',
);

void main() {
  late MockRemote remote;

  setUp(() => remote = MockRemote());

  SectionEditorBloc build({SectionModel? initial = _listCopy}) =>
      SectionEditorBloc(remote, slug: 'toko', sectionId: 1, initial: initial);

  SectionEditorState seeded() =>
      const SectionEditorState.loaded(SectionEditorData(section: _server));

  group('load', () {
    blocTest<SectionEditorBloc, SectionEditorState>(
      'sukses: memakai detail server',
      setUp: () =>
          when(() => remote.detail('toko', 1))
              .thenAnswer((_) async => const Right(_server)),
      build: build,
      act: (b) => b.add(const SectionEditorEvent.load()),
      expect: () => [
        _loading,
        _loaded((d) => d.section.name == 'Dari server' && !d.fromList),
      ],
    );

    blocTest<SectionEditorBloc, SectionEditorState>(
      'offline: jatuh ke salinan dari daftar',
      setUp: () =>
          when(() => remote.detail('toko', 1))
              .thenAnswer((_) async => const Left(ApiFailure('offline'))),
      build: build,
      act: (b) => b.add(const SectionEditorEvent.load()),
      expect: () => [
        _loading,
        _loaded((d) => d.section.name == 'Dari daftar' && d.fromList),
      ],
    );

    blocTest<SectionEditorBloc, SectionEditorState>(
      '403 (terkunci): error, tidak memakai salinan daftar',
      setUp: () => when(() => remote.detail('toko', 1)).thenAnswer(
        (_) async => const Left(ApiFailure('terkunci', statusCode: 403)),
      ),
      build: build,
      act: (b) => b.add(const SectionEditorEvent.load()),
      expect: () => [
        _loading,
        predicate<SectionEditorState>(
          (s) => s.maybeWhen(
            error: (f) => f.statusCode == 403,
            orElse: () => false,
          ),
        ),
      ],
    );
  });

  group('save', () {
    blocTest<SectionEditorBloc, SectionEditorState>(
      'sukses: isSaving lalu savedSection terisi',
      setUp: () =>
          when(() => remote.update('toko', 1, any()))
              .thenAnswer((_) async => const Right(_server)),
      build: build,
      seed: seeded,
      act: (b) =>
          b.add(SectionEditorEvent.save((fetch) async => {'title': 'x'})),
      expect: () => [
        _loaded((d) => d.isSaving),
        _loaded((d) => !d.isSaving && d.savedSection != null),
      ],
      verify: (_) =>
          verify(() => remote.update('toko', 1, {'title': 'x'})).called(1),
    );

    blocTest<SectionEditorBloc, SectionEditorState>(
      '422: saveFailure membawa fieldErrors',
      setUp: () => when(() => remote.update('toko', 1, any())).thenAnswer(
        (_) async => const Left(
          ApiFailure(
            'x',
            statusCode: 422,
            fieldErrors: {
              'title': ['Wajib'],
            },
          ),
        ),
      ),
      build: build,
      seed: seeded,
      act: (b) => b.add(SectionEditorEvent.save((fetch) async => {})),
      expect: () => [
        _loaded((d) => d.isSaving),
        _loaded(
          (d) =>
              !d.isSaving &&
              d.saveFailure?.errorFor('title') == 'Wajib' &&
              d.savedSection == null,
        ),
      ],
    );

    blocTest<SectionEditorBloc, SectionEditorState>(
      'gagal mengunduh gambar lama: update tidak dipanggil',
      setUp: () => when(() => remote.downloadBytes(any())).thenAnswer(
        (_) async => const Left(ApiFailure('Gagal mengunduh gambar.')),
      ),
      build: build,
      seed: seeded,
      act: (b) => b.add(
        SectionEditorEvent.save((fetch) async {
          await fetch('/storage/a.jpg');
          return {};
        }),
      ),
      expect: () => [
        _loaded((d) => d.isSaving),
        _loaded(
          (d) =>
              !d.isSaving &&
              d.saveFailure?.message == 'Gagal mengunduh gambar.',
        ),
      ],
      verify: (_) => verifyNever(() => remote.update(any(), any(), any())),
    );

    blocTest<SectionEditorBloc, SectionEditorState>(
      'gambar lama diunduh lalu dikirim ke update',
      setUp: () {
        when(() => remote.downloadBytes('/storage/a.jpg'))
            .thenAnswer((_) async => Right(Uint8List.fromList([1])));
        when(() => remote.update('toko', 1, any()))
            .thenAnswer((_) async => const Right(_server));
      },
      build: build,
      seed: seeded,
      act: (b) => b.add(
        SectionEditorEvent.save((fetch) async {
          final bytes = await fetch('/storage/a.jpg');
          return {'len': bytes.length};
        }),
      ),
      expect: () => [
        _loaded((d) => d.isSaving),
        _loaded((d) => d.savedSection != null),
      ],
      verify: (_) =>
          verify(() => remote.update('toko', 1, {'len': 1})).called(1),
    );

    blocTest<SectionEditorBloc, SectionEditorState>(
      'builder payload melempar: saveFailure, update tidak dipanggil',
      build: build,
      seed: seeded,
      act: (b) => b.add(
        SectionEditorEvent.save((fetch) async => throw StateError('x')),
      ),
      expect: () => [
        _loaded((d) => d.isSaving),
        _loaded((d) => !d.isSaving && d.saveFailure != null),
      ],
      verify: (_) => verifyNever(() => remote.update(any(), any(), any())),
    );
  });
}
