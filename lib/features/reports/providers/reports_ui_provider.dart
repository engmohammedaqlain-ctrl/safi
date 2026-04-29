import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../../debts/providers/debts_ui_provider.dart';

class SelectedTimeframeNotifier extends Notifier<String> {
  @override
  String build() => 'أسبوع';
  void setTimeframe(String value) => state = value;
}

final selectedTimeframeProvider = NotifierProvider<SelectedTimeframeNotifier, String>(
  SelectedTimeframeNotifier.new,
);

final analyticsDataProvider = Provider((ref) {
  final timeframe = ref.watch(selectedTimeframeProvider);
  final cashbook = ref.watch(cashbookEntriesProvider);
  final txs = ref.watch(transactionsProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  int daysBack = 7;
  if (timeframe == 'شهر') daysBack = 30;
  if (timeframe == 'سنة') daysBack = 365;
  if (timeframe == 'اليوم') daysBack = 1;

  final startDate = today.subtract(Duration(days: daysBack - 1));

  // Initialize data arrays
  final incomeByDay = List<double>.filled(daysBack, 0);
  final expenseByDay = List<double>.filled(daysBack, 0);

  // Process cashbook
  for (final entry in cashbook) {
    if (entry.date.isBefore(startDate)) continue;
    final diff = entry.date.difference(startDate).inDays;
    if (diff >= 0 && diff < daysBack) {
      if (entry.isIncome) {
        incomeByDay[diff] += entry.amount;
      } else {
        expenseByDay[diff] += entry.amount;
      }
    }
  }

  // Process debts (received = income, gave = expense)
  for (final tx in txs) {
    if (tx.date.isBefore(startDate)) continue;
    final diff = tx.date.difference(startDate).inDays;
    if (diff >= 0 && diff < daysBack) {
      if (tx.type == TransactionType.received) {
        incomeByDay[diff] += tx.amount;
      } else {
        expenseByDay[diff] += tx.amount;
      }
    }
  }

  return {
    'income': incomeByDay,
    'expense': expenseByDay,
    'daysBack': daysBack,
    'startDate': startDate,
  };
});

final pnlSpotsProvider = Provider<List<FlSpot>>((ref) {
  final data = ref.watch(analyticsDataProvider);
  final income = data['income'] as List<double>;
  final expense = data['expense'] as List<double>;
  
  final spots = <FlSpot>[];
  for (int i = 0; i < income.length; i++) {
    final net = income[i] - expense[i];
    spots.add(FlSpot(i.toDouble(), net));
  }
  return spots;
});

final salesBarsProvider = Provider<List<BarChartGroupData>>((ref) {
  final data = ref.watch(analyticsDataProvider);
  final income = data['income'] as List<double>;
  
  return List.generate(
    income.length,
    (i) => BarChartGroupData(
      x: i,
      barRods: [
        BarChartRodData(
          toY: income[i],
          width: income.length > 10 ? 8 : 16,
          color: AppColors.electricBlue.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    ),
  );
});

final analyticsSummaryProvider = Provider<String>((ref) {
  final data = ref.watch(analyticsDataProvider);
  final income = data['income'] as List<double>;
  final expense = data['expense'] as List<double>;
  
  final totalIncome = income.fold(0.0, (a, b) => a + b);
  final totalExpense = expense.fold(0.0, (a, b) => a + b);
  final net = totalIncome - totalExpense;
  
  if (totalIncome == 0 && totalExpense == 0) {
    return 'لا توجد حركات مالية في هذه الفترة.';
  }
  
  if (net > 0) {
    return 'أداء ممتاز! صافي الدخل إيجابي بقيمة ${net.toStringAsFixed(1)} شيكل.';
  } else if (net < 0) {
    return 'انتبه، المصروفات تتجاوز الدخل بقيمة ${net.abs().toStringAsFixed(1)} شيكل.';
  } else {
    return 'الدخل والمصروفات متوازنان.';
  }
});