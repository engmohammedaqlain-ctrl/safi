import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/ai_insight_card.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/reports_ui_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key, this.bottomContentPadding = 100});

  final double bottomContentPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spots = ref.watch(pnlSpotsProvider);
    final bars = ref.watch(salesBarsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          bottomContentPadding,
        ),
        children: [
          // ── فلترة الأداء ──
          _SectionLabel('الفترة الزمنية'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final label in ['اليوم', 'أسبوع', 'شهر', 'سنة'])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: FilterChip(
                      label: Text(label),
                      selected: label == 'أسبوع',
                      onSelected: (_) {},
                      showCheckmark: false,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundColor: AppColors.backgroundSecondary,
                      side: BorderSide(
                        color: label == 'أسبوع'
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : AppColors.outlineSoft,
                      ),
                      labelStyle: AppTextStyles.labelMedium.copyWith(
                        color: label == 'أسبوع'
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: label == 'أسبوع'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── ملخص ذكي ──
          const AiInsightCard(
            message:
                'هامش الربح تحسّن 8٪ عن الأسبوع الماضي مع ثبات تكاليف المخزون.',
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── الأرباح والخسائر ──
          _SectionLabel('الربح والتكلفة (تقريبي)'),
          GlassCard(
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 8,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (v) {
                      return FlLine(
                        color: AppColors.outlineSoft,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      );
                    },
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── المبيعات ──
          _SectionLabel('مبيعات الأيام السابقة'),
          GlassCard(
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 12,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: AppColors.outlineSoft, dashArray: [4, 4]),
                  ),
                  barGroups: bars,
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}
