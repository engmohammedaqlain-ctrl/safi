import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_keys.dart';
import '../../features/debts/providers/debts_ui_provider.dart';
import '../../features/sales/models/cashbook_entry.dart';

/// لقطات أولية تُحمَّل من [SharedPreferences] قبل [runApp] لتفادي السباق مع الحفظ.
class StartupLedgerData {
  StartupLedgerData._();

  static List<DebtorUi> debtors = [];
  static List<TransactionUi> transactions = [];
  static List<CashbookEntry> cashbook = [];

  static bool _sessionLoggedIn = false;
  static bool _sessionOnboardingDone = false;
  static String? _sessionUserName;

  static Future<void>? _loadFuture;

  /// يبدأ التحميل مرة واحدة؛ آمِن لاستدعائه من عدة أماكن.
  static Future<void> ensureLoaded() => _loadFuture ??= load();

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _sessionLoggedIn = p.getBool(PrefsKeys.loggedIn) ?? false;
    _sessionOnboardingDone = p.getBool(PrefsKeys.onboardingDone) ?? false;
    _sessionUserName = p.getString(PrefsKeys.userName);
    debtors = _decodeDebtors(p.getString(PrefsKeys.debtors));
    transactions = _decodeTransactions(p.getString(PrefsKeys.transactions));
    cashbook = _decodeCashbook(p.getString(PrefsKeys.cashbook));
  }

  /// تُقرأ مع [ensureLoaded] في نفس جولة [SharedPreferences] لتفادي انتظار إضافي عند فتح الجلسة.
  static bool get bootstrapLoggedIn => _sessionLoggedIn;

  static bool get bootstrapOnboardingDone => _sessionOnboardingDone;

  static String? get bootstrapUserName => _sessionUserName;

  static List<DebtorUi> _decodeDebtors(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [for (final e in list) _debtorFromMap(e as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }

  static List<TransactionUi> _decodeTransactions(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list) _transactionFromMap(e as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  static List<CashbookEntry> _decodeCashbook(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          CashbookEntry.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDebtors(List<DebtorUi> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      PrefsKeys.debtors,
      jsonEncode([for (final d in list) _debtorToMap(d)]),
    );
  }

  static Future<void> saveTransactions(List<TransactionUi> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      PrefsKeys.transactions,
      jsonEncode([for (final t in list) _transactionToMap(t)]),
    );
  }

  static Future<void> saveCashbook(List<CashbookEntry> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      PrefsKeys.cashbook,
      jsonEncode([for (final c in list) c.toJson()]),
    );
  }

  // ── DebtorUi JSON ──
  static Map<String, dynamic> _debtorToMap(DebtorUi d) => {
        'id': d.id,
        'name': d.name,
        'phone': d.phone,
        'amount': d.amount,
        'status': d.status,
        'urgency': d.urgency.name,
        'address': d.address,
        'categoryIds': d.categoryIds,
        'isSupplier': d.isSupplier,
      };

  static DebtorUi _debtorFromMap(Map<String, dynamic> m) {
    return DebtorUi(
      id: m['id'] as String,
      name: m['name'] as String,
      phone: m['phone'] as String? ?? '',
      amount: m['amount'] as String? ?? '0.0',
      status: m['status'] as String? ?? '',
      urgency: DebtUrgency.values.firstWhere(
        (e) => e.name == m['urgency'],
        orElse: () => DebtUrgency.low,
      ),
      address: m['address'] as String?,
      categoryIds: (m['categoryIds'] as List<dynamic>?) == null
          ? const []
          : [for (final c in m['categoryIds'] as List<dynamic>) c as String],
      isSupplier: m['isSupplier'] as bool? ?? false,
    );
  }

  // ── TransactionUi JSON ──
  static Map<String, dynamic> _transactionToMap(TransactionUi t) => {
        'id': t.id,
        'customerId': t.customerId,
        'amount': t.amount,
        'type': t.type.name,
        'note': t.note,
        'date': t.date.toIso8601String(),
        'payMethodId': t.payMethodId,
        'imagePath': t.imagePath,
      };

  static TransactionUi _transactionFromMap(Map<String, dynamic> m) {
    return TransactionUi(
      id: m['id'] as String,
      customerId: m['customerId'] as String,
      amount: (m['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == m['type'],
        orElse: () => TransactionType.gave,
      ),
      note: m['note'] as String? ?? '',
      date: DateTime.parse(m['date'] as String),
      payMethodId: m['payMethodId'] as String?,
      imagePath: m['imagePath'] as String?,
    );
  }
}
