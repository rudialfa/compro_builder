import 'dart:convert';

import 'package:compro_builder/data/model/response/plan_info_model.dart';
import 'package:compro_builder/data/model/response/tenant_model.dart';

int? _toInt(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

String? _toStrOrNull(Object? v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

DateTime? _toDate(Object? v) =>
    v == null ? null : DateTime.tryParse('$v')?.toLocal();

Map<String, dynamic> _unwrapData(String str, String errorMessage) {
  final decoded = jsonDecode(str);
  if (decoded is! Map) throw FormatException(errorMessage);
  final inner = decoded['data'];
  return Map<String, dynamic>.from(inner is Map ? inner : decoded);
}

// ─── Harga satu paket untuk satu periode ─────────────────────────────────────
/// `quotes[]` pada paket: {months, amount} (rupiah, sudah termasuk pengali periode).
class BillingQuoteModel {
  final int months;
  final int amount;

  const BillingQuoteModel({required this.months, required this.amount});

  factory BillingQuoteModel.fromMap(Map<String, dynamic> json) =>
      BillingQuoteModel(
        months: _toInt(json['months']) ?? 0,
        amount: _toInt(json['amount']) ?? 0,
      );
}

/// `periods[]`: {months, label, multiplier}.
class BillingPeriodModel {
  final int months;
  final String label;
  final num multiplier;

  const BillingPeriodModel({
    required this.months,
    required this.label,
    this.multiplier = 1,
  });

  factory BillingPeriodModel.fromMap(Map<String, dynamic> json) {
    final months = _toInt(json['months']) ?? 0;
    return BillingPeriodModel(
      months: months,
      label: _toStrOrNull(json['label']) ?? '$months bulan',
      multiplier: json['multiplier'] is num ? json['multiplier'] as num : 1,
    );
  }
}

/// `methods[]`: {code, label, group}. Daftar dari server; aplikasi tidak
/// menebak metode apa yang tersedia.
class BillingMethodModel {
  final String code;
  final String label;
  final String group;

  const BillingMethodModel({
    required this.code,
    required this.label,
    this.group = '',
  });

  factory BillingMethodModel.fromMap(Map<String, dynamic> json) =>
      BillingMethodModel(
        code: (json['code'] ?? '').toString(),
        label: (json['label'] ?? json['code'] ?? '').toString(),
        group: (json['group'] ?? '').toString(),
      );
}

/// `plans[]`: {code, name, level, price, limits, current, buyable, quotes}.
class BillingPlanModel {
  final String code;
  final String name;
  final int level;
  final int price;

  /// Mentah dari server; bentuk baris tampil sama dengan halaman Paket.
  final Map<String, Object?> limits;
  final bool current;
  final bool buyable;
  final List<BillingQuoteModel> quotes;

  const BillingPlanModel({
    required this.code,
    required this.name,
    this.level = 0,
    this.price = 0,
    this.limits = const {},
    this.current = false,
    this.buyable = false,
    this.quotes = const [],
  });

  factory BillingPlanModel.fromMap(Map<String, dynamic> json) {
    final code = (json['code'] ?? '').toString();
    final name = (json['name'] ?? code).toString();
    if (code.isEmpty) throw const FormatException('Paket tanpa kode');
    final rawLimits = json['limits'];
    final rawQuotes = json['quotes'];
    return BillingPlanModel(
      code: code,
      name: name,
      level: _toInt(json['level']) ?? 0,
      price: _toInt(json['price']) ?? 0,
      limits: rawLimits is Map ? Map<String, Object?>.from(rawLimits) : const {},
      current: json['current'] == true,
      buyable: json['buyable'] == true,
      quotes: rawQuotes is List
          ? rawQuotes
                .whereType<Map>()
                .map((e) => BillingQuoteModel.fromMap(e.cast<String, dynamic>()))
                .toList(growable: false)
          : const [],
    );
  }

  /// Harga untuk [months] bulan; null bila server tidak menyebut periode itu.
  int? amountFor(int months) {
    for (final q in quotes) {
      if (q.months == months) return q.amount;
    }
    return null;
  }

  /// Baris batas paket siap tampil (label sama dengan halaman Paket).
  List<PlanLimit> get limitRows =>
      PlanInfoModel(code: code, name: name, limits: limits).limitRows;
}

// ─── Rincian cara bayar ──────────────────────────────────────────────────────
enum BillingDetailsType { va, bill, qris, unknown }

/// `details` order yang sedang menunggu bayar:
/// VA {type:"va",bank,number} | Mandiri {type:"bill",biller_code,bill_key} |
/// QRIS {type:"qris",qr_string,qr_url}.
class BillingPayDetails {
  final BillingDetailsType type;
  final String? bank;
  final String? number;
  final String? billerCode;
  final String? billKey;
  final String? qrString;
  final String? qrUrl;

  const BillingPayDetails({
    required this.type,
    this.bank,
    this.number,
    this.billerCode,
    this.billKey,
    this.qrString,
    this.qrUrl,
  });

  factory BillingPayDetails.fromMap(Map<String, dynamic> json) =>
      BillingPayDetails(
        type: switch (json['type']) {
          'va' => BillingDetailsType.va,
          'bill' => BillingDetailsType.bill,
          'qris' => BillingDetailsType.qris,
          _ => BillingDetailsType.unknown,
        },
        bank: _toStrOrNull(json['bank']),
        number: _toStrOrNull(json['number']),
        billerCode: _toStrOrNull(json['biller_code']),
        billKey: _toStrOrNull(json['bill_key']),
        qrString: _toStrOrNull(json['qr_string']),
        qrUrl: _toStrOrNull(json['qr_url']),
      );
}

/// `state` order: choose (pilih metode) | instructions | paid | closed.
enum BillingOrderStep { choose, instructions, paid, closed, unknown }

BillingOrderStep _stepOf(Object? v) => switch (v) {
  'choose' => BillingOrderStep.choose,
  'instructions' => BillingOrderStep.instructions,
  'paid' => BillingOrderStep.paid,
  'closed' => BillingOrderStep.closed,
  _ => BillingOrderStep.unknown,
};

/// Cadangan bila `state` dari server tidak ada / tidak dikenal (mis. backend versi lama):
/// tebak langkah dari status order, jangan langsung dianggap "tagihan tidak aktif".
BillingOrderStep _stepFromStatus(String status, {bool hasCharge = false}) =>
    switch (status.toLowerCase()) {
      'paid' => BillingOrderStep.paid,
      'pending' =>
        hasCharge ? BillingOrderStep.instructions : BillingOrderStep.choose,
      _ => BillingOrderStep.closed,
    };

// ─── Satu order/tagihan ──────────────────────────────────────────────────────
/// Bentuk `data` dari POST /checkout, POST /orders/{id}/charge, GET /orders/{id},
/// elemen GET /orders, dan `pending_order` pada GET /billing.
class BillingOrderModel {
  final int id;
  final String number;

  /// Status mentah server (mis. pending, paid, failed, expired).
  final String status;
  final BillingOrderStep step;
  final int months;
  final int amount;
  final String planCode;
  final String planName;
  final int planLevel;
  final String? method;
  final String? methodLabel;
  final BillingPayDetails? details;
  final DateTime? expiresAt;

  /// Tagihan di gateway sudah lewat batas waktu tetapi order masih pending:
  /// pengguna perlu memilih metode lagi.
  final bool timedOut;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final String? webPayUrl;

  const BillingOrderModel({
    required this.id,
    required this.number,
    this.status = 'pending',
    this.step = BillingOrderStep.unknown,
    this.months = 0,
    this.amount = 0,
    this.planCode = '',
    this.planName = '',
    this.planLevel = 0,
    this.method,
    this.methodLabel,
    this.details,
    this.expiresAt,
    this.timedOut = false,
    this.paidAt,
    this.createdAt,
    this.webPayUrl,
  });

  factory BillingOrderModel.fromJson(String str) => BillingOrderModel.fromMap(
    _unwrapData(str, 'Data tagihan tidak valid'),
  );

  factory BillingOrderModel.fromMap(Map<String, dynamic> json) {
    final id = _toInt(json['id']);
    if (id == null) throw const FormatException('Tagihan tanpa id');
    final rawPlan = json['plan'];
    final plan = rawPlan is Map
        ? rawPlan.cast<String, dynamic>()
        : const <String, dynamic>{};
    final rawDetails = json['details'];
    final status = (json['status'] ?? 'pending').toString();
    final expiresAt = _toDate(json['expires_at']);
    var step = _stepOf(json['state']);
    // `state` tidak dikirim ATAU tidak dikenal: tebak dari status order, supaya order yang
    // masih pending tidak pernah tampil sebagai "tagihan tidak aktif". `closed` eksplisit dari server dipercaya.
    if (step == BillingOrderStep.unknown) {
      step = _stepFromStatus(
        status,
        hasCharge:
            rawDetails is Map &&
            rawDetails.isNotEmpty &&
            (expiresAt == null || expiresAt.isAfter(DateTime.now())),
      );
    }
    return BillingOrderModel(
      id: id,
      number: (json['number'] ?? '').toString(),
      status: status,
      step: step,
      months: _toInt(json['months']) ?? 0,
      amount: _toInt(json['amount']) ?? 0,
      planCode: (plan['code'] ?? '').toString(),
      planName: (plan['name'] ?? plan['code'] ?? '').toString(),
      planLevel: _toInt(plan['level']) ?? 0,
      method: _toStrOrNull(json['method']),
      methodLabel: _toStrOrNull(json['method_label']),
      details: rawDetails is Map
          ? BillingPayDetails.fromMap(rawDetails.cast<String, dynamic>())
          : null,
      expiresAt: expiresAt,
      timedOut: json['timed_out'] == true,
      paidAt: _toDate(json['paid_at']),
      createdAt: _toDate(json['created_at']),
      webPayUrl: _toStrOrNull(json['web_pay_url']),
    );
  }

  bool get isPaid => step == BillingOrderStep.paid;

  /// Masih bisa dibayar (pilih metode atau menunggu transfer).
  bool get isPayable =>
      step == BillingOrderStep.choose || step == BillingOrderStep.instructions;

  /// Terapkan hasil polling status ke order yang sedang tampil.
  /// Rincian bayar hanya dipertahankan selama server masih `instructions`.
  BillingOrderModel applyStatus(BillingStatusModel s, {DateTime? now}) {
    // `state` dari polling bisa tidak terbaca: pertahankan langkah sekarang selama
    // order masih pending, supaya layar bayar tidak berubah jadi "tidak aktif".
    final nextStep = s.step != BillingOrderStep.unknown
        ? s.step
        : (s.status.isEmpty
              ? step
              : s.paid
              ? BillingOrderStep.paid
              : _stepFromStatus(
                  s.status,
                  hasCharge: step == BillingOrderStep.instructions,
                ));
    return BillingOrderModel(
        id: id,
        number: number,
        status: s.status,
        step: nextStep,
        months: months,
        amount: amount,
        planCode: planCode,
        planName: planName,
        planLevel: planLevel,
        method: method,
        methodLabel: methodLabel,
        details: nextStep == BillingOrderStep.instructions ? details : null,
        expiresAt: expiresAt,
        timedOut: s.expired,
        paidAt: s.paid ? (paidAt ?? now ?? DateTime.now()) : paidAt,
        createdAt: createdAt,
        webPayUrl: webPayUrl,
      );
  }
}

// ─── Hasil polling status ────────────────────────────────────────────────────
/// GET /orders/{id}/status -> {data:{status, paid, expired, state, tenant?}}.
/// `tenant` (tenantSummary terbaru) hanya ada bila sudah lunas.
class BillingStatusModel {
  final String status;
  final bool paid;

  /// `expired` pada API = batas waktu tagihan lewat (order masih pending).
  final bool expired;
  final BillingOrderStep step;
  final TenantModel? tenant;

  const BillingStatusModel({
    required this.status,
    this.paid = false,
    this.expired = false,
    this.step = BillingOrderStep.unknown,
    this.tenant,
  });

  factory BillingStatusModel.fromJson(String str) => BillingStatusModel.fromMap(
    _unwrapData(str, 'Status pembayaran tidak valid'),
  );

  factory BillingStatusModel.fromMap(Map<String, dynamic> json) {
    final rawTenant = json['tenant'];
    TenantModel? tenant;
    if (rawTenant is Map) {
      final t = TenantModel.fromMap(rawTenant.cast<String, dynamic>());
      if (t.slug.isNotEmpty) tenant = t;
    }
    final paid = json['paid'] == true;
    final step = _stepOf(json['state']);
    return BillingStatusModel(
      status: (json['status'] ?? '').toString(),
      paid: paid,
      expired: json['expired'] == true,
      // Lunas selalu dianggap `paid` walau `state` tidak terbaca.
      step: paid ? BillingOrderStep.paid : step,
      tenant: tenant,
    );
  }
}

// ─── GET /billing ────────────────────────────────────────────────────────────
class BillingOverviewModel {
  final PlanSummaryModel current;
  final bool emailVerified;

  /// false (driver `fake`): checkout tetap jalan, pembayaran lewat [BillingOrderModel.webPayUrl].
  final bool inAppPayment;
  final String driver;
  final List<BillingMethodModel> methods;
  final List<BillingPeriodModel> periods;
  final List<BillingPlanModel> plans;
  final BillingOrderModel? pendingOrder;
  final String? webBillingUrl;

  const BillingOverviewModel({
    required this.current,
    this.emailVerified = false,
    this.inAppPayment = false,
    this.driver = '',
    this.methods = const [],
    this.periods = const [],
    this.plans = const [],
    this.pendingOrder,
    this.webBillingUrl,
  });

  factory BillingOverviewModel.fromJson(String str) =>
      BillingOverviewModel.fromMap(
        _unwrapData(str, 'Data tagihan tidak valid'),
      );

  factory BillingOverviewModel.fromMap(Map<String, dynamic> json) {
    List<T> list<T>(Object? raw, T Function(Map<String, dynamic>) build) =>
        raw is List
        ? raw
              .whereType<Map>()
              .map((e) => build(e.cast<String, dynamic>()))
              .toList(growable: false)
        : <T>[];

    final rawCurrent = json['current'];
    final rawPending = json['pending_order'];
    return BillingOverviewModel(
      current: rawCurrent is Map
          ? PlanSummaryModel.fromMap(rawCurrent.cast<String, dynamic>())
          : const PlanSummaryModel(),
      emailVerified: json['email_verified'] == true,
      inAppPayment: json['in_app_payment'] == true,
      driver: (json['driver'] ?? '').toString(),
      methods: list(json['methods'], BillingMethodModel.fromMap),
      periods: list(json['periods'], BillingPeriodModel.fromMap),
      plans: list(json['plans'], BillingPlanModel.fromMap),
      pendingOrder: rawPending is Map
          ? BillingOrderModel.fromMap(rawPending.cast<String, dynamic>())
          : null,
      webBillingUrl: _toStrOrNull(json['web_billing_url']),
    );
  }

  /// Paket yang boleh dibeli (server yang menentukan lewat `buyable`).
  List<BillingPlanModel> get buyablePlans =>
      plans.where((p) => p.buyable).toList(growable: false);
}

// ─── GET /orders (riwayat) ───────────────────────────────────────────────────
class BillingOrdersPageModel {
  final List<BillingOrderModel> orders;
  final int page;
  final int lastPage;
  final int total;

  const BillingOrdersPageModel({
    required this.orders,
    this.page = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  bool get hasMore => page < lastPage;

  factory BillingOrdersPageModel.fromJson(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! Map) throw const FormatException('Riwayat tidak valid');
    final raw = decoded['data'];
    if (raw is! List) throw const FormatException('Riwayat tidak valid');
    final meta = decoded['meta'] is Map
        ? (decoded['meta'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return BillingOrdersPageModel(
      orders: raw
          .whereType<Map>()
          .map((e) => BillingOrderModel.fromMap(e.cast<String, dynamic>()))
          .toList(growable: false),
      page: _toInt(meta['page']) ?? 1,
      lastPage: _toInt(meta['last_page']) ?? 1,
      total: _toInt(meta['total']) ?? raw.length,
    );
  }
}
