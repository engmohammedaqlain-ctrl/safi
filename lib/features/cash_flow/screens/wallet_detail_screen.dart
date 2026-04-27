import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:safi/core/router/app_page_route.dart';

import '../../../core/router/main_shell.dart' show hideBalanceProvider;
import '../../../core/theme/app_colors.dart';
import '../../sales/models/cashbook_entry.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../data/financial_account_model.dart';
import '../providers/accounts_provider.dart';
import 'cashbook_entry_detail_screen.dart';
import 'cash_entry_screen.dart';
import 'financial_accounts_screen.dart' show AccountFormScreen;

/// تفاصيل محفظة واحدة:
/// - بطاقة الرصيد + معلومات الحساب
/// - أزرار: + دخل / − مصروف
/// - أزرار ثانوية: تعديل / تقرير المحفظة / حذف
/// - قائمة الحركات (مفلترة بـ accountId)
class WalletDetailScreen extends ConsumerWidget {
  const WalletDetailScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final acc = accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => const FinancialAccount(
        id: '_missing',
        name: '—',
        type: AccountType.wallet,
      ),
    );

    if (acc.id == '_missing') {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon:
                  const Icon(LucideIcons.arrowRight, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: const Center(
            child: Text('تم حذف هذه المحفظة'),
          ),
        ),
      );
    }

    final hidden = ref.watch(hideBalanceProvider);
    final allEntries = ref.watch(cashbookEntriesProvider);
    final entries =
        allEntries.where((e) => e.accountId == acc.id).toList(growable: false);

    final income =
        entries.where((e) => e.isIncome).fold<double>(0, (s, e) => s + e.amount);
    final expense = entries
        .where((e) => !e.isIncome)
        .fold<double>(0, (s, e) => s + e.amount);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            acc.name,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              tooltip: 'تعديل',
              onPressed: () => _editWallet(context, ref, acc),
              icon: const Icon(LucideIcons.edit, color: AppColors.primary),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _BalanceCard(account: acc, hidden: hidden),
            const SizedBox(height: 16),
            _IncomeExpenseStrip(
              income: income,
              expense: expense,
              hidden: hidden,
              count: entries.length,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SoftCta(
                    label: '+ دخل',
                    bg: AppColors.successLight,
                    fg: Colors.green,
                    onTap: () => Navigator.push<void>(
                      context,
                      AppPageRoute<void>(
                        builder: (_) => CashEntryScreen(
                          initialIncome: true,
                          initialAccountId: acc.id,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SoftCta(
                    label: '− مصروف',
                    bg: AppColors.errorLight,
                    fg: Colors.deepOrange,
                    onTap: () => Navigator.push<void>(
                      context,
                      AppPageRoute<void>(
                        builder: (_) => CashEntryScreen(
                          initialIncome: false,
                          initialAccountId: acc.id,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OutlineAction(
                    icon: LucideIcons.fileText,
                    label: 'تقرير المحفظة',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تقرير المحفظة — قريباً'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OutlineAction(
                    icon: LucideIcons.edit,
                    label: 'تعديل',
                    onTap: () => _editWallet(context, ref, acc),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OutlineAction(
                    icon: LucideIcons.trash2,
                    label: 'حذف',
                    color: Colors.red,
                    onTap: () => _deleteWallet(context, ref, acc),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'الحركات (${entries.length})',
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
              const _EmptyMovements()
            else
              ...entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MovementTile(
                    entry: e,
                    hidden: hidden,
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

  void _editWallet(BuildContext context, WidgetRef ref, FinancialAccount acc) {
    Navigator.push<void>(
      context,
      AppPageRoute<void>(
        builder: (_) => AccountFormScreen(existingAccount: acc),
      ),
    );
  }

  Future<void> _deleteWallet(
    BuildContext context,
    WidgetRef ref,
    FinancialAccount acc,
  ) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف المحفظة'),
          content: Text('هل تريد حذف "${acc.name}"؟ لا يمكن التراجع.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (res == true) {
      ref.read(accountsProvider.notifier).deleteAccount(acc.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

// ════════════════════════════════════════════════════════════════
//  بطاقة رصيد المحفظة
// ════════════════════════════════════════════════════════════════
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.account, required this.hidden});
  final FinancialAccount account;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final amount = hidden
        ? obscureAmountText()
        : formatShekelAmount(account.balance);

    final infoLines = <String>[
      if (account.accountOwner != null && account.accountOwner!.isNotEmpty)
        'صاحب الحساب: ${account.accountOwner!}',
      if (account.accountNumber != null && account.accountNumber!.isNotEmpty)
        'رقم الحساب: ${account.accountNumber!}',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  account.type.icon,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'الرصيد الحالي',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const Text(
                  ' ₪',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (infoLines.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  for (final l in infoLines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(
                        l,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  شريط الدخل / المصروف / عدد الحركات
// ════════════════════════════════════════════════════════════════
class _IncomeExpenseStrip extends StatelessWidget {
  const _IncomeExpenseStrip({
    required this.income,
    required this.expense,
    required this.hidden,
    required this.count,
  });

  final double income;
  final double expense;
  final bool hidden;
  final int count;

  @override
  Widget build(BuildContext context) {
    Widget cell({
      required IconData icon,
      required String label,
      required String amount,
      required Color color,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        amount,
                        style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        ' ₪',
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final incStr = hidden ? obscureAmountText() : formatShekelAmount(income);
    final expStr = hidden ? obscureAmountText() : formatShekelAmount(expense);

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        cell(
          icon: LucideIcons.trendingUp,
          label: 'الدخل',
          amount: incStr,
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        cell(
          icon: LucideIcons.trendingDown,
          label: 'المصروف',
          amount: expStr,
          color: Colors.deepOrange,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.list,
                    color: AppColors.primary, size: 18),
                const SizedBox(height: 6),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'حركات',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  أزرار CTA الناعمة (+ دخل / − مصروف)
// ════════════════════════════════════════════════════════════════
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
//  زر مخطط (تقرير / تعديل / حذف)
// ════════════════════════════════════════════════════════════════
class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: c.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: c, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: c,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  بطاقة حركة
// ════════════════════════════════════════════════════════════════
String _formatDate(DateTime d) {
  final now = DateTime.now();
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return 'اليوم ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  return '${d.day}/${d.month}/${d.year}';
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({
    required this.entry,
    required this.hidden,
    required this.onOpen,
  });

  final CashbookEntry entry;
  final bool hidden;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = entry.isIncome ? Colors.green : Colors.deepOrange;
    final amount = hidden
        ? obscureAmountText()
        : formatShekelAmount(entry.amount);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
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
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 14,
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
                    _formatDate(entry.date),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${entry.isIncome ? '+' : '-'} $amount',
                    style: TextStyle(
                      color: c,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    ' ₪',
                    style: TextStyle(
                      color: c,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  حالة فارغة (لا حركات على هذه المحفظة)
// ════════════════════════════════════════════════════════════════
class _EmptyMovements extends StatelessWidget {
  const _EmptyMovements();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.inbox,
              size: 26,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'لا توجد حركات على هذه المحفظة',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'سجّل دخلاً أو مصروفاً واختر هذه المحفظة لتتبّع حركاتها',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
