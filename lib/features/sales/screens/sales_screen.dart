import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/main_shell.dart' show hideBalanceProvider;
import '../../../core/theme/app_colors.dart';
import '../../cash_flow/screens/cash_entry_screen.dart';
import '../../cash_flow/screens/cash_flow_screen.dart';
import '../../cash_flow/screens/financial_accounts_screen.dart';
import '../providers/cashbook_ui_provider.dart';
import 'new_sale_screen.dart';
import 'package:safi/core/router/app_page_route.dart';

/// ظل ناعم موحّد مع بطاقة ملخص دفتر الديون
List<BoxShadow> _kCardShadow() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];

/// دفتر النقدية — نفس ألوان / ثيم صفحة الديون + تخطيط RTL
class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key, this.bottomInset = 0});

  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cashbookSummaryProvider);
    final hidden = ref.watch(hideBalanceProvider);

    void push(Widget page) {
      Navigator.push<void>(
        context,
        AppPageRoute<void>(builder: (_) => page),
      );
    }

    final balText = hidden ? obscureMoney() : formatMAD(summary.balance);
    final incText = hidden ? obscureMoney() : formatMAD(summary.income);
    final outText = hidden ? obscureMoney() : formatMAD(summary.expense);

    // يضمن ترتيب العناصر من اليمين لليسار حتى داخل الـ ListView
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 100 + bottomInset),
          children: [
            _BalanceCard(
              balanceText: balText,
              incomeText: incText,
              expenseText: outText,
              onIncome: () => push(const CashEntryScreen(initialIncome: true)),
              onExpense: () => push(const CashEntryScreen(initialIncome: false)),
            ),
            const SizedBox(height: 20),

            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: LucideIcons.inbox,
                    label: 'أرشيف المعاملات',
                    onTap: () => push(const CashFlowScreen()),
                  ),
                ),
                Expanded(
                  child: _QuickAction(
                    icon: LucideIcons.barChart2,
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
                Expanded(
                  child: _QuickAction(
                    icon: LucideIcons.briefcase,
                    label: 'إنهاء الوردية',
                    onTap: () => _confirmEndShift(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _LinkRow(
              icon: LucideIcons.wallet,
              title: 'إدارة الحسابات والمحافظ',
              subtitle: 'البنوك، الكاش، المحافظ الإلكترونية',
              onTap: () => push(const FinancialAccountsScreen()),
            ),
            const SizedBox(height: 8),
            _LinkRow(
              icon: LucideIcons.shoppingCart,
              title: 'نقطة البيع (POS)',
              subtitle: 'الكاشير وإدارة الطلبات السريعة',
              onTap: () => push(const NewSaleScreen()),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  'المعاملات (${summary.transactionCount})',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (summary.transactionCount == 0)
              const _EmptyTransactions()
            else
              const SizedBox.shrink(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Material(
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          child: FloatingActionButton.extended(
            onPressed: () => push(const CashEntryScreen(initialIncome: true)),
            backgroundColor: AppColors.primary,
            elevation: 0,
            highlightElevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            icon: const Icon(LucideIcons.plus, color: Colors.white),
            label: const Text(
              'إضافة معاملة',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmEndShift(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء الوردية'),
        content: const Text('هل تريد إغلاق جلسة الوردية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  بطاقة الرصيد — ألوان مثل سطور «أخذت / أعطيت» في دفتر الديون
// ════════════════════════════════════════════════════════════════
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balanceText,
    required this.incomeText,
    required this.expenseText,
    required this.onIncome,
    required this.onExpense,
  });

  final String balanceText;
  final String incomeText;
  final String expenseText;
  final VoidCallback onIncome;
  final VoidCallback onExpense;

  @override
  Widget build(BuildContext context) {
    // نفس ألوان سطور «أخذت / أعطيت» في debts_screen
    const incomeColor = Colors.green;
    const expenseValColor = Colors.deepOrange;
    final expenseCtaBg = AppColors.errorLight;
    const incomeCtaBg = AppColors.successLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _kCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'الرصيد',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              balanceText,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: incomeColor,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MiniMetric(
                  label: 'الدخل',
                  value: incomeText,
                  valueColor: incomeColor,
                ),
                const SizedBox(height: 4),
                _MiniMetric(
                  label: 'المصروف',
                  value: expenseText,
                  valueColor: expenseValColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _SoftCta(
                  label: '+ دخل',
                  bg: incomeCtaBg,
                  fg: incomeColor,
                  onTap: onIncome,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SoftCta(
                  label: '− مصروف',
                  bg: expenseCtaBg,
                  fg: expenseValColor,
                  onTap: onExpense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          value,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}

class _SoftCta extends StatelessWidget {
  const _SoftCta({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: fg.withValues(alpha: 0.1),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  إجراء سريع — مطابق لـ _ActionButton في debts_screen
// ════════════════════════════════════════════════════════════════
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  صف رابط
// ════════════════════════════════════════════════════════════════
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _kCardShadow(),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronLeft,
                color: Colors.grey.shade400,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  حالة فارغة
// ════════════════════════════════════════════════════════════════
class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: _kCardShadow(),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.bookOpen,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'لا توجد معاملات بعد',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'سجّل دخلاً أو مصروفاً لبدء المتابعة',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
