import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../sales/models/cashbook_entry.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import 'cashbook_entry_detail_screen.dart';
import 'cash_entry_screen.dart';
import 'package:safi/core/router/app_page_route.dart';

class CashFlowScreen extends ConsumerWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void push(Widget w) {
      Navigator.push<void>(context, AppPageRoute<void>(builder: (_) => w));
    }

    final summary = ref.watch(cashbookSummaryProvider);
    final entries = ref.watch(cashbookEntriesProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        24,
      ),
      children: [
        _MetricsStrip(
          balance: formatShekelAmount(summary.balance),
          income: formatShekelAmount(summary.income),
          expense: formatShekelAmount(summary.expense),
        ),
        const SizedBox(height: 18),
        _PrimaryActions(
          onIncome: () => push(const CashEntryScreen(initialIncome: true)),
          onExpense: () => push(const CashEntryScreen(initialIncome: false)),
        ),
        const SizedBox(height: 22),
        Text(
          'آخر المعاملات',
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 10),
        _TransactionsList(
          entries: entries,
          onOpen: (e) {
            Navigator.push<void>(
              context,
              AppPageRoute<void>(
                builder: (_) => CashbookEntryDetailScreen(entry: e),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── شريط الأرقام الثلاث (مثل دفتر الديون) ──
class _MetricsStrip extends StatelessWidget {
  const _MetricsStrip({
    required this.balance,
    required this.income,
    required this.expense,
  });

  final String balance;
  final String income;
  final String expense;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCell(
            label: 'الصافي',
            value: '$balance ₪',
            icon: LucideIcons.wallet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCell(
            label: 'الدخل',
            value: '$income ₪',
            icon: LucideIcons.trendingUp,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCell(
            label: 'المصروف',
            value: '$expense ₪',
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
String _dateLine(DateTime d) {
  final now = DateTime.now();
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return 'اليوم ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  return '${d.day}/${d.month}/${d.year}';
}

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({required this.entries, required this.onOpen});

  final List<CashbookEntry> entries;
  final void Function(CashbookEntry e) onOpen;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptyState();
    }
    return Column(
      children: [
        for (final t in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TransactionCard(
              item: t,
              onTap: () => onOpen(t),
            ),
          ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.item, required this.onTap});
  final CashbookEntry item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = item.isIncome ? AppColors.success : AppColors.error;
    final amount = formatShekelAmount(item.amount);
    return Material(
      color: AppColors.backgroundSecondary,
      borderRadius: AppRadius.rlg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rlg,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: AppRadius.rlg,
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: (!kIsWeb &&
                      item.imagePath != null &&
                      item.imagePath!.isNotEmpty)
                  ? Image.file(
                      File(item.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      item.isIncome
                          ? LucideIcons.trendingUp
                          : LucideIcons.trendingDown,
                      size: 18,
                      color: color,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.category != null && item.category!.isNotEmpty)
                    Text(
                      item.category!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    _dateLine(item.date),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${item.isIncome ? '+' : '-'} $amount ₪',
                style: AppTextStyles.titleSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        ),
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
