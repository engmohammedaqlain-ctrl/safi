import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:safi/core/router/app_page_route.dart';

import '../../../core/router/main_shell.dart' show hideBalanceProvider;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/vault_branded_shell.dart';
import '../../debts/providers/debts_ui_provider.dart';
import '../../debts/screens/customer_detail_screen.dart';
import '../../sales/models/cashbook_entry.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../../sales/providers/unified_ledger_math.dart';
import '../data/financial_account_model.dart';
import '../providers/accounts_provider.dart';
import '../utils/wallet_balance_math.dart';
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

    if (acc.id == '_missing' || acc.isDeleted) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: VaultInsetPageShell(
          title: const Text(
            'المحفظة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'تم حذف هذه المحفظة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final hidden = ref.watch(hideBalanceProvider);
    final activeAccounts = ref.watch(activeAccountsProvider);
    final allEntries = ref.watch(cashbookEntriesProvider);
    final allTx = ref.watch(transactionsProvider);
    final debtors = ref.watch(debtorsUiProvider);

    final cashEntries = allEntries.where((e) {
      if (e.isDeleted) return false;
      final rid = resolvedCashAccountIdForEntry(e, activeAccounts);
      return rid == acc.id;
    }).toList(growable: false);

    final debtTxs = allTx
        .where(
          (t) =>
              !t.isDeleted &&
              debtPayTouchesWallet(t, acc, activeAccounts),
        )
        .toList(growable: false);

    final cashIncome = cashEntries
        .where((e) => e.isIncome)
        .fold<double>(0, (s, e) => s + e.amount);
    final cashExpense = cashEntries
        .where((e) => !e.isIncome)
        .fold<double>(0, (s, e) => s + e.amount);

    final debtIncome = debtTxs
        .where((t) => t.type == TransactionType.received)
        .fold<double>(0, (s, t) => s + t.amount);
    final debtExpense = debtTxs
        .where((t) => t.type == TransactionType.gave)
        .fold<double>(0, (s, t) => s + t.amount);

    final income = cashIncome + debtIncome;
    final expense = cashExpense + debtExpense;
    final movementCount = cashEntries.length + debtTxs.length;

    final combined = <({DateTime t, CashbookEntry? c, TransactionUi? d})>[];
    for (final e in cashEntries) {
      combined.add((t: e.date, c: e, d: null));
    }
    for (final t in debtTxs) {
      combined.add((t: t.date, c: null, d: t));
    }
    combined.sort((a, b) => b.t.compareTo(a.t));

    final effectiveBalance = effectiveWalletBalance(
      acc: acc,
      entries: allEntries,
      txs: allTx,
      accounts: activeAccounts,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: VaultInsetPageShell(
        headerExtent: 72,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              acc.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: AppRadius.rfull,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                _WalletUi.typeChipShort(acc.type),
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        trailing: [
          IconButton(
            tooltip: 'تعديل',
            onPressed: () => _editWallet(context, ref, acc),
            icon: Icon(
              LucideIcons.edit,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _WalletHeroPlasticCard(
              account: acc,
              hidden: hidden,
              effectiveBalance: effectiveBalance,
            ),
            const SizedBox(height: 18),
            _IncomeExpenseStrip(
              income: income,
              expense: expense,
              hidden: hidden,
              count: movementCount,
              accent: _WalletUi.typeAccent(acc.type),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SoftCta(
                    label: '+ دخل',
                    bg: AppColors.successLight,
                    fg: AppColors.flowIn,
                    icon: LucideIcons.trendingUp,
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
                    fg: AppColors.flowOut,
                    icon: LucideIcons.trendingDown,
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
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _OutlineAction(
                    icon: LucideIcons.fileText,
                    label: 'تقرير',
                    onTap: () {
                      showAppSnackBar(context, 'تقرير المحفظة — قريباً');
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
                    color: AppColors.error,
                    onTap: () => _deleteWallet(context, ref, acc),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Icon(
                  LucideIcons.clipboardList,
                  size: 20,
                  color: AppColors.primary.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 8),
                Text(
                  'الحركات ($movementCount)',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (combined.isEmpty)
              _EmptyMovements(accent: _WalletUi.typeAccent(acc.type))
            else
              ...combined.map(
                (row) {
                  if (row.c != null) {
                    final e = row.c!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MovementTile(
                        entry: e,
                        hidden: hidden,
                        accent: _WalletUi.typeAccent(acc.type),
                        onOpen: () {
                          Navigator.push<void>(
                            context,
                            AppPageRoute<void>(
                              builder: (_) =>
                                  CashbookEntryDetailScreen(entry: e),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  final t = row.d!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DebtWalletTile(
                      tx: t,
                      debtors: debtors,
                      hidden: hidden,
                      accent: _WalletUi.typeAccent(acc.type),
                      onOpen: () {
                        final debtor =
                            ref.read(debtorByIdProvider(t.customerId));
                        if (debtor == null) return;
                        Navigator.push<void>(
                          context,
                          AppPageRoute<void>(
                            builder: (_) =>
                                CustomerDetailScreen(debtor: debtor),
                          ),
                        );
                      },
                    ),
                  );
                },
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
//  ألوان وتدرّجات متسقة مع قائمة المحافظ وبطاقة الأونبوردينغ
// ════════════════════════════════════════════════════════════════
abstract final class _WalletUi {
  static Color typeAccent(AccountType t) {
    switch (t) {
      case AccountType.cash:
        return const Color(0xFF2E7D32);
      case AccountType.bank:
        return const Color(0xFF1565C0);
      case AccountType.wallet:
        return AppColors.primaryDark;
    }
  }

  static String typeChipShort(AccountType t) {
    switch (t) {
      case AccountType.cash:
        return 'كاش';
      case AccountType.bank:
        return 'بنك';
      case AccountType.wallet:
        return 'محفظة';
    }
  }

  static List<Color> plasticGradient(AccountType t) {
    switch (t) {
      case AccountType.cash:
        return const [
          Color(0xFF43A047),
          Color(0xFF2E7D32),
          Color(0xFF1B5E20),
        ];
      case AccountType.bank:
        return const [
          Color(0xFF42A5F5),
          Color(0xFF1565C0),
          Color(0xFF0D47A1),
        ];
      case AccountType.wallet:
        return const [
          Color(0xFF9C27B0),
          Color(0xFF6A1B9A),
          Color(0xFF4A148C),
        ];
    }
  }

  static String _tailDigits(String id) {
    final only = id.replaceAll(RegExp(r'[^0-9]'), '');
    if (only.isEmpty) return '0000';
    final tail =
        only.length <= 4 ? only : only.substring(only.length - 4);
    return tail.padLeft(4, '0');
  }

  static String decorativePan(FinancialAccount a) {
    final tail = _tailDigits(a.id);
    return '••••  ••••  ••••  $tail';
  }
}

/// بطاقة بلاستيكية للرصيد وتفاصيل الحساب — مطابقة لفكرة بطاقات المحافظ.
class _WalletHeroPlasticCard extends StatelessWidget {
  const _WalletHeroPlasticCard({
    required this.account,
    required this.hidden,
    required this.effectiveBalance,
  });

  final FinancialAccount account;
  final bool hidden;

  /// الرصيد بعد استيفاء الحقل المخزَّن وجميع حركات الصندوق والديون لهذه المحفظة.
  final double effectiveBalance;

  @override
  Widget build(BuildContext context) {
    final gradient = _WalletUi.plasticGradient(account.type);
    final amount = hidden
        ? obscureAmountText()
        : formatShekelAmount(effectiveBalance);

    final infoLines = <String>[
      if (account.accountOwner != null && account.accountOwner!.isNotEmpty)
        'صاحب الحساب: ${account.accountOwner!}',
      if (account.accountNumber != null && account.accountNumber!.isNotEmpty)
        'رقم الحساب: ${account.accountNumber!}',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -18,
            bottom: -24,
            child: Icon(
              LucideIcons.circle,
              size: 110,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF0E6D2),
                          Color(0xFFC9A66B),
                          Color(0xFF9A7847),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: AppRadius.rfull,
                    ),
                    child: Text(
                      'الصافي',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      account.type.icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'الرصيد الحالي',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amount,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 34,
                        height: 1.05,
                      ),
                    ),
                    Text(
                      ' ₪',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (infoLines.isNotEmpty) ...[
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      children: [
                        for (final l in infoLines)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              l,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                _WalletUi.decorativePan(account),
                textAlign: TextAlign.center,
                style: AppTextStyles.titleSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  letterSpacing: 1.15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
    required this.accent,
  });

  final double income;
  final double expense;
  final bool hidden;
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    Widget cell({
      required IconData icon,
      required String label,
      required String amount,
      required Color color,
      Color? bgTint,
      Color? borderTint,
      bool showCurrencySuffix = true,
    }) {
      final bg = bgTint ?? Colors.white;
      final bd = borderTint ?? AppColors.outlineSoft;
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: bd),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: showCurrencySuffix
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              amount,
                              style: TextStyle(
                                color: color,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' ₪',
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          amount,
                          style: TextStyle(
                            color: color,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMuted,
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
          color: AppColors.flowIn,
          bgTint: AppColors.successLight,
        ),
        const SizedBox(width: 8),
        cell(
          icon: LucideIcons.trendingDown,
          label: 'المصروف',
          amount: expStr,
          color: AppColors.flowOut,
          bgTint: AppColors.errorLight,
        ),
        const SizedBox(width: 8),
        cell(
          icon: LucideIcons.layers,
          label: 'عدد الحركات',
          amount: '$count',
          color: accent,
          bgTint: accent.withValues(alpha: 0.08),
          borderTint: accent.withValues(alpha: 0.28),
          showCurrencySuffix: false,
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
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                  fontWeight: FontWeight.w600,
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

class _DebtWalletTile extends StatelessWidget {
  const _DebtWalletTile({
    required this.tx,
    required this.debtors,
    required this.hidden,
    required this.accent,
    required this.onOpen,
  });

  final TransactionUi tx;
  final List<DebtorUi> debtors;
  final bool hidden;
  final Color accent;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isGave = tx.type == TransactionType.gave;
    final c = isGave ? AppColors.flowOut : AppColors.flowIn;
    final amount =
        hidden ? obscureAmountText() : formatShekelAmount(tx.amount);
    final name = UnifiedLedgerMath.debtName(debtors, tx.customerId);
    final headline =
        isGave ? 'دين جديد — عبر المحفظة' : 'سداد — إلى المحفظة';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outlineSoft),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(13),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            LucideIcons.bookMarked,
                            color: c,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                headline,
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                name,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatDate(tx.date),
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                                '${isGave ? '-' : '+'} $amount',
                                style: TextStyle(
                                  color: c,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                ' ₪',
                                style: TextStyle(
                                  color: c,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _MovementTile extends StatelessWidget {
  const _MovementTile({
    required this.entry,
    required this.hidden,
    required this.accent,
    required this.onOpen,
  });

  final CashbookEntry entry;
  final bool hidden;
  final Color accent;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = entry.isIncome ? AppColors.flowIn : AppColors.flowOut;
    final amount = hidden
        ? obscureAmountText()
        : formatShekelAmount(entry.amount);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outlineSoft),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(13),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
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
                                  size: 21,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.title,
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (entry.category != null &&
                                  entry.category!.isNotEmpty)
                                Text(
                                  entry.category!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                _formatDate(entry.date),
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                ' ₪',
                                style: TextStyle(
                                  color: c,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

// ════════════════════════════════════════════════════════════════
//  حالة فارغة (لا حركات على هذه المحفظة)
// ════════════════════════════════════════════════════════════════
class _EmptyMovements extends StatelessWidget {
  const _EmptyMovements({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.18),
                  accent.withValues(alpha: 0.07),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              LucideIcons.inbox,
              size: 26,
              color: accent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'لا توجد حركات على هذه المحفظة',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'سجّل دخلاً أو مصروفاً واختر هذه المحفظة لتتبّع حركاتها',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
