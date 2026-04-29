import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_keys.dart';
import '../../features/cash_flow/data/financial_account_model.dart';
import '../../features/debts/models/debt_category_model.dart';
import '../../features/debts/providers/debts_ui_provider.dart';
import '../../features/sales/models/cashbook_entry.dart';

/// لقطات أولية تُحمَّل من [SharedPreferences] قبل [runApp] لتفادي السباق مع الحفظ.
class StartupLedgerData {
  StartupLedgerData._();

  static List<DebtorUi> debtors = [];
  static List<TransactionUi> transactions = [];
  static List<CashbookEntry> cashbook = [];

  /// الحسابات المالية (كاش، بنك، محفظة) — تُزامن مع Firestore.
  static List<FinancialAccount> accounts = [];

  /// تصنيفات الديون.
  static List<DebtCategory> debtCategories = [];

  static bool _sessionLoggedIn = false;
  static bool _sessionOnboardingDone = false;
  static String? _sessionUserName;

  static Future<void>? _loadFuture;

  /// يبدأ التحميل مرة واحدة؛ آمِن لاستدعائه من عدة أماكن.
  static Future<void> ensureLoaded() => _loadFuture ??= load();

  /// يُستدعى بعد كل حفظ محلي للحافظة — تُسجّل المزامنة السحابية المؤجّلة.
  static void Function()? onLedgerPersistedForCloud;

  static void _notifyCloudSyncHook() {
    onLedgerPersistedForCloud?.call();
  }

  /// إعادة قراءة [SharedPreferences] إلى الذاكرة الثابتة (بعد سحب سحابي مثلاً).
  static Future<void> reloadFromDiskIntoMemory() async {
    await load();
  }

  /// تحديث كاش الاسم المعروض بعد تغيِّر [PrefsKeys.userName] خارج [load].
  static Future<void> refreshCachedUserName() async {
    final p = await SharedPreferences.getInstance();
    _sessionUserName = p.getString(PrefsKeys.userName);
  }

  /// مسح دفتر العمليات محلياً (عملاء، معاملات، صندوق…) واستبدال المحافظ بالبذور الافتراضية.
  /// يُستدعى عند الخروج أو عند احتمال اختلاط بيانات مستخدمَين مختلفَين بحساب Firebase.
  static Future<void> wipeLocalLedgerStorageAndPersist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(PrefsKeys.debtors, '[]');
    await p.setString(PrefsKeys.transactions, '[]');
    await p.setString(PrefsKeys.cashbook, '[]');
    await p.setString(
      PrefsKeys.accounts,
      jsonEncode([
        for (final a in _seedFinancialAccounts) _financialAccountToMap(a),
      ]),
    );
    await p.setString(PrefsKeys.debtCategories, '[]');
    await p.remove(PrefsKeys.lastLedgerSyncedMs);

