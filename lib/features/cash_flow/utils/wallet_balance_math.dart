import '../../debts/providers/debts_ui_provider.dart';
import '../../sales/models/cashbook_entry.dart';
import '../data/financial_account_model.dart';

/// يحدّد المحفظة المرتبطة بحركة الصندوق (`accountId` أو fallback للمحفظة الأولى).
String? resolvedCashAccountIdForEntry(
  CashbookEntry e,
  List<FinancialAccount> accs,
) {
  final a = e.accountId;
  if (a != null && a.isNotEmpty) return a;
  return accs.isNotEmpty ? accs.first.id : null;
}

/// هل معاملة الدين هذه على هذه المحفظة (`payMethodId` أو قيم legacy).
bool debtPayTouchesWallet(
  TransactionUi tx,
  FinancialAccount acc,
  List<FinancialAccount> accounts,
) {
  final pid = tx.payMethodId;
  if (pid == null || pid.isEmpty) return false;
  if (pid == acc.id) return true;

  AccountType? legacyType;
  switch (pid) {
    case 'cash':
      legacyType = AccountType.cash;
      break;
    case 'wallet':
      legacyType = AccountType.wallet;
      break;
    case 'bank':
      legacyType = AccountType.bank;
      break;
    default:
      return false;
  }

  if (acc.type != legacyType) return false;
  final same = accounts.where((a) => a.type == legacyType).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  if (same.isEmpty) return false;
  return same.first.id == acc.id;
}

/// صافي حركات الصندوق المنسوبة لهذه المحفظة (موجب وارد، سالب صادر).
double netCashbookSignedForWallet(
  String walletId,
  List<CashbookEntry> entries,
  List<FinancialAccount> accounts,
) {
  var s = 0.0;
  for (final e in entries) {
    final rid = resolvedCashAccountIdForEntry(e, accounts);
    if (rid != walletId) continue;
    s += e.isIncome ? e.amount : -e.amount;
  }
  return s;
}

/// صافي تأثير الديون على هذه المحفظة (سداد للمحفظة +، دين من المحفظة −).
double netDebtSignedForWallet(
  FinancialAccount acc,
  List<TransactionUi> txs,
  List<FinancialAccount> accounts,
) {
  var s = 0.0;
  for (final t in txs) {
    if (!debtPayTouchesWallet(t, acc, accounts)) continue;
    switch (t.type) {
      case TransactionType.received:
        s += t.amount;
        break;
      case TransactionType.gave:
        s -= t.amount;
        break;
    }
  }
  return s;
}

double _moneyRound2(double v) => (v * 100).round() / 100;

/// الرصيد الفعلي المعروض: الرصيد المخزَّن في المحفظة + تأثير كل حركات الصندوق والديون المرتبطة بها.
///
/// الحقل [FinancialAccount.balance] لا يُحدَّث تلقائياً عند كل إدخال حركة؛ لهذا يُضاف صافي الحركات.
double effectiveWalletBalance({
  required FinancialAccount acc,
  required List<CashbookEntry> entries,
  required List<TransactionUi> txs,
  required List<FinancialAccount> accounts,
}) {
  final raw = acc.balance +
      netCashbookSignedForWallet(acc.id, entries, accounts) +
      netDebtSignedForWallet(acc, txs, accounts);
  return _moneyRound2(raw);
}
