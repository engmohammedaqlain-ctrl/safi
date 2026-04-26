import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/safi_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../ai_assistant/screens/ai_assistant_screen.dart';
import '../providers/debts_ui_provider.dart';
import 'add_debt_screen.dart';
import 'record_payment_screen.dart';

/// ملف عميل — تخطيط وثائقي نظيف: رصيد، إجراءات سريعة، سجل، أزرار سفلية
class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.debtor});

  final DebtorUi debtor;

  @override
  Widget build(BuildContext context) {
    final c = urgencyToColor(debtor.urgency);
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text(
          debtor.name,
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          120,
        ),
        children: [
          Text(
            'اضغط هنا لنسخ رقم الجوال',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: debtor.phone));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ رقم الجوال')),
                );
              },
              borderRadius: AppRadius.rmd,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  debtor.phone,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: AppRadius.rxl,
              border: Border.all(color: AppColors.outlineSoft),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'الرصيد / المستحق',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₪ ${debtor.amount}',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: c,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                StatusPill(label: debtor.status, color: c),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'إجراءات سريعة',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickCircle(
                icon: LucideIcons.fileText,
                label: 'ملاحظة',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الملاحظات قريباً')),
                  );
                },
              ),
              _QuickCircle(
                icon: LucideIcons.phone,
                label: 'اتصال',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('اربط تطبيق الهاتف لاحقاً للاتصال المباشر'),
                    ),
                  );
                },
              ),
              _QuickCircle(
                icon: LucideIcons.share2,
                label: 'مشاركة',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('مشاركة الملخص قريباً')),
                  );
                },
              ),
              _QuickCircle(
                icon: LucideIcons.barChart2,
                label: 'تقرير',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('التقارير من تبويب المزيد')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'سجل حركات',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: AppRadius.rlg,
              border: Border.all(color: AppColors.outlineSoft),
            ),
            child: Column(
              children: [
                _TxRow(
                  side: 'دين',
                  time: 'منذ 12 يوم',
                  amount: '₪ 1,100',
                  isOut: true,
                ),
                Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.6)),
                _TxRow(
                  side: 'سداد',
                  time: 'منذ 8 أيام',
                  amount: '₪ 250',
                  isOut: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 6),
          Center(
            child: Text(
              'تذكير ودّي بخصوص المستحق — يُعدّل داخل المساعد',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        color: AppColors.backgroundSecondary,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => AddDebtScreen(forCustomer: debtor),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lavenderDeep.withValues(alpha: 0.35),
                      foregroundColor: AppColors.plum,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.rmd,
                        side: BorderSide(color: AppColors.plum.withValues(alpha: 0.2)),
                      ),
                    ),
                    child: const Text(
                      'تسجيل دين',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              RecordPaymentScreen(forCustomer: debtor),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lavender,
                      foregroundColor: AppColors.flowIn,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.rmd,
                      ),
                    ),
                    child: const Text(
                      'تسجيل دفعة',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickCircle extends StatelessWidget {
  const _QuickCircle({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rmd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: AppRadius.rmd,
              border: Border.all(color: AppColors.outlineSoft),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({
    required this.side,
    required this.time,
    required this.amount,
    required this.isOut,
  });

  final String side;
  final String time;
  final String amount;
  final bool isOut;

  @override
  Widget build(BuildContext context) {
    final amtColor = isOut ? AppColors.flowOut : AppColors.flowIn;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Text(
            amount,
            style: AppTextStyles.titleSmall.copyWith(
              color: amtColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(side, style: AppTextStyles.titleSmall),
              Text(
                time,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
