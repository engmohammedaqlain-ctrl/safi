import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../cash_flow/data/financial_account_model.dart';
import '../../cash_flow/providers/accounts_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/router/app_page_route.dart';
import '../models/debt_category_model.dart';
import '../providers/debt_categories_provider.dart';
import '../providers/debts_ui_provider.dart';
import '../../reports/screens/client_report_screen.dart';
import 'add_debt_screen.dart';
import 'record_payment_screen.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.debtor});

  final DebtorUi debtor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDebtor = ref.watch(debtorByIdProvider(debtor.id)) ?? debtor;
    final transactions = ref.watch(customerTransactionsProvider(debtor.id));

    final amountText = currentDebtor.amount.isEmpty
        ? '0.0'
        : currentDebtor.amount.replaceAll('₪', '').trim();
    final numericAmount = double.tryParse(amountText) ?? 0;
    final balanceColor = numericAmount > 0
        ? Colors.red
        : numericAmount < 0
        ? Colors.green
        : Colors.grey;
    final balanceLabel = numericAmount > 0
        ? 'عليه لك'
        : numericAmount < 0
        ? 'لك عليه'
        : 'لا يوجد رصيد';
    final displayAmountWest = numericAmount.abs().toStringAsFixed(1);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          iconTheme: const IconThemeData(color: AppColors.primary),
          centerTitle: true,
          title: GestureDetector(
            onTap: () {
              _showCustomerInfo(context, ref, currentDebtor);
            },
            child: Text(
              currentDebtor.name,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // ── بطاقة الرصيد ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'الرصيد',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                balanceLabel,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$displayAmountWest ₪',
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: balanceColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _CustomerCategoryChipsInline(debtor: currentDebtor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── الإجراءات السريعة ──
                  Row(
                    textDirection: TextDirection.rtl,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _QuickCircle(
                        icon: LucideIcons.fileEdit,
                        label: 'ملاحظة',
                        onTap: () {},
                      ),
                      _QuickCircle(
                        icon: LucideIcons.phone,
                        label: 'اتصل',
                        onTap: () {},
                      ),
                      _QuickCircle(
                        icon: LucideIcons.share2,
                        label: 'مشاركة',
                        onTap: () {},
                      ),
                      _QuickCircle(
                        icon: LucideIcons.fileText,
                        label: 'تقرير',
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            AppPageRoute<void>(
                              builder: (_) =>
                                  ClientReportScreen(client: currentDebtor),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── عنوان المعاملات ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'معاملات (${transactions.length})',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── قائمة المعاملات أو الحالة الفارغة ──
                  if (transactions.isEmpty)
                    _buildEmptyState()
                  else
                    ...transactions.map(
                      (tx) => _TransactionTile(debtor: currentDebtor, tx: tx),
                    ),
                ],
              ),
            ),

            // ── أزرار أعطيت/أخذت ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push<bool>(
                          context,
                          AppPageRoute<bool>(
                            builder: (_) =>
                                AddDebtScreen(forCustomer: currentDebtor),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'دين جديد',
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push<bool>(
                          context,
                          AppPageRoute<bool>(
                            builder: (_) =>
                                RecordPaymentScreen(forCustomer: currentDebtor),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'تسجيل دفعة',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerInfo(
    BuildContext context,
    WidgetRef ref,
    DebtorUi currentDebtor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerInfoSheet(debtor: currentDebtor),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 32),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 30,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade300,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.attach_money,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 25,
                  left: 30,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.attach_money,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                Positioned(
                  top: 35,
                  left: 45,
                  child: Transform.rotate(
                    angle: 0.5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 35,
                  right: 40,
                  child: Transform.rotate(
                    angle: 0.5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد أي معاملة',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ── شِبس تصنيفات مدمجة في بطاقة الرصيد (بدون عنوان ولا صندوق منفصل) ──

class _CustomerCategoryChipsInline extends ConsumerWidget {
  const _CustomerCategoryChipsInline({required this.debtor});

  final DebtorUi debtor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(debtCategoriesProvider);
    final chips = <Widget>[];
    for (final id in debtor.categoryIds) {
      DebtCategory? cat;
      for (final c in all) {
        if (c.id == id) {
          cat = c;
          break;
        }
      }
      if (cat == null) continue;
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: cat.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: cat.color.withValues(alpha: 0.25)),
          ),
          child: Text(
            cat.name,
            style: TextStyle(
              color: cat.color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 6,
        runSpacing: 6,
        textDirection: TextDirection.rtl,
        children: chips,
      ),
    );
  }
}

// ── بطاقة المعاملة ──

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.debtor, required this.tx});

  final DebtorUi debtor;
  final TransactionUi tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGave = tx.type == TransactionType.gave;
    final color = isGave ? Colors.red : Colors.green;
    final icon = isGave ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft;
    final label = isGave ? 'دين' : 'سداد';
    final sign = isGave ? '+' : '−';
    final amountWest = tx.amount.toStringAsFixed(1);
    final dateStr = _formatTxListDate(tx.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openTransactionDetailSheet(context, ref, debtor, tx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (tx.note.isNotEmpty)
                      Text(
                        tx.note,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign$amountWest ₪',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatTxListDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) {
    return 'منذ ${diff.inMinutes} دقيقة';
  }
  if (diff.inHours < 24) {
    return 'منذ ${diff.inHours} ساعة';
  }
  if (diff.inDays == 1) return 'أمس';
  return '${date.day}/${date.month}/${date.year}';
}

void _openTransactionDetailSheet(
  BuildContext context,
  WidgetRef ref,
  DebtorUi debtor,
  TransactionUi tx,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (ctx) => _TransactionDetailSheet(debtor: debtor, transaction: tx),
  );
}

const _kArMonthNames = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String _formatSheetHeaderDate(DateTime d) {
  return '${d.day} ${_kArMonthNames[d.month - 1]} ${d.year}  ·  '
      '${_two(d.hour)}:${_two(d.minute)}';
}

String _two(int n) => n < 10 ? '0$n' : '$n';

IconData _payMethodIcon(String? id) {
  return switch (id) {
    'wallet' => LucideIcons.wallet,
    'bank' => LucideIcons.landmark,
    'cash' => LucideIcons.banknote,
    _ => LucideIcons.circleDot,
  };
}

IconData _payMethodIconFor(String? id, List<FinancialAccount> accounts) {
  if (id == null || id.isEmpty) return LucideIcons.circleDot;
  for (final a in accounts) {
    if (a.id == id) return a.type.icon;
  }
  return _payMethodIcon(id);
}

class _TransactionDetailSheet extends ConsumerWidget {
  const _TransactionDetailSheet({
    required this.debtor,
    required this.transaction,
  });

  final DebtorUi debtor;
  final TransactionUi transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = transaction;
    final accounts = ref.watch(accountsProvider);
    final isGave = tx.type == TransactionType.gave;
    final accent = isGave ? const Color(0xFFE65100) : const Color(0xFF2E7D32);
    final typeLabel = isGave ? 'أعطيت' : 'أخذت';
    final sign = isGave ? '+' : '−';
    final amt = tx.amount.toStringAsFixed(1);
    final method = transactionPayMethodLabel(
      tx.payMethodId,
      accounts: accounts,
    );
    final when = _formatSheetHeaderDate(tx.date);
    final bal = debtor.amount.replaceAll('₪', '').trim();
    final balColor = (double.tryParse(bal) ?? 0) > 0
        ? const Color(0xFFE65100)
        : (double.tryParse(bal) ?? 0) < 0
        ? const Color(0xFF2E7D32)
        : Colors.grey;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                when,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                debtor.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E6ED)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      typeLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$sign$amt ₪',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: accent,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الرصيد الحالي  $bal ₪',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: balColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _payMethodIconFor(tx.payMethodId, accounts),
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          method,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (tx.note.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  tx.note,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
              if (tx.imagePath != null &&
                  tx.imagePath!.isNotEmpty &&
                  !kIsWeb) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(tx.imagePath!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final lines = <String>[
                          typeLabel,
                          'المبلغ: $sign$amt ₪',
                          'الوسيلة: $method',
                          'الرصيد الحالي: $bal ₪',
                          'العميل: ${debtor.name}',
                          when,
                        ];
                        if (tx.note.isNotEmpty) {
                          lines.add('ملاحظة: ${tx.note}');
                        }
                        if (tx.imagePath != null && tx.imagePath!.isNotEmpty) {
                          lines.add('صورة: مرفقة');
                        }
                        Clipboard.setData(
                          ClipboardData(text: lines.join('\n')),
                        );
                        Navigator.pop(context);
                        showAppSnackBar(context, 'تم نسخ تفاصيل المعاملة');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFE0DCE8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'مشاركة',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            title: const Text('حذف المعاملة؟'),
                            content: const Text(
                              'سُحذف السجل ويُعدَّل رصيد العميل/المورد تلقائياً.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('إلغاء'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFE8E6),
                                  foregroundColor: const Color(0xFFC62828),
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('حذف'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true || !context.mounted) return;
                        final delta = tx.type == TransactionType.gave
                            ? -tx.amount
                            : tx.amount;
                        ref
                            .read(debtorsUiProvider.notifier)
                            .updateCustomerBalance(tx.customerId, delta);
                        ref
                            .read(transactionsProvider.notifier)
                            .removeTransactionById(tx.id);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        showAppSnackBar(context, 'تم حذف المعاملة');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE8E6),
                        foregroundColor: const Color(0xFFC62828),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'حذف',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── الدائرة السريعة ──

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
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CustomerInfoSheet extends ConsumerStatefulWidget {
  final DebtorUi debtor;
  const _CustomerInfoSheet({required this.debtor});

  @override
  ConsumerState<_CustomerInfoSheet> createState() => _CustomerInfoSheetState();
}

class _CustomerInfoSheetState extends ConsumerState<_CustomerInfoSheet> {
  bool _isEditingAddress = false;
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _addressCtrl = TextEditingController(text: widget.debtor.address ?? '');
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 64),
      padding: EdgeInsets.only(
        bottom: keyboardSpace > 0 ? keyboardSpace + 16 : 32,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'معلومات العميل',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Phone Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.phone,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'رقم الجوال',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.debtor.phone,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.copy,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.debtor.phone));
                    showAppSnackBar(context, 'تم نسخ رقم الجوال');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),

          // Address Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.mapPin,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _isEditingAddress
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تعديل الموقع',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _addressCtrl,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'أدخل موقع أو عنوان العميل',
                                hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      ref
                                          .read(debtorsUiProvider.notifier)
                                          .updateCustomerAddress(
                                            widget.debtor.id,
                                            _addressCtrl.text.trim(),
                                          );
                                      setState(() => _isEditingAddress = false);
                                      showAppSnackBar(context, 'تم حفظ الموقع');
                                    },
                                    child: const Text(
                                      'حفظ',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    _addressCtrl.text =
                                        widget.debtor.address ?? '';
                                    setState(() => _isEditingAddress = false);
                                  },
                                  child: const Text(
                                    'إلغاء',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الموقع / العنوان',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (widget.debtor.address == null ||
                                      widget.debtor.address!.isEmpty)
                                  ? 'لم يتم تسجيل موقع للعميل'
                                  : widget.debtor.address!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    (widget.debtor.address == null ||
                                        widget.debtor.address!.isEmpty)
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color:
                                    (widget.debtor.address == null ||
                                        widget.debtor.address!.isEmpty)
                                    ? Colors.grey.shade500
                                    : Colors.black87,
                              ),
                            ),
                            if (widget.debtor.address == null ||
                                widget.debtor.address!.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _isEditingAddress = true),
                                  child: const Text(
                                    '+ إضافة موقع',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                if (!_isEditingAddress &&
                    widget.debtor.address != null &&
                    widget.debtor.address!.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      LucideIcons.edit2,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isEditingAddress = true),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
