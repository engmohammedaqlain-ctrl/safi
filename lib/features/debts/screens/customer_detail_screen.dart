import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safi_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../ai_assistant/screens/ai_assistant_screen.dart';
import '../providers/debts_ui_provider.dart';
import 'add_debt_screen.dart';
import 'record_payment_screen.dart';

/// صفحة عميل: كل المعلومات + رسالة AI (بعيداً عن البطاقة المختصرة)
class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.debtor});

  final DebtorUi debtor;

  @override
  Widget build(BuildContext context) {
    final c = urgencyToColor(debtor.urgency);
    return Scaffold(
      appBar: AppBar(
        title: Text(debtor.name, style: AppTextStyles.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Icon(LucideIcons.user, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(debtor.name, style: AppTextStyles.titleMedium),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.phone,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                debtor.phone,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    StatusPill(label: debtor.status, color: c),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text('إجمالي المستحق', style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                Text(
                  '₪ ${debtor.amount}',
                  style: AppTextStyles.headlineSmall.copyWith(color: c),
                ),
                const SizedBox(height: 8),
                Text(
                  'تُحدَّث الأرقام تلقائياً عند تسجيل دين أو دفعة.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('سجل سريع', style: AppTextStyles.titleSmall),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              children: [
                _TimelineRow(
                  icon: LucideIcons.plus,
                  color: AppColors.error,
                  title: 'دين — شراء',
                  subtitle: 'منذ 12 يوم',
                  amount: '₪ 1,100',
                ),
                const Divider(height: 20),
                _TimelineRow(
                  icon: LucideIcons.minus,
                  color: AppColors.success,
                  title: 'سداد — نقد',
                  subtitle: 'منذ 8 أيام',
                  amount: '₪ 250',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AddDebtScreen(forCustomer: debtor),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.userPlus, size: 20),
                  label: const Text('تسجيل دين'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => RecordPaymentScreen(forCustomer: debtor),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.banknote, size: 20),
                  label: const Text('تسجيل دفعة'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SafiButton(
            label: 'رسالة AI للزبون',
            icon: LucideIcons.sparkles,
            variant: SafiButtonVariant.ai,
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const AiAssistantScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'صياغة تذكير ودّي بخصوص المستحق (قابل للتعديل داخل المساعد).',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.rmd,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleSmall),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Text(amount, style: AppTextStyles.numberMedium),
      ],
    );
  }
}
