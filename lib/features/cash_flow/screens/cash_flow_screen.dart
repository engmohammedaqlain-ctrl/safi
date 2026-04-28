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
import 'cashbook_entry_detail_screen.dart';
import 'cash_entry_screen.dart';
import 'package:safi/core/router/app_page_route.dart';

enum _LedgerFilter { all, income, expense }

/// أرشيف — كل المعاملات (صندوق + ديون) بترتيب زمني وزر تصفية.
class CashFlowScreen extends ConsumerStatefulWidget {
  const CashFlowScreen({super.key});

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen> {
  _LedgerFilter _filter = _LedgerFilter.all;

  List<UnifiedLedgerRowUi> _filtered(List<UnifiedLedgerRowUi> all) {
    switch (_filter) {
      case _LedgerFilter.all:
        return List<UnifiedLedgerRowUi>.from(all);
      case _LedgerFilter.income:
        return [for (final r in all) if (r.deltaSigned > 0) r];
      case _LedgerFilter.expense:
        return [for (final r in all) if (r.deltaSigned < 0) r];
    }
  }

  String _filterLabel() => switch (_filter) {
        _LedgerFilter.all => 'كل الحركات',
        _LedgerFilter.income => 'وارد فقط',
        _LedgerFilter.expense => 'صادر فقط',
      };

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
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  _sheetTile('كل الحركات', _LedgerFilter.all),
                  _sheetTile('وارد فقط', _LedgerFilter.income),
                  _sheetTile('صادر فقط', _LedgerFilter.expense),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sheetTile(String title, _LedgerFilter f) {
    final sel = _filter == f;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
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
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: () => push(const CashEntryScreen(initialIncome: true)),
          icon: const Icon(LucideIcons.plus, size: 20),
          label: const Text(
            'تسجيل حركة',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
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
              fontWeight: FontWeight.w900,
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
                          fontWeight: FontWeight.w900,
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
                                  fontWeight: FontWeight.w800,
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 88),
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
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        112,
                      ),
                      itemCount: rows.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 10),
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
  final _LedgerFilter filter;

  @override
  Widget build(BuildContext context) {
    if (!hasAnyEntries) {
      return const SizedBox.shrink();
    }
    final msg = switch (filter) {
      _LedgerFilter.income => 'لا توجد حركات وارد ضمن هذا العرض.',
      _LedgerFilter.expense =>
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
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(e.imagePath!), fit: BoxFit.cover),
              )
            : Icon(
                e.isIncome ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                color: c,
                size: 20,
              );
      }
      return Icon(row.icon, color: c, size: 20);
    }

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: AppRadius.rlg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rlg,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rlg,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(child: leadingIcon()),
                ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (row.detailLine.isNotEmpty && row.detailLine != '—')
                      Text(
                        row.detailLine,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      _formatArchiveDate(row.sortTime),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: c,
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
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'سجّل حركتك من الصافي أو دفتر الديون، أو بالزر أدناه.',
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
