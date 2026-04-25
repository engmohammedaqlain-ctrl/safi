import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/ai_insight_card.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/metric_stat_card.dart';
import '../providers/home_ui_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(homeMetricsProvider);
    final insight = ref.watch(homeInsightProvider);
    final w = MediaQuery.sizeOf(context).width;
    final crossAxis = w > 800 ? 3 : (w > 500 ? 2 : 1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        100,
      ),
      children: [
        Text('لوحة التحكم', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 6),
        Text('نظرة سريعة على يومك', style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        AiInsightCard(message: insight),
        const SizedBox(height: AppSpacing.lg),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxis,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 158,
          ),
          itemBuilder: (context, i) => MetricStatCard(data: metrics[i]),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('آخر العمليات', style: AppTextStyles.titleSmall),
              const SizedBox(height: 10),
              const _TransactionRow(
                label: 'بيع — نقد',
                value: '₪ 86',
              ),
              Divider(height: 20, color: AppColors.textMuted.withValues(alpha: 0.2)),
              const _TransactionRow(
                label: 'دفعة دين',
                value: '₪ 350',
              ),
              Divider(height: 20, color: AppColors.textMuted.withValues(alpha: 0.2)),
              const _TransactionRow(
                label: 'مشتريات',
                value: '₪ 1,200',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMedium),
        ),
        Text(
          value,
          style: AppTextStyles.numberMedium,
        ),
      ],
    );
  }
}