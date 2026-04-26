import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../cash_flow/screens/cash_entry_screen.dart';
import '../../cash_flow/screens/cash_flow_screen.dart';
import '../providers/cashbook_ui_provider.dart';
import 'new_sale_screen.dart';

/// دفتر النقدية — واجهة مثل «نظيفة/وثائقية» مع هوية أرجوانية
class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key, this.bottomInset = 0});

  final double bottomInset;

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  bool _hide = false;
  bool _showDrawerHint = true;

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

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              _DashboardHeader(
                userName: summary.userName,
                onToggleHide: () => setState(() => _hide = !_hide),
                hide: _hide,
                onQuickReport: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('التقارير — قريباً'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onRefreshMock: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم التحديث'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _BalanceCard(
                summary: summary,
                hide: _hide,
                onIncome: () =>
                    push(const CashEntryScreen(initialIncome: true)),
                onExpense: () =>
                    push(const CashEntryScreen(initialIncome: false)),
              ),
              const SizedBox(height: 20),
              _QuickActionsRow(
                onArchive: () => push(const CashFlowScreen()),
                onReports: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تقرير مفصّل — نربطه لاحقاً'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onEndSession: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('إنهاء الوردية'),
                      content: const Text(
                        'هل تريد إغلاق تسجيل جلسة الوردية؟ (تجريبي)',
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
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => push(const NewSaleScreen()),
                icon: const Icon(LucideIcons.shoppingCart, size: 18),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                label: const Text('فتح نقطة بيع المنتجات'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'المعاملات (${summary.transactionCount})',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _EmptyStateIllustration(
                onRecordHint: () =>
                    push(const CashEntryScreen(initialIncome: true)),
              ),
              SizedBox(height: 16 + bottomPad),
            ],
          ),
        ),
        if (_showDrawerHint)
          _DrawerHintBar(
            onClose: () => setState(() => _showDrawerHint = false),
          ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.userName,
    required this.onToggleHide,
    required this.onQuickReport,
    required this.onRefreshMock,
    required this.hide,
  });

  final String userName;
  final bool hide;
  final VoidCallback onToggleHide;
  final VoidCallback onQuickReport;
  final VoidCallback onRefreshMock;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SquareIcon(
              onTap: onToggleHide,
              child: Icon(
                hide ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            _SquareIcon(
              onTap: onQuickReport,
              child: const Icon(
                LucideIcons.barChart2,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            _SquareIcon(
              onTap: onRefreshMock,
              child: const Icon(
                LucideIcons.refreshCw,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          userName,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.lavender,
            borderRadius: AppRadius.rmd,
            border: Border.all(color: AppColors.outlineSoft),
          ),
          child: const Icon(
            LucideIcons.bookOpen,
            color: AppColors.primary,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lavender,
      borderRadius: AppRadius.rmd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rmd,
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.summary,
    required this.hide,
    required this.onIncome,
    required this.onExpense,
  });

  final CashbookSummary summary;
  final bool hide;
  final VoidCallback onIncome;
  final VoidCallback onExpense;

  @override
  Widget build(BuildContext context) {
    final bal = hide ? obscureMoney() : formatMAD(summary.balance);
    final inc = hide ? obscureMoney() : formatMAD(summary.income);
    final out = hide ? obscureMoney() : formatMAD(summary.expense);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rlg,
        boxShadow: [
          BoxShadow(
            color: AppColors.plum.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.outlineSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: Text(
              'الرصيد',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bal,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.violet,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المصروف: $out',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'الدخل: $inc',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PillPairedButton(
                  label: '− مصروف',
                  background: AppColors.errorLight,
                  foreground: AppColors.error,
                  onPressed: onExpense,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PillPairedButton(
                  label: '+ دخل',
                  background: AppColors.successLight,
                  foreground: AppColors.success,
                  onPressed: onIncome,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillPairedButton extends StatelessWidget {
  const _PillPairedButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rmd),
        elevation: 0,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onArchive,
    required this.onReports,
    required this.onEndSession,
  });

  final VoidCallback onArchive;
  final VoidCallback onReports;
  final VoidCallback onEndSession;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickAction(
          label: 'أرشيف\nالمعاملات',
          icon: LucideIcons.archive,
          onTap: onArchive,
        ),
        _QuickAction(
          label: 'التقارير',
          icon: LucideIcons.lineChart,
          onTap: onReports,
        ),
        _QuickAction(
          label: 'إنهاء',
          icon: LucideIcons.briefcase,
          onTap: onEndSession,
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEF5),
              borderRadius: AppRadius.rmd,
              border: Border.all(color: const Color(0xFFDEDAEB)),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateIllustration extends StatelessWidget {
  const _EmptyStateIllustration({required this.onRecordHint});

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
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(
                LucideIcons.bookOpen,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.85),
              ),
              Positioned(
                top: -4,
                right: 24,
                child: _MiniBadge('−', AppColors.plum),
              ),
              Positioned(
                bottom: 8,
                left: 20,
                child: _MiniBadge('+', AppColors.violet),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد معاملات بعد. سجّل عمليات الدخول والخروج النقدي',
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

class _MiniBadge extends StatelessWidget {
  const _MiniBadge(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _DrawerHintBar extends StatelessWidget {
  const _DrawerHintBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warningLight,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.warning.withValues(alpha: 0.35)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onClose,
                icon: const Icon(LucideIcons.x, size: 20),
                color: AppColors.warning,
                tooltip: 'إغلاق',
              ),
              Expanded(
                child: Text(
                  'لا يمكنك إغلاق الدرج بدون عمليات',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                LucideIcons.alertCircle,
                color: AppColors.warning,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
