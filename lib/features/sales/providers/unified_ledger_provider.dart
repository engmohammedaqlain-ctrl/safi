import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cash_flow/providers/include_debts_in_wallet_balance_provider.dart';
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

/// صفوف تبويب «الصافي»: صندوق دائماً؛ ومعاملات الدين/السداد عند تفعيل «دمج الديون في أرصدة المحافظ» (مثل الأرشيف).
final safiCashOnlyLedgerRowsProvider = Provider<List<UnifiedLedgerRowUi>>((ref) {
  final cash = ref.watch(activeCashbookEntriesProvider);
  final debtors = ref.watch(debtorsUiProvider);
  final includeDebts = ref.watch(includeDebtsInWalletBalanceProvider);
  final txs = includeDebts
      ? ref.watch(transactionsProvider)
      : const <TransactionUi>[];
  return UnifiedLedgerMath.buildRowsNewestFirst(
    cash: cash,
    txs: txs,
    debtors: debtors,
  );
});

/// دخل/مصروف بطاقة الصافي — صندوق فقط عند إيقاف الدمج؛ ومع الديون عند التفعيل (يتوافق مع القائمة والرصيد الفعلي).
final safiCashOnlyInflowOutflowProvider =
    Provider<({double inflow, double outflow})>((ref) {
  final cash = ref.watch(activeCashbookEntriesProvider);
  final includeDebts = ref.watch(includeDebtsInWalletBalanceProvider);
  final txs = includeDebts
      ? ref.watch(transactionsProvider)
      : const <TransactionUi>[];
  return UnifiedLedgerMath.inflowOutflowSplit(cash: cash, txs: txs);
});
