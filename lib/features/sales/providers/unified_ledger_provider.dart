import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../debts/providers/debts_ui_provider.dart';
import 'cashbook_ui_provider.dart';
import 'unified_ledger_math.dart';

export 'unified_ledger_math.dart' show UnifiedLedgerMath, UnifiedLedgerRowUi, UnifiedLedgerListFilter;

/// صندوق + ديون — الأحدث أولاً (شاشة الأرشيف والسجل الموحّد).
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

/// دخل/مصروف الصندوق فقط — يطابق قائمة «حركات الصندوق» (لا يشمل رصيد المخزَّن في المحافظ).
final safiCashOnlyInflowOutflowProvider =
    Provider<({double inflow, double outflow})>((ref) {
  final cash = ref.watch(activeCashbookEntriesProvider);
  return UnifiedLedgerMath.inflowOutflowSplit(cash: cash, txs: const []);
});
