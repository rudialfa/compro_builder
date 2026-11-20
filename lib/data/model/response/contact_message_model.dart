import 'dart:convert';

/// Satu pesan dari formulir kontak pengunjung.
class ContactMessageModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  const ContactMessageModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.message,
    this.isRead = false,
    this.createdAt,
  });

  factory ContactMessageModel.fromJson(String str) =>
      ContactMessageModel.fromMap(jsonDecode(str) as Map<String, dynamic>);

  factory ContactMessageModel.fromMap(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is num ? rawId.toInt() : int.tryParse('${rawId ?? ''}');
    if (id == null) throw const FormatException('Pesan tanpa id');
    final read = json['read'] ?? json['is_read'];
    final phone = json['phone']?.toString().trim();
    return ContactMessageModel(
      id: id,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (phone == null || phone.isEmpty) ? null : phone,
      message: (json['message'] ?? '').toString(),
      isRead: switch (read) {
        bool b => b,
        num n => n != 0,
        String s => s == '1' || s == 'true',
        _ => json['read_at'] != null,
      },
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'message': message,
    'read': isRead,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };

  String toJson() => jsonEncode(toMap());

  ContactMessageModel copyWith({bool? isRead}) => ContactMessageModel(
    id: id,
    name: name,
    email: email,
    phone: phone,
    message: message,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}

// ─── RESPONSE MODEL: MessagesPageModel ───────────────────────────────────────
/// Satu halaman GET /{slug}/manage/messages:
/// {data: [pesan...], meta: {page, last_page, total}}.
class MessagesPageModel {
  final List<ContactMessageModel> items;
  final int page;
  final int lastPage;
  final int total;

  const MessagesPageModel({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => page < lastPage;

  factory MessagesPageModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) {
      throw const FormatException('Daftar pesan tidak valid');
    }
    return MessagesPageModel.fromMap(Map<String, dynamic>.from(decoded));
  }

  factory MessagesPageModel.fromMap(Map<String, dynamic> json) {
    final raw = json['data'];
    if (raw is! List) throw const FormatException('Daftar pesan tidak valid');
    final items = <ContactMessageModel>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        items.add(ContactMessageModel.fromMap(Map<String, dynamic>.from(e)));
      } on FormatException {
        continue;
      }
    }
    final meta = json['meta'] is Map ? json['meta'] as Map : const {};
    int? n(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
    final page = n(meta['page']) ?? 1;
    return MessagesPageModel(
      items: items,
      page: page,
      lastPage: n(meta['last_page']) ?? page,
      total: n(meta['total']) ?? items.length,
    );
  }

  Map<String, dynamic> toMap() => {
    'data': items.map((m) => m.toMap()).toList(),
    'meta': {'page': page, 'last_page': lastPage, 'total': total},
  };

  String toJson() => jsonEncode(toMap());
}
