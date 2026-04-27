import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/main_shell.dart' show hideBalanceProvider;
import '../../../core/theme/app_colors.dart';
import '../../cash_flow/screens/cash_entry_screen.dart';
import '../../cash_flow/screens/cash_flow_screen.dart';
import '../../cash_flow/screens/financial_accounts_screen.dart';
import '../models/cashbook_entry.dart';
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
    final entries = ref.watch(cashbookEntriesProvider);
    final hidden = ref.watch(hideBalanceProvider);

    void push(Widget page) {
      Navigator.push<void>(
        context,
        AppPageRoute<void>(builder: (_) => page),
      );
    }

    final balAmt = hidden ? obscureAmountText() : formatShekelAmount(summary.balance);
    final incAmt = hidden ? obscureAmountText() : formatShekelAmount(summary.income);
    final outAmt = hidden ? obscureAmountText() : formatShekelAmount(summary.expense);

    // يضمن ترتيب العناصر من اليمين لليسار حتى داخل الـ ListView
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          children: [
            _BalanceCard(
              balanceAmount: balAmt,
              incomeAmount: incAmt,
              expenseAmount: outAmt,
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

            if (entries.isEmpty)
              const _EmptyTransactions()
            else
              ...entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CashbookTile(
                    entry: e,
                    hideAmount: hidden,
                    onDelete: () {
                      ref
                          .read(cashbookEntriesProvider.notifier)
                          .removeById(e.id);
                    },
                  ),
                ),
              ),
          ],
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
    required this.balanceAmount,
    required this.incomeAmount,
    required this.expenseAmount,
    required this.onIncome,
    required this.onExpense,
  });

  /// رقم أو نقاط فقط — يُلحق ₪ بعد الرقم في الواجهة
  final String balanceAmount;
  final String incomeAmount;
  final String expenseAmount;
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
      // RTL: CrossAxisAlignment.start = محاذاة كل المحتوى من نفس الحافة اليمين
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: double.infinity,
            child: Text(
              'الصافي',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _ShekelAmountLine(
            amount: balanceAmount,
            valueColor: incomeColor,
            numberStyle: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
            alignEnd: true,
          ),
          const SizedBox(height: 10),
          _MetricLine(
            label: 'الدخل',
            amount: incomeAmount,
            valueColor: incomeColor,
          ),
          const SizedBox(height: 4),
          _MetricLine(
            label: 'المصروف',
            amount: expenseAmount,
            valueColor: expenseValColor,
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

/// سطر: «الدخل:» ثم [رقم][₪] بترتيب LTR واضح
class _MetricLine extends StatelessWidget {
  const _MetricLine({
    required this.label,
    required this.amount,
    required this.valueColor,
  });

  final String label;
  final String amount;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          _ShekelAmountLine(
            amount: amount,
            valueColor: valueColor,
            numberStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            alignEnd: false,
          ),
        ],
      ),
    );
  }
}

/// رقم + ₪ دائماً بهذا الترتيب (عدد ثم عملة) داخل bidi
class _ShekelAmountLine extends StatelessWidget {
  const _ShekelAmountLine({
    required this.amount,
    required this.valueColor,
    required this.numberStyle,
    required this.alignEnd,
  });

  final String amount;
  final Color valueColor;
  final TextStyle numberStyle;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final n = numberStyle.copyWith(color: valueColor);
    final block = Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          Text(amount, style: n),
          Text(' ₪', style: n),
        ],
      ),
    );
    if (alignEnd) {
      return SizedBox(
        width: double.infinity,
        child: Align(alignment: Alignment.centerRight, child: block),
      );
    }
    return block;
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
//  سطر في قائمة دفتر النقدية
// ════════════════════════════════════════════════════════════════
String _formatCashDate(DateTime d) {
  final now = DateTime.now();
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return 'اليوم ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  return '${d.day}/${d.month}/${d.year}';
}

class _CashbookTile extends StatelessWidget {
  const _CashbookTile({
    required this.entry,
    required this.hideAmount,
    required this.onDelete,
  });

  final CashbookEntry entry;
  final bool hideAmount;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = entry.isIncome ? Colors.green : Colors.deepOrange;
    final amountStr = hideAmount
        ? obscureAmountText()
        : formatShekelAmount(entry.amount);
    return Material(
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            IconButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('حذف المعاملة؟'),
                    content: const Text('لن يُسترجع المبلغ من الصافي.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onDelete();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(LucideIcons.trash2, size: 18, color: Colors.grey.shade500),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                entry.isIncome ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                color: c,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatCashDate(entry.date),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _ShekelAmountLine(
              amount: amountStr,
              valueColor: c,
              numberStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              alignEnd: false,
            ),
          ],
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