    debtors = [];
    transactions = [];
    cashbook = [];
    accounts = List<FinancialAccount>.from(_seedFinancialAccounts);
    debtCategories = [];
  }

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _sessionLoggedIn = p.getBool(PrefsKeys.loggedIn) ?? false;
    _sessionOnboardingDone = p.getBool(PrefsKeys.onboardingDone) ?? false;
    _sessionUserName = p.getString(PrefsKeys.userName);
    debtors = _decodeDebtors(p.getString(PrefsKeys.debtors));
    transactions = _decodeTransactions(p.getString(PrefsKeys.transactions));
    cashbook = _decodeCashbook(p.getString(PrefsKeys.cashbook));

    final accountsRaw = p.getString(PrefsKeys.accounts);
    List<FinancialAccount> acc;
    if (accountsRaw == null) {
      acc = List<FinancialAccount>.from(_seedFinancialAccounts);
      await p.setString(
        PrefsKeys.accounts,
        jsonEncode([for (final a in acc) _financialAccountToMap(a)]),
      );
      _notifyCloudSyncHook();
    } else {
      acc = _decodeAccounts(accountsRaw);
    }
    accounts = acc;

    debtCategories = _decodeDebtCategories(
      p.getString(PrefsKeys.debtCategories),
    );
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

  static String _encodeDebtors(List<DebtorUi> list) =>
      jsonEncode([for (final d in list) _debtorToMap(d)]);
  static String _encodeTransactions(List<TransactionUi> list) =>
      jsonEncode([for (final t in list) _transactionToMap(t)]);
  static String _encodeCashbook(List<CashbookEntry> list) =>
      jsonEncode([for (final c in list) c.toJson()]);

  static Future<void> saveDebtors(List<DebtorUi> list) async {
    final raw = await compute(_encodeDebtors, list);
    final p = await SharedPreferences.getInstance();
    await p.setString(PrefsKeys.debtors, raw);
    _notifyCloudSyncHook();
  }

  static Future<void> saveTransactions(List<TransactionUi> list) async {
    final raw = await compute(_encodeTransactions, list);
    final p = await SharedPreferences.getInstance();
    await p.setString(PrefsKeys.transactions, raw);
    _notifyCloudSyncHook();
  }

  static Future<void> saveCashbook(List<CashbookEntry> list) async {
    final raw = await compute(_encodeCashbook, list);
    final p = await SharedPreferences.getInstance();
    await p.setString(PrefsKeys.cashbook, raw);

    _notifyCloudSyncHook();
  }

  static Future<void> saveAccounts(List<FinancialAccount> list) async {
    accounts = List<FinancialAccount>.from(list);
    final p = await SharedPreferences.getInstance();
    await p.setString(
      PrefsKeys.accounts,
      jsonEncode([for (final a in accounts) _financialAccountToMap(a)]),
    );
    _notifyCloudSyncHook();
  }

  static Future<void> saveDebtCategories(List<DebtCategory> list) async {
    debtCategories = List<DebtCategory>.from(list);
    final p = await SharedPreferences.getInstance();
    await p.setString(
      PrefsKeys.debtCategories,
      jsonEncode([for (final c in debtCategories) _debtCategoryToMap(c)]),
    );
    _notifyCloudSyncHook();
  }

  /// بذور أول تشغيل — تُستخدم فقط لو لا يوجد `accounts_json` بعد.
  static const List<FinancialAccount> _seedFinancialAccounts = [
    FinancialAccount(
      id: '1',
      name: 'الدرج الرئيسي',
      type: AccountType.cash,
      balance: 1200,
    ),
    FinancialAccount(
      id: '2',
      name: 'حساب بنك فلسطين',
      type: AccountType.bank,
      balance: 4500,
      accountNumber: '12345678',
      accountOwner: 'المالك',
    ),
    FinancialAccount(
      id: '3',
      name: 'جوال بي',
      type: AccountType.wallet,
      balance: 300,
      accountNumber: '0599123456',
    ),
  ];

  static List<FinancialAccount> _decodeAccounts(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          _financialAccountFromMap(e as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  static List<DebtCategory> _decodeDebtCategories(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list) _debtCategoryFromMap(e as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  static Map<String, dynamic> _financialAccountToMap(FinancialAccount a) => {
    'id': a.id,
    'name': a.name,
    'type': a.type.name,
    'balance': a.balance,
    'accountNumber': a.accountNumber,
    'accountOwner': a.accountOwner,
  };

  static FinancialAccount _financialAccountFromMap(Map<String, dynamic> m) {
    return FinancialAccount(
      id: m['id'] as String,
      name: m['name'] as String,
      type: AccountType.values.firstWhere(
        (t) => t.name == (m['type'] as String? ?? 'cash'),
        orElse: () => AccountType.cash,
      ),
      balance: (m['balance'] as num?)?.toDouble() ?? 0,
      accountNumber: m['accountNumber'] as String?,
      accountOwner: m['accountOwner'] as String?,
    );
  }

  static Map<String, dynamic> _debtCategoryToMap(DebtCategory c) => {
    'id': c.id,
    'name': c.name,
    'colorValue': c.colorValue,
  };

  static DebtCategory _debtCategoryFromMap(Map<String, dynamic> m) {
    return DebtCategory(
      id: m['id'] as String,
      name: m['name'] as String,
      colorValue: (m['colorValue'] as num?)?.toInt() ?? 0xFF000000,
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
    'editedMs': d.editedMs,
    'doubleLedger': d.doubleLedger,
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
      editedMs: (m['editedMs'] as num?)?.toInt() ?? 0,
      doubleLedger: m['doubleLedger'] as bool? ?? false,
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
    'editedMs': t.editedMs,
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
      editedMs: (m['editedMs'] as num?)?.toInt() ?? 0,
    );
  }

  // ── واجهات عامة للمزامنة مع Firestore (مجموعات فرعية) ──

  static Map<String, dynamic> debtorToMap(DebtorUi d) => _debtorToMap(d);
  static DebtorUi debtorFromMap(Map<String, dynamic> m) => _debtorFromMap(m);

  static Map<String, dynamic> transactionToMap(TransactionUi t) =>
      _transactionToMap(t);
  static TransactionUi transactionFromMap(Map<String, dynamic> m) =>
      _transactionFromMap(m);

  static Map<String, dynamic> financialAccountToMap(FinancialAccount a) =>
      _financialAccountToMap(a);
  static FinancialAccount financialAccountFromMap(Map<String, dynamic> m) =>
      _financialAccountFromMap(m);

  static Map<String, dynamic> debtCategoryToMap(DebtCategory c) =>
      _debtCategoryToMap(c);
  static DebtCategory debtCategoryFromMap(Map<String, dynamic> m) =>
      _debtCategoryFromMap(m);

  static String encodeDebtorsJson(List<DebtorUi> list) =>
      jsonEncode([for (final d in list) _debtorToMap(d)]);
  static String encodeTransactionsJson(List<TransactionUi> list) =>
      jsonEncode([for (final t in list) _transactionToMap(t)]);
  static String encodeCashbookJson(List<CashbookEntry> list) =>
      jsonEncode([for (final c in list) c.toJson()]);
  static String encodeAccountsJson(List<FinancialAccount> list) =>
      jsonEncode([for (final a in list) _financialAccountToMap(a)]);
  static String encodeDebtCategoriesJson(List<DebtCategory> list) =>
      jsonEncode([for (final c in list) _debtCategoryToMap(c)]);
}
