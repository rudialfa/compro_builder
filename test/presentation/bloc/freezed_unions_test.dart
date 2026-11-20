import 'package:compro_builder/core/helper/api_failure.dart';
import 'package:compro_builder/presentation/auth/bloc/login/login_bloc.dart';
import 'package:compro_builder/presentation/bloc/messages/messages_bloc.dart';
import 'package:compro_builder/presentation/bloc/sections/sections_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pengaman Fase 2B: memastikan union hasil freezed tetap berperilaku seperti
/// versi tulisan tangan (when/maybeWhen/whenOrNull, nilai default parameter).
void main() {
  group('State hasil freezed', () {
    const failure = ApiFailure('gagal');

    test('when memilih cabang yang tepat', () {
      String label(LoginState s) => s.when(
        initial: () => 'initial',
        loading: () => 'loading',
        success: (_) => 'success',
        error: (f) => 'error:${f.message}',
      );

      expect(label(const LoginState.initial()), 'initial');
      expect(label(const LoginState.loading()), 'loading');
      expect(label(const LoginState.error(failure)), 'error:gagal');
    });

    test('maybeWhen jatuh ke orElse untuk cabang yang tidak diberikan', () {
      const s = LoginState.loading();
      expect(
        s.maybeWhen(error: (_) => 'error', orElse: () => 'lainnya'),
        'lainnya',
      );
    });

    test('whenOrNull mengembalikan null untuk cabang yang tidak diberikan', () {
      const s = LoginState.initial();
      expect(s.whenOrNull(loading: () => 1), isNull);
      expect(const LoginState.loading().whenOrNull(loading: () => 1), 1);
    });

    test('kesamaan nilai: state tanpa data sama, state dengan data beda instance', () {
      expect(const LoginState.loading(), const LoginState.loading());
      expect(const LoginState.error(failure), const LoginState.error(failure));
      expect(const LoginState.loading() == const LoginState.initial(), isFalse);
    });
  });

  group('Event hasil freezed', () {
    test('toggleRead: onlyIfUnread default false', () {
      const dynamic e = MessagesEvent.toggleRead(7);
      expect(e.id, 7);
      expect(e.onlyIfUnread, isFalse);

      const dynamic f = MessagesEvent.toggleRead(7, onlyIfUnread: true);
      expect(f.onlyIfUnread, isTrue);
    });

    test('move: parameter up wajib dan terbaca', () {
      const dynamic e = SectionsEvent.move(3, up: true);
      expect(e.id, 3);
      expect(e.up, isTrue);
    });
  });
}
