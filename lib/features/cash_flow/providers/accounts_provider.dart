import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bootstrap/startup_ledger_data.dart';
import '../data/financial_account_model.dart';

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
    state = [...state, StartupLedgerData.normalizeFinancialAccount(acc)];
    _persist();
  }

  void updateAccount(FinancialAccount acc) {
    final n = StartupLedgerData.normalizeFinancialAccount(acc);
    state = [
      for (final a in state)
        if (a.id == n.id) n else a,
    ];
    _persist();
  }

  void deleteAccount(String id) {
    state = state.where((a) => a.id != id).toList();
    _persist();
  }
}

final accountsProvider =
    NotifierProvider<AccountsNotifier, List<FinancialAccount>>(
  AccountsNotifier.new,
);
