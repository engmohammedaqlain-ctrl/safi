import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../debts/providers/debts_ui_provider.dart';
import 'cashbook_ui_provider.dart';
import 'unified_ledger_math.dart';

export 'unified_ledger_math.dart' show UnifiedLedgerMath, UnifiedLedgerRowUi;

/// كل حركات الصافي (صندوق + ديون) — الأحدث أولاً.
final unifiedLedgerRowsProvider = Provider<List<UnifiedLedgerRowUi>>((ref) {
  final cash = ref.watch(cashbookEntriesProvider);
  final txs = ref.watch(transactionsProvider);
  final debtors = ref.watch(debtorsUiProvider);
  return UnifiedLedgerMath.buildRowsNewestFirst(
    cash: cash,
    txs: txs,
    debtors: debtors,
  );
});

final unifiedNetSignedProvider = Provider<double>((ref) {
  final cash = ref.watch(cashbookEntriesProvider);
  final txs = ref.watch(transactionsProvider);
  return UnifiedLedgerMath.netSignedTotal(cash: cash, txs: txs);
});

final unifiedInflowOutflowProvider =
    Provider<({double inflow, double outflow})>((ref) {
  final cash = ref.watch(cashbookEntriesProvider);
  final txs = ref.watch(transactionsProvider);
  return UnifiedLedgerMath.inflowOutflowSplit(cash: cash, txs: txs);
});
