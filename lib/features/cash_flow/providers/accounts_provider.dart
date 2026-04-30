import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bootstrap/startup_ledger_data.dart';
import '../../debts/providers/debts_ui_provider.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../data/financial_account_model.dart';
import '../utils/wallet_balance_math.dart';
import 'include_debts_in_wallet_balance_provider.dart';

/// قائمة الحسابات المالية — محفوظة محليًا ومُزامَنة مع Firebase عبر [StartupLedgerData].
class AccountsNotifier extends Notifier<List<FinancialAccount>> {
  @override
  List<FinancialAccount> build() {
    return List<FinancialAccount>.from(StartupLedgerData.accounts);
  }

  void _persist() {
    scheduleMicrotask(() => StartupLedgerData.saveAccounts(state));
  }

  void addAccount(FinancialAccount acc) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final withTs = acc.editedMs > 0
        ? acc
        : acc.copyWith(editedMs: now);
    state = [...state, StartupLedgerData.normalizeFinancialAccount(withTs)];
    _persist();
  }

  void updateAccount(FinancialAccount acc) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final n = StartupLedgerData.normalizeFinancialAccount(
      acc.copyWith(editedMs: now),
    );
    state = [
      for (final a in state)
        if (a.id == n.id) n else a,
    ];
    _persist();
  }

  void deleteAccount(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    state = [
      for (final a in state)
        if (a.id == id)
          a.copyWith(
            isDeleted: true,
            deletedMs: now,
            editedMs: now,
          )
        else
          a,
    ];
    _persist();
  }
}

final accountsProvider =
    NotifierProvider<AccountsNotifier, List<FinancialAccount>>(
  AccountsNotifier.new,
);

/// محافظ/حسابات نشطة فقط (للواجهة والاختيار).
final activeAccountsProvider = Provider<List<FinancialAccount>>((ref) {
  return [
    for (final a in ref.watch(accountsProvider)) if (!a.isDeleted) a,
  ];
});

/// مجموع الرصيد الفعلي لكل المحافظ النشطة — يطابق «ملخص الأرصدة» في شاشة المحافظ.
final walletsEffectiveTotalProvider = Provider<double>((ref) {
  final accounts = ref.watch(activeAccountsProvider);
  // نفس مصدر حركات الصندوق المستخدم في تفاصيل المحفظة (يشمل المنطق الكامل للرصيد المبدئي + الحركات).
  final entries = ref.watch(cashbookEntriesProvider);
  final txs = ref.watch(transactionsProvider);
  final includeDebts = ref.watch(includeDebtsInWalletBalanceProvider);
  var s = 0.0;
  for (final a in accounts) {
    s += effectiveWalletBalance(
      acc: a,
      entries: entries,
      txs: txs,
      accounts: accounts,
      includeDebtEffect: includeDebts,
    );
  }
  return s;
});
