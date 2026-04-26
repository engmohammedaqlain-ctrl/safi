import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/reports_ui_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key, this.bottomContentPadding = 100});

  final double bottomContentPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spots = ref.watch(pnlSpotsProvider);
    final bars = ref.watch(salesBarsProvider);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        bottomContentPadding,
      ),
      children: [
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
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.sparkles,
                    color: AppColors.aiPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text('ملخّص ذكي', style: AppTextStyles.titleSmall),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'هامش الربح تحسّن 8٪ عن الأسبوع الماضي مع ثبات تكاليف المخزون.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الربح والخسارة (تقريب)', style: AppTextStyles.titleSmall),
              const SizedBox(height: 12),
              SizedBox(
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
                          color: AppColors.outline.withValues(alpha: 0.5),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3.5,
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withValues(alpha: 0.12),
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
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مبيعات حسب اليوم', style: AppTextStyles.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: 12,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: AppColors.outline.withValues(alpha: 0.35),
                      ),
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
            ],
          ),
        ),
      ],
    );
  }
}
