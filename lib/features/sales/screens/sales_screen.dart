import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/main_shell.dart' show hideBalanceProvider;
import '../../../core/theme/app_colors.dart';
import '../../cash_flow/screens/cash_entry_screen.dart';
import '../../cash_flow/screens/cashbook_entry_detail_screen.dart';
import '../../cash_flow/screens/cash_flow_screen.dart';
import '../../cash_flow/screens/financial_accounts_screen.dart';
import '../models/cashbook_entry.dart';
import '../providers/cashbook_ui_provider.dart';
import 'package:safi/core/router/app_page_route.dart';

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
            const SizedBox(height: 12),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _TopCardAction(
                    icon: LucideIcons.wallet,
                    label: 'المحافظ',
                    onTap: () => push(const FinancialAccountsScreen()),
                    compact: true,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: _TopCardAction(
                    icon: LucideIcons.inbox,
                    label: 'الأرشيف',
                    onTap: () => push(const CashFlowScreen()),
                    compact: true,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: _TopCardAction(
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
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

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
                    onOpen: () {
                      Navigator.push<void>(
                        context,
                        AppPageRoute<void>(
                          builder: (_) => CashbookEntryDetailScreen(entry: e),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
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
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1) ملخّص الصافي
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'الصافي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
                alignEnd: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 2) تفصيل دخل / مصروف
          _CardIncomeExpenseRow(
            incomeAmount: incomeAmount,
            expenseAmount: expenseAmount,
            incomeColor: incomeColor,
            expenseColor: expenseValColor,
          ),
          const SizedBox(height: 16),
          // 3) تسجيل دخل / مصروف
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.center,
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

/// صف دخل/مصروف داخل بطاقة الصافي — متماثل ومركز
class _CardIncomeExpenseRow extends StatelessWidget {
  const _CardIncomeExpenseRow({
    required this.incomeAmount,
    required this.expenseAmount,
    required this.incomeColor,
    required this.expenseColor,
  });

  final String incomeAmount;
  final String expenseAmount;
  final Color incomeColor;
  final Color expenseColor;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String amount, Color c) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _ShekelAmountLine(
            amount: amount,
            valueColor: c,
            numberStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            alignEnd: false,
          ),
        ],
      );
    }

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(child: cell('الدخل', incomeAmount, incomeColor)),
        Container(
          width: 1,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: Colors.grey.shade200,
        ),
        Expanded(child: cell('المصروف', expenseAmount, expenseColor)),
      ],
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
//  أيقونات أعلى بطاقة الصافي (مضغوطة)
// ════════════════════════════════════════════════════════════════
class _TopCardAction extends StatelessWidget {
  const _TopCardAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final box = compact ? 36.0 : 44.0;
    final iconSize = compact ? 19.0 : 22.0;
    final fontSize = compact ? 8.5 : 10.0;
    const actionWidth = 88.0;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: iconSize, color: AppColors.primary),
        ),
        SizedBox(height: compact ? 3 : 4),
        Text(
          label,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: compact
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: content,
              )
            : SizedBox(
                width: actionWidth,
                child: content,
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
    required this.onOpen,
  });

  final CashbookEntry entry;
  final bool hideAmount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = entry.isIncome ? Colors.green : Colors.deepOrange;
    final amountStr = hideAmount
        ? obscureAmountText()
        : formatShekelAmount(entry.amount);
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onOpen,
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: (!kIsWeb &&
                      entry.imagePath != null &&
                      entry.imagePath!.isNotEmpty)
                  ? Image.file(
                      File(entry.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      entry.isIncome
                          ? LucideIcons.trendingUp
                          : LucideIcons.trendingDown,
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
                  if (entry.category != null && entry.category!.isNotEmpty)
                    Text(
                      entry.category!,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
