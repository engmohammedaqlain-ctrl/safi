import 'package:flutter_riverpod/flutter_riverpod.dart';

/// بيانات معروضة لدفتر النقدية (لاحقاً: ربط بـ Firebase/محلي)
class CashbookSummary {
  const CashbookSummary({
    required this.userName,
    required this.balance,
    required this.income,
    required this.expense,
    required this.transactionCount,
  });

  final String userName;
  final double balance;
  final double income;
  final double expense;
  final int transactionCount;
}

final cashbookSummaryProvider = Provider<CashbookSummary>(
  (ref) => const CashbookSummary(
    userName: 'تاجر',
    balance: 0,
    income: 0,
    expense: 0,
    transactionCount: 0,
  ),
);

String formatMAD(double v) {
  if (v == v.roundToDouble()) {
    return 'MAD ${v.toStringAsFixed(0)}.0';
  }
  return 'MAD ${v.toStringAsFixed(1)}';
}

String obscureMoney() => 'MAD ••••';
