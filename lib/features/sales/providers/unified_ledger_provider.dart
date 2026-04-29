import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/bootstrap/prefs_keys.dart';
import '../../../core/bootstrap/startup_ledger_data.dart';
import '../../debts/providers/debts_ui_provider.dart';
import 'cashbook_ui_provider.dart';
import 'unified_ledger_math.dart';

export 'unified_ledger_math.dart' show UnifiedLedgerMath, UnifiedLedgerRowUi;

/// كل حركات الصافي (صندوق + ديون) — الأحدث أولاً.
/// للأرشيف والشاشات التي تعرض كل الحركات معاً.
final unifiedLedgerRowsProvider = Provider<List<UnifiedLedgerRowUi>>((ref) {
  final cash = ref.watch(activeCashbookEntriesProvider);
  final txs = ref.watch(transactionsProvider);
  final debtors = ref.watch(debtorsUiProvider);
  return UnifiedLedgerMath.buildRowsNewestFirst(
    cash: cash,
    txs: txs,
    debtors: debtors,
  );
});

/// صندوق فقط لتبويب «الصافي» — بدون معاملات دين/سداد (تظهر في الأرشيف).
final safiCashOnlyLedgerRowsProvider = Provider<List<UnifiedLedgerRowUi>>((ref) {
  final cash = ref.watch(activeCashbookEntriesProvider);
  final debtors = ref.watch(debtorsUiProvider);
  return UnifiedLedgerMath.buildRowsNewestFirst(
    cash: cash,
    txs: const [],
    debtors: debtors,
  );
});

final unifiedNetSignedProvider = Provider<double>((ref) {
  final cash = ref.watch(activeCashbookEntriesProvider);
  final txs = ref.watch(transactionsProvider);
  return UnifiedLedgerMath.netSignedTotal(cash: cash, txs: txs);
});

/// صافي الصندوق فقط — يطابق قائمة المعاملات في تبويب «الصافي».
final safiCashOnlyNetSignedProvider = Provider<double>((ref) {
  final cash = ref.watch(activeCashbookEntriesProvider);
  return UnifiedLedgerMath.netSignedTotal(cash: cash, txs: const []);
});

final unifiedInflowOutflowProvider =
    Provider<({double inflow, double outflow})>((ref) {
  final cash = ref.watch(activeCashbookEntriesProvider);
  final txs = ref.watch(transactionsProvider);
  return UnifiedLedgerMath.inflowOutflowSplit(cash: cash, txs: txs);
});

/// دخل/مصروف الصندوق فقط — يطابق بطاقة «الصافي» عند عرض حركات الصندوق فقط.
final safiCashOnlyInflowOutflowProvider =
    Provider<({double inflow, double outflow})>((ref) {
  final cash = ref.watch(activeCashbookEntriesProvider);
  return UnifiedLedgerMath.inflowOutflowSplit(cash: cash, txs: const []);
});

/// دمج معاملات الدين/السداد مع تبويب «الصافي» (محفّز من الإعدادات، يُحفظ محلياً).
final mergeDebtsIntoSafiProvider =
    NotifierProvider<MergeDebtsIntoSafiNotifier, bool>(
      MergeDebtsIntoSafiNotifier.new,
    );

class MergeDebtsIntoSafiNotifier extends Notifier<bool> {
  @override
  bool build() => StartupLedgerData.bootstrapMergeDebtsIntoSafiTab;

  Future<void> setMerged(bool merged) async {
    state = merged;
    final p = await SharedPreferences.getInstance();
    await p.setBool(PrefsKeys.mergeDebtsIntoSafiTab, merged);
  }
}
