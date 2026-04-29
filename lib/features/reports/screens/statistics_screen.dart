import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/reports_style_shell.dart';
import '../../debts/providers/debts_ui_provider.dart';
import '../../sales/providers/cashbook_ui_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _selectedPeriodIndex = 1; // 0: اليوم, 1: أسبوع, 2: شهر, 3: سنة

  @override
  Widget build(BuildContext context) {
    final cashbookEntries = ref.watch(cashbookEntriesProvider);
    final transactions = ref.watch(transactionsProvider);

    // Filter by period
    final now = DateTime.now();
    DateTime startDate;
    if (_selectedPeriodIndex == 0) {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (_selectedPeriodIndex == 1) {
      startDate = now.subtract(const Duration(days: 7));
    } else if (_selectedPeriodIndex == 2) {
      startDate = now.subtract(const Duration(days: 30));
    } else {
      startDate = now.subtract(const Duration(days: 365));
    }

    final filteredCashbook = cashbookEntries.where((e) => e.date.isAfter(startDate)).toList();
    final filteredTransactions = transactions.where((t) => t.date.isAfter(startDate)).toList();

    double totalIncome = 0;
    double totalExpense = 0;

    for (final e in filteredCashbook) {
      if (e.isIncome) {
        totalIncome += e.amount;
      } else {
        totalExpense += e.amount;
      }
    }

    for (final t in filteredTransactions) {
      if (t.type == TransactionType.received) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    final profit = totalIncome - totalExpense;
    final profitMargin = totalIncome > 0 ? (profit / totalIncome) * 100 : 0.0;

    // Generate daily sales for the last 6 days
    List<double> dailySales = List.filled(6, 0.0);
    for (int i = 0; i < 6; i++) {
      final date = now.subtract(Duration(days: 5 - i));
      final dailyEntries = cashbookEntries.where((e) => 
        e.isIncome && 
        e.date.year == date.year && 
        e.date.month == date.month && 
        e.date.day == date.day
      );
      final dailyTrans = transactions.where((t) => 
        t.type == TransactionType.received && 
        t.date.year == date.year && 
        t.date.month == date.month && 
        t.date.day == date.day
      );
      
      double dayTotal = 0;
      for (final e in dailyEntries) {
        dayTotal += e.amount;
      }
      for (final t in dailyTrans) {
        dayTotal += t.amount;
      }
      
      dailySales[i] = dayTotal;
    }

    final maxDailySale = dailySales.isEmpty ? 10.0 : dailySales.reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxDailySale > 0 ? maxDailySale * 1.2 : 10.0;

    // Calculate line chart data (Profit vs Cost over 6 periods)
    List<FlSpot> profitSpots = [];
    double maxLineY = 10.0;
    
    if (_selectedPeriodIndex == 0) {
      // Today: hourly
      for (int i = 0; i <= 5; i++) {
        profitSpots.add(FlSpot(i.toDouble(), (i * 2 + 1).toDouble())); // Placeholder for hourly logic
      }
    } else {
      // Other periods: daily/weekly
      for (int i = 0; i <= 5; i++) {
        final date = now.subtract(Duration(days: 5 - i));
        double dayIn = 0;
        double dayOut = 0;
        
        final dEntries = cashbookEntries.where((e) => e.date.year == date.year && e.date.month == date.month && e.date.day == date.day);
        for (final e in dEntries) {
          if (e.isIncome) {
            dayIn += e.amount;
          } else {
            dayOut += e.amount;
          }
        }
        
        final dTrans = transactions.where((t) => t.date.year == date.year && t.date.month == date.month && t.date.day == date.day);
        for (final t in dTrans) {
          if (t.type == TransactionType.received) {
            dayIn += t.amount;
          } else {
            dayOut += t.amount;
          }
        }
        
        final dayProfit = dayIn - dayOut;
        if (dayProfit > maxLineY) maxLineY = dayProfit;
        profitSpots.add(FlSpot(i.toDouble(), dayProfit > 0 ? dayProfit : 0));
      }
    }
    
    maxLineY = maxLineY * 1.2;
    if (maxLineY < 10) maxLineY = 10;

    return ReportsStylePage(
      title: 'الإحصائيات',
      subtitle: 'تحليل سريع ورسوم بحسب الفترة',
      child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Time Period Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الفترة الزمنية',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    _PeriodButton(
                      title: 'اليوم',
                      isSelected: _selectedPeriodIndex == 0,
                      onTap: () => setState(() => _selectedPeriodIndex = 0),
                    ),
                    const SizedBox(width: 8),
                    _PeriodButton(
                      title: 'أسبوع',
                      isSelected: _selectedPeriodIndex == 1,
                      onTap: () => setState(() => _selectedPeriodIndex = 1),
                    ),
                    const SizedBox(width: 8),
                    _PeriodButton(
                      title: 'شهر',
                      isSelected: _selectedPeriodIndex == 2,
                      onTap: () => setState(() => _selectedPeriodIndex = 2),
                    ),
                    const SizedBox(width: 8),
                    _PeriodButton(
                      title: 'سنة',
                      isSelected: _selectedPeriodIndex == 3,
                      onTap: () => setState(() => _selectedPeriodIndex = 3),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Smart Vision Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'رؤية ذكية',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profitMargin > 0 
                            ? 'هامش الربح تحسّن بنسبة ${profitMargin.toStringAsFixed(1)}% خلال هذه الفترة بناءً على مبيعاتك ومصروفاتك.'
                            : 'لا يوجد هامش ربح إيجابي في هذه الفترة، حاول تقليل المصروفات.',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.sparkles,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Line Chart (Profit and Cost)
            const Text(
              'الربح والتكلفة (تقريبي)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineSoft),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxLineY / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.outlineSoft,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox();
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxLineY / 4,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox();
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 5,
                  minY: 0,
                  maxY: maxLineY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: profitSpots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bar Chart (Previous days sales)
            const Text(
              'مبيعات الأيام السابقة',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineSoft),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMaxY,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: chartMaxY / 4,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox();
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartMaxY / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.outlineSoft,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeBarData(0, dailySales[0]),
                    _makeBarData(1, dailySales[1]),
                    _makeBarData(2, dailySales[2]),
                    _makeBarData(3, dailySales[3]),
                    _makeBarData(4, dailySales[4]),
                    _makeBarData(5, dailySales[5]),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  BarChartGroupData _makeBarData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primaryLight,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lavender : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineSoft,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
