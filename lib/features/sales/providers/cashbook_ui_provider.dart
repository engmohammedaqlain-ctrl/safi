import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bootstrap/startup_ledger_data.dart';
import '../models/cashbook_entry.dart';

class CashbookSummary {
  const CashbookSummary({
    required this.balance,
    required this.income,
    required this.expense,
    required this.transactionCount,
  });

  final double balance;
  final double income;
  final double expense;
  final int transactionCount;
}

class CashbookNotifier extends Notifier<List<CashbookEntry>> {
  @override
  List<CashbookEntry> build() {
    return List<CashbookEntry>.from(StartupLedgerData.cashbook);
  }

  void _persist() {
    scheduleMicrotask(() => StartupLedgerData.saveCashbook(state));
  }

  void add(CashbookEntry e) {
    final entry = e.copyWith(editedMs: DateTime.now().millisecondsSinceEpoch);
    state = [entry, ...state];
    _persist();
  }

  void removeById(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    state = [
      for (final x in state)
        if (x.id == id)
          x.copyWith(
            isDeleted: true,
            deletedMs: now,
            editedMs: now,
          )
        else
          x,
    ];
    _persist();
  }

  void update(CashbookEntry updated) {
    final entry = updated.copyWith(
      editedMs: DateTime.now().millisecondsSinceEpoch,
    );
    state = [
      for (final x in state)
        if (x.id == entry.id) entry else x,
    ];
    _persist();
  }
}

final cashbookEntriesProvider =
    NotifierProvider<CashbookNotifier, List<CashbookEntry>>(
  CashbookNotifier.new,
);

/// حركات الصندوق المعروضة فقط — بدون محذوفة ناعمة (لا تزال في الحالة للمزامنة).
final activeCashbookEntriesProvider = Provider<List<CashbookEntry>>((ref) {
  return [
    for (final e in ref.watch(cashbookEntriesProvider))
      if (!e.isDeleted) e,
  ];
});

final cashbookSummaryProvider = Provider<CashbookSummary>((ref) {
  final list = ref.watch(activeCashbookEntriesProvider);
  double inc = 0, exp = 0;
  for (final e in list) {
    if (e.isIncome) {
      inc += e.amount;
    } else {
      exp += e.amount;
    }
  }
  return CashbookSummary(
    balance: inc - exp,
    income: inc,
    expense: exp,
    transactionCount: list.length,
  );
});

String formatShekelAmount(double v) {
  if (v == v.roundToDouble()) {
    return '${v.toStringAsFixed(0)}.0';
  }
  return v.toStringAsFixed(1);
}

String obscureAmountText() => '••••';
