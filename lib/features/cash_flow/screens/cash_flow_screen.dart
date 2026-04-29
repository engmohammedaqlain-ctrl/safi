import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/main_shell.dart' show hideBalanceProvider;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../debts/providers/debts_ui_provider.dart';
import '../../debts/screens/customer_detail_screen.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../../sales/providers/unified_ledger_provider.dart';
import '../../sales/providers/unified_ledger_math.dart';
import 'cashbook_entry_detail_screen.dart';
import 'cash_entry_screen.dart';
import 'package:safi/core/router/app_page_route.dart';

/// أرشيف — كل المعاملات (صندوق + ديون) بترتيب زمني وزر تصفية.
/// التصفية: ديون منفصلة؛ وارد/صادر للصندوق فقط (لا يختلط سداد/دين جديد مع النقد).
class CashFlowScreen extends ConsumerStatefulWidget {
  const CashFlowScreen({super.key});

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen> {
  UnifiedLedgerListFilter _filter = UnifiedLedgerListFilter.all;

  List<UnifiedLedgerRowUi> _filtered(List<UnifiedLedgerRowUi> all) {
    return UnifiedLedgerMath.applyListFilter(all, _filter);
  }

  String _filterLabel() => _filter.labelAr;

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'عرض الحركات',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  _sheetTile(UnifiedLedgerListFilter.all),
                  _sheetTile(UnifiedLedgerListFilter.debtsOnly),
                  _sheetTile(UnifiedLedgerListFilter.cashIncomeOnly),
                  _sheetTile(UnifiedLedgerListFilter.cashExpenseOnly),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sheetTile(UnifiedLedgerListFilter f) {
    final sel = _filter == f;
    return ListTile(
      title: Text(
        f.labelAr,
        style: TextStyle(
          fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
          color: sel ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: Icon(
        sel ? Icons.check_circle : Icons.circle_outlined,
        color: sel ? AppColors.primary : Colors.grey.shade400,
      ),
      onTap: () {
        setState(() => _filter = f);
        Navigator.pop(context);
      },
    );
  }

  void _openRow(UnifiedLedgerRowUi row) {
    void push(Widget w) {
      Navigator.push<void>(
        context,
        AppPageRoute<void>(builder: (_) => w),
      );
    }

    if (row.isCashbook && row.cashbookEntry != null) {
      push(CashbookEntryDetailScreen(entry: row.cashbookEntry!));
      return;
    }
    final tid = row.debtTransactionId;
    if (tid == null) return;
    TransactionUi? found;
    for (final t in ref.read(transactionsProvider)) {
      if (t.id == tid) {
        found = t;
        break;
      }
    }
    final debtor =
        found != null ? ref.read(debtorByIdProvider(found.customerId)) : null;
    if (debtor != null) {
      push(CustomerDetailScreen(debtor: debtor));
    }
  }

  @override
  Widget build(BuildContext context) {
    void push(Widget w) {
      Navigator.push<void>(
        context,
        AppPageRoute<void>(builder: (_) => w),
      );
    }

    final unifiedAll = ref.watch(unifiedLedgerRowsProvider);
    final hidden = ref.watch(hideBalanceProvider);
    final rows = [..._filtered(unifiedAll)]
      ..sort((a, b) => b.sortTime.compareTo(a.sortTime));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F6FA),
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF1A0A24),
                  AppColors.primaryDark,
                  AppColors.primary,
                ],
                stops: [0.0, 0.52, 1.0],
              ),
            ),
          ),
          leadingWidth: 48,
          leading: BackButton(
            color: Colors.white,
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'الأرشيف',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'سجل الحركات',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'التصفية: ${_filterLabel()}',
                    child: Material(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _showFilterSheet,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.slidersHorizontal,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _filterLabel(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: Text(
                      '${rows.length} عملية',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child:
                          unifiedAll.isEmpty
                              ? _EmptyLedger(onAddIncome: () {
                                  push(const CashEntryScreen(
                                    initialIncome: true,
                                  ));
                                })
                              : _EmptyFilteredState(
                                  hasAnyEntries: true,
                                  filter: _filter,
                                ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      itemCount: rows.length,
                      itemBuilder: (context, i) {
                        final row = rows[i];
                        return _ArchiveLedgerTile(
                          row: row,
                          hideAmount: hidden,
                          onTap: () => _openRow(row),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFilteredState extends StatelessWidget {
  const _EmptyFilteredState({
    required this.hasAnyEntries,
    required this.filter,
  });

  final bool hasAnyEntries;
  final UnifiedLedgerListFilter filter;

  @override
  Widget build(BuildContext context) {
    if (!hasAnyEntries) {
      return const SizedBox.shrink();
    }
    final msg = switch (filter) {
      UnifiedLedgerListFilter.cashIncomeOnly =>
        'لا توجد حركات وارد ضمن هذا العرض.',
      UnifiedLedgerListFilter.cashExpenseOnly =>
        'لا توجد حركات صادر ضمن هذا العرض.',
      _ => '',
    };
    if (msg.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

String _formatArchiveDate(DateTime d) {
  final now = DateTime.now();
  if (d.year == now.year &&
      d.month == now.month &&
      d.day == now.day) {
    return 'اليوم ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  return '${d.day}/${d.month}/${d.year}';
}

class _ArchiveLedgerTile extends StatelessWidget {
  const _ArchiveLedgerTile({
    required this.row,
    required this.hideAmount,
    required this.onTap,
  });

  final UnifiedLedgerRowUi row;
  final bool hideAmount;
  final VoidCallback onTap;

  Color _accent() {
    if (row.isCashbook && row.cashbookEntry != null) {
      final e = row.cashbookEntry!;
      return e.isIncome ? Colors.green : Colors.deepOrange;
    }
    return row.deltaSigned >= 0 ? Colors.green : Colors.deepOrange;
  }

  @override
  Widget build(BuildContext context) {
    final c = _accent();
    final absAmt = row.deltaSigned.abs();
    final amountStr =
        hideAmount ? obscureAmountText() : formatShekelAmount(absAmt);

    Widget leadingIcon() {
      if (row.isCashbook && row.cashbookEntry != null) {
        final e = row.cashbookEntry!;
        return (!kIsWeb && e.imagePath != null && e.imagePath!.isNotEmpty)
            ? Image.file(File(e.imagePath!), fit: BoxFit.cover)
            : Icon(
                e.isIncome ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                color: c,
                size: 18,
              );
      }
      return Icon(row.icon, color: c, size: 18);
    }

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(child: leadingIcon()),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      row.headline,
                      style: const TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (row.detailLine.isNotEmpty && row.detailLine != '—')
                      Text(
                        row.detailLine,
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      _formatArchiveDate(row.sortTime),
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '${row.deltaSigned >= 0 ? '+' : '-'} $amountStr ₪',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    height: 1.2,
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

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger({required this.onAddIncome});

  final VoidCallback onAddIncome;

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
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'سجّل حركتك من الصافي أو دفتر الديون.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAddIncome,
            icon: const Icon(LucideIcons.plus),
            label: const Text('تسجيل دخل أو مصروف'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
