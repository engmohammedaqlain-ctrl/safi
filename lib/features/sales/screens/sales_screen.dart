import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../cash_flow/screens/cash_entry_screen.dart';
import '../../cash_flow/screens/cash_flow_screen.dart';
import '../../cash_flow/screens/financial_accounts_screen.dart';
import '../providers/cashbook_ui_provider.dart';
import 'new_sale_screen.dart';

/// دفتر النقدية — تصميم متسق مع دفتر الديون
class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key, this.bottomInset = 0});

  final double bottomInset;

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  bool _hide = false;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(cashbookSummaryProvider);
    final bottomPad = 12.0 + widget.bottomInset;

    void push(Widget page) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
      );
    }

    final bal = _hide ? obscureMoney() : formatMAD(summary.balance);
    final inc = _hide ? obscureMoney() : formatMAD(summary.income);
    final out = _hide ? obscureMoney() : formatMAD(summary.expense);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              bottomPad,
            ),
            children: [
              // ── شريط الأرقام الثلاثة — مطابق للديون ──

              // ── شريط الأرقام الثلاثة — مطابق للديون ──
              Row(
                children: [
                  Expanded(
                    child: _MetricCell(
                      label: 'الرصيد',
                      value: bal,
                      icon: LucideIcons.wallet,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCell(
                      label: 'الدخل',
                      value: inc,
                      icon: LucideIcons.trendingUp,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCell(
                      label: 'المصروف',
                      value: out,
                      icon: LucideIcons.trendingDown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── إدارة المحافظ والحسابات ──
              Material(
                color: AppColors.backgroundSecondary,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    color: AppColors.outlineSoft,
                    width: 1,
                  ),
                  borderRadius: AppRadius.rmd,
                ),
                child: InkWell(
                  onTap: () => push(const FinancialAccountsScreen()),
                  borderRadius: AppRadius.rmd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                LucideIcons.wallet,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إدارة الحسابات والمحافظ',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'البنوك، الكاش، المحافظ الإلكترونية',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Icon(
                          LucideIcons.chevronLeft,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── زر نقطة البيع POS (مهم جداً) ──
              _CtaBlock(
                background: AppColors.aiPurple,
                onTap: () => push(const NewSaleScreen()),
                icon: LucideIcons.shoppingCart,
                label: 'نقطة البيع (POS)',
                subtitle: 'الكاشير وإدارة الطلبات السريعة',
              ),
              const SizedBox(height: 12),

              // ── زرّا الإجراء الرئيسيان — مطابق للديون ──
              Row(
                children: [
                  Expanded(
                    child: _CtaBlock(
                      background: AppColors.primary,
                      onTap: () =>
                          push(const CashEntryScreen(initialIncome: true)),
                      icon: LucideIcons.plus,
                      label: '+ دخل',
                      subtitle: 'إيراد أو وارد',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CtaBlock(
                      background: AppColors.primaryDark,
                      onTap: () =>
                          push(const CashEntryScreen(initialIncome: false)),
                      icon: LucideIcons.minus,
                      label: '- مصروف',
                      subtitle: 'نفقة أو صادر',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ── روابط سريعة ──
              Row(
                children: [
                  Expanded(
                    child: _SecondaryAction(
                      icon: LucideIcons.archive,
                      label: 'أرشيف\nالمعاملات',
                      onTap: () => push(const CashFlowScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SecondaryAction(
                      icon: LucideIcons.lineChart,
                      label: 'التقارير',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تقرير مفصّل — قريباً'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SecondaryAction(
                      icon: LucideIcons.briefcase,
                      label: 'إنهاء\nالوردية',
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('إنهاء الوردية'),
                            content: const Text(
                              'هل تريد إغلاق جلسة الوردية؟ (تجريبي)',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('إلغاء'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('تأكيد'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SecondaryAction(
                      icon: _hide ? LucideIcons.eye : LucideIcons.eyeOff,
                      label: _hide ? 'إظهار\nالأرقام' : 'إخفاء\nالأرقام',
                      onTap: () => setState(() => _hide = !_hide),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── المعاملات ──
              Text(
                'المعاملات (${summary.transactionCount})',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 14),
              _EmptyStateCard(
                onRecordHint: () =>
                    push(const CashEntryScreen(initialIncome: true)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── بطاقة رقم ملخص — مطابقة تماماً لما في الديون ──
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
                child: Icon(icon, size: 17, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 14,
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

// (SubAccountCell was removed because accounts are now managed via FinancialAccountsScreen)

// ── زر CTA كبير ملوّن — نفس _CtaBlock في الديون ──
class _CtaBlock extends StatelessWidget {
  const _CtaBlock({
    required this.background,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final Color background;
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 110),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
                  color: AppColors.onPrimary.withValues(alpha: 0.85),
                  fontSize: 11,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── إجراء ثانوي (أيقونة صغيرة + نص) ──
class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBF0),
              borderRadius: AppRadius.rmd,
              border: Border.all(
                color: AppColors.textMuted.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 22),
          ),
          const SizedBox(height: 6),
          Container(
            height: 38,
            alignment: Alignment.topCenter,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── حالة فارغة ──
class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.onRecordHint});

  final VoidCallback onRecordHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rlg,
        border: Border.all(color: AppColors.outlineSoft),
      ),
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
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRecordHint,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('تسجيل أول وارد'),
          ),
        ],
      ),
    );
  }
}
