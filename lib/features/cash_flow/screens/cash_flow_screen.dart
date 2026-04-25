import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safi_button.dart';
import 'cash_entry_screen.dart';

class CashFlowScreen extends StatelessWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التدفق المالي'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'المدخلات والمصروفات',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'مخطط مبسّط — الربط مع Firebase لاحقاً (first_plan)',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _FlowMini(
                  label: 'مدخلات',
                  value: '₪ 12,400',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FlowMini(
                  label: 'مصروفات',
                  value: '₪ 3,100',
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('صافي التدفق', style: AppTextStyles.titleSmall),
                const SizedBox(height: 6),
                Text('₪ 9,300', style: AppTextStyles.numberLarge),
                const SizedBox(height: 8),
                Text(
                  'تنبيه: الحد الأدنى للسيولة ₪ 2,000',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SafiButton(
                  label: 'وارد',
                  icon: LucideIcons.plus,
                  variant: SafiButtonVariant.secondary,
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const CashEntryScreen(
                          initialIncome: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SafiButton(
                  label: 'صادر',
                  icon: LucideIcons.minus,
                  variant: SafiButtonVariant.outline,
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const CashEntryScreen(
                          initialIncome: false,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowMini extends StatelessWidget {
  const _FlowMini({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      background: color.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.numberMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
