import 'package:compro_builder/data/model/response/contact_message_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _m(int id, {bool read = false}) => {
  'id': id,
  'name': 'Budi $id',
  'email': 'b$id@x.co',
  'phone': '0812-3456-789',
  'message': 'Halo',
  'is_read': read,
  'created_at': '2026-11-07T10:05:00Z',
};

void main() {
  group('MessagesPageModel.fromMap', () {
    test('halaman tengah: hasMore, total, createdAt terparse', () {
      final r = MessagesPageModel.fromMap({
        'data': [_m(1), _m(2)],
        'meta': {'page': 1, 'last_page': 3, 'total': 45},
      });
      expect(r.items.length, 2);
      expect(r.hasMore, isTrue);
      expect(r.total, 45);
      expect(r.items.first.createdAt, isNotNull);
    });

    test('halaman terakhir -> hasMore false', () {
      final r = MessagesPageModel.fromMap({
        'data': [_m(1)],
        'meta': {'page': 3, 'last_page': 3, 'total': 41},
      });
      expect(r.hasMore, isFalse);
    });

    test('tanpa meta -> satu halaman, total = jumlah isi', () {
      final r = MessagesPageModel.fromMap({
        'data': [_m(1), _m(2)],
      });
      expect(r.page, 1);
      expect(r.lastPage, 1);
      expect(r.total, 2);
      expect(r.hasMore, isFalse);
    });

    test('butir tanpa id dilewati, bukan menggagalkan seluruh daftar', () {
      final r = MessagesPageModel.fromMap({
        'data': [
          {'name': 'tanpa id'},
          _m(7),
        ],
      });
      expect(r.items.map((e) => e.id), [7]);
    });

    test('bentuk tak dikenal -> FormatException', () {
      expect(
        () => MessagesPageModel.fromMap({'foo': 1}),
        throwsFormatException,
      );
      expect(() => MessagesPageModel.fromJson('[1]'), throwsFormatException);
    });

    test('toJson -> fromJson bolak-balik', () {
      final r = MessagesPageModel.fromMap({
        'data': [_m(1, read: true), _m(2)],
        'meta': {'page': 2, 'last_page': 4, 'total': 70},
      });
      final back = MessagesPageModel.fromJson(r.toJson());
      expect(back.items.map((e) => e.id), [1, 2]);
      expect(back.items.map((e) => e.isRead), [true, false]);
      expect(back.page, 2);
      expect(back.lastPage, 4);
      expect(back.total, 70);
    });
  });

  group('ContactMessageModel.fromMap', () {
    Map<String, dynamic> base() => {
      'id': 1,
      'name': 'A',
      'email': 'a@b.co',
      'message': 'x',
    };

    test('read_at dipakai bila tak ada read/is_read', () {
      final m = ContactMessageModel.fromMap({
        ...base(),
        'read_at': '2026-11-07T10:00:00Z',
      });
      expect(m.isRead, isTrue);
    });

    test('read bool/angka/string dibaca benar', () {
      expect(
        ContactMessageModel.fromMap({...base(), 'read': true}).isRead,
        isTrue,
      );
      expect(
        ContactMessageModel.fromMap({...base(), 'read': 0}).isRead,
        isFalse,
      );
      expect(
        ContactMessageModel.fromMap({...base(), 'is_read': '1'}).isRead,
        isTrue,
      );
      expect(ContactMessageModel.fromMap(base()).isRead, isFalse);
    });

    test('telepon kosong menjadi null; tanpa id -> FormatException', () {
      expect(
        ContactMessageModel.fromMap({...base(), 'phone': '  '}).phone,
        isNull,
      );
      expect(
        () => ContactMessageModel.fromMap({'name': 'a'}),
        throwsFormatException,
      );
    });

    test('copyWith hanya mengubah status baca', () {
      final m = ContactMessageModel.fromMap(base());
      final c = m.copyWith(isRead: true);
      expect(c.isRead, isTrue);
      expect(c.id, m.id);
      expect(c.message, m.message);
    });
  });
}
