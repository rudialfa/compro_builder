import 'dart:async';

import 'package:compro_builder/core/helper/deep_link_service.dart';
import 'package:compro_builder/core/utils/reset_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tautan saat aplikasi berjalan langsung diteruskan ke onReset',
      () async {
    final controller = StreamController<Uri>();
    final service = DeepLinkService(
      uriStream: controller.stream,
      initialUri: () async => null,
    );
    final got = <ResetLinkInput>[];
    await service.start(onReset: got.add);

    controller.add(Uri.parse('https://situs.id/reset-password/tok1?email=a@b.id'));
    await Future<void>.delayed(Duration.zero);

    expect(got, hasLength(1));
    expect(got.single.token, 'tok1');
    expect(got.single.email, 'a@b.id');
    await service.dispose();
    await controller.close();
  });

  test('tautan yang bukan atur ulang password diabaikan', () async {
    final controller = StreamController<Uri>();
    final service = DeepLinkService(
      uriStream: controller.stream,
      initialUri: () async => null,
    );
    final got = <ResetLinkInput>[];
    await service.start(onReset: got.add);

    controller.add(Uri.parse('https://situs.id/kopi-kita'));
    await Future<void>.delayed(Duration.zero);

    expect(got, isEmpty);
    await service.dispose();
    await controller.close();
  });

  group('cold start', () {
    test('disimpan tertunda dan hanya bisa diambil sekali', () async {
      final service = DeepLinkService(
        uriStream: const Stream<Uri>.empty(),
        initialUri: () async =>
            Uri.parse('comprobuilder://reset-password/cold?email=z@y.id'),
      );
      final got = <ResetLinkInput>[];
      await service.start(onReset: got.add);

      expect(got, isEmpty); // tidak langsung membuka halaman
      final first = service.takePending();
      expect(first?.token, 'cold');
      expect(first?.email, 'z@y.id');
      expect(service.takePending(), isNull);
      await service.dispose();
    });

    test('kedaluwarsa setelah pendingTtl', () async {
      var now = DateTime(2026, 11, 10, 10);
      final service = DeepLinkService(
        uriStream: const Stream<Uri>.empty(),
        initialUri: () async => Uri.parse('https://situs.id/reset-password/old'),
        now: () => now,
        pendingTtl: const Duration(minutes: 2),
      );
      await service.start(onReset: (_) {});

      now = now.add(const Duration(minutes: 3));
      expect(service.takePending(), isNull);
      await service.dispose();
    });
  });
}
