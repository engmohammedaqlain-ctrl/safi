import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/ai_insight_card.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/metric_stat_card.dart';
import '../providers/home_ui_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.bottomContentPadding = 100});

  final double bottomContentPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(homeMetricsProvider);
    final insight = ref.watch(homeInsightProvider);
    final w = MediaQuery.sizeOf(context).width;
    final crossAxis = w > 800 ? 3 : (w > 500 ? 2 : 1);

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          bottomContentPadding,
        ),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: metrics.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxis,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 148,
            ),
            itemBuilder: (context, i) => MetricStatCard(data: metrics[i]),
          ),
          const SizedBox(height: 16),

          // ── رؤية ذكية ──
          AiInsightCard(message: insight),
          const SizedBox(height: 20),

          // ── آخر العمليات ──
          Text(
            'آخر العمليات',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _TxRow(
                  icon: LucideIcons.shoppingBag,
                  label: 'بيع — نقد',
                  value: '₪ 86',
                  color: AppColors.success,
                ),
                const Divider(height: 1, indent: 52),
                _TxRow(
                  icon: LucideIcons.wallet,
                  label: 'دفعة دين',
                  value: '₪ 350',
                  color: AppColors.success,
                ),
                const Divider(height: 1, indent: 52),
                _TxRow(
                  icon: LucideIcons.shoppingCart,
                  label: 'مشتريات',
                  value: '₪ 1,200',
                  color: AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.rmd,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(value, style: AppTextStyles.numberMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}
