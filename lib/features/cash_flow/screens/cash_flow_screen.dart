import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'cash_entry_screen.dart';

class CashFlowScreen extends StatelessWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void push(Widget w) {
      Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => w));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        24,
      ),
      children: [
        // ── ملخص ──
        Text(
          'ملخص',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.35,
          ),
        ),
        const SizedBox(height: 10),
        _MetricsStrip(),
        const SizedBox(height: 18),

        // ── أزرار الإجراءات ──
        _PrimaryActions(
          onIncome: () => push(const CashEntryScreen(initialIncome: true)),
          onExpense: () => push(const CashEntryScreen(initialIncome: false)),
        ),
        const SizedBox(height: 22),

        // ── آخر المعاملات ──
        Text(
          'آخر المعاملات',
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 10),
        _TransactionsList(),
      ],
    );
  }
}

// ── شريط الأرقام الثلاث (مثل دفتر الديون) ──
class _MetricsStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCell(
            label: 'الرصيد',
            value: 'MAD 0.0',
            icon: LucideIcons.wallet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCell(
            label: 'الدخل',
            value: 'MAD 0.0',
            icon: LucideIcons.trendingUp,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCell(
            label: 'المصروف',
            value: 'MAD 0.0',
            icon: LucideIcons.trendingDown,
          ),
        ),
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: AppRadius.rlg,
        border: Border.all(
          color: AppColors.textMuted.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEBF0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── أزرار الإجراءات الرئيسية — مطابقة لنمط دفتر الديون ──
class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({required this.onIncome, required this.onExpense});

  final VoidCallback onIncome;
  final VoidCallback onExpense;

  static const _tileRadius = 18.0;
  static const _tileH = 100.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CtaBlock(
            height: _tileH,
            radius: _tileRadius,
            background: AppColors.primary,
            onTap: onIncome,
            icon: LucideIcons.plus,
            label: '+ دخل',
            subtitle: 'إيراد أو وارد',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CtaBlock(
            height: _tileH,
            radius: _tileRadius,
            background: AppColors.primaryDark,
            onTap: onExpense,
            icon: LucideIcons.minus,
            label: '- مصروف',
            subtitle: 'نفقة أو صادر',
          ),
        ),
      ],
    );
  }
}

class _CtaBlock extends StatelessWidget {
  const _CtaBlock({
    required this.height,
    required this.radius,
    required this.background,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final double height;
  final double radius;
  final Color background;
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(radius),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: AppColors.onPrimary),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.9),
                    fontSize: 11,
                    height: 1.1,
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

// ── قائمة المعاملات ——————————————————————————————————————
class _TransactionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // بيانات تجريبية — ستُربط بـ Firebase لاحقاً
    final items = <_TxItem>[];

    if (items.isEmpty) {
      return _EmptyState();
    }

    return Column(
      children: items
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TransactionCard(item: t),
            ),
          )
          .toList(),
    );
  }
}

class _TxItem {
  const _TxItem({
    required this.label,
    required this.amount,
    required this.isIncome,
    required this.date,
  });
  final String label;
  final String amount;
  final bool isIncome;
  final String date;
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.item});
  final _TxItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isIncome ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: AppRadius.rlg,
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.isIncome ? LucideIcons.trendingUp : LucideIcons.trendingDown,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.date,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            (item.isIncome ? '+ ' : '- ') + item.amount,
            style: AppTextStyles.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEEECEF),
              borderRadius: AppRadius.rlg,
            ),
            child: const Icon(
              LucideIcons.bookOpen,
              size: 36,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد معاملات بعد',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'سجّل دخلاً أو مصروفاً من الأعلى لبدء المتابعة',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
