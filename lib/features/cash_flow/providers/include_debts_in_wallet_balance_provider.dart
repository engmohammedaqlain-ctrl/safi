import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/bootstrap/prefs_keys.dart';
import '../../../core/bootstrap/startup_ledger_data.dart';

/// هل تُحسب معاملات الدين/السداد ضمن الرصيد الفعلي لكل محفظة (الافتراضي: نعم).
final includeDebtsInWalletBalanceProvider =
    NotifierProvider<IncludeDebtsInWalletBalanceNotifier, bool>(
  IncludeDebtsInWalletBalanceNotifier.new,
);

class IncludeDebtsInWalletBalanceNotifier extends Notifier<bool> {
  @override
  bool build() => StartupLedgerData.bootstrapIncludeDebtsInWalletBalance;

  Future<void> setIncludeDebts(bool include) async {
    state = include;
    StartupLedgerData.cacheIncludeDebtsInWalletBalance(include);
    final p = await SharedPreferences.getInstance();
    await p.setBool(PrefsKeys.includeDebtsInWalletBalance, include);
  }
}
