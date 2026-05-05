import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../debts/providers/debts_ui_provider.dart';
import '../models/cashbook_entry.dart';

/// صف واحد في «الصافي» الموحّد: صندوق + ديون.
class UnifiedLedgerRowUi {
  const UnifiedLedgerRowUi({
    required this.sortTime,
    required this.headline,
    required this.detailLine,
    required this.deltaSigned,
    required this.icon,
    this.isCashbook = true,
    this.cashbookEntry,
    this.debtTransactionId,
  });

  final DateTime sortTime;
  final String headline;
  final String detailLine;
  final double deltaSigned;
  final IconData icon;
  final bool isCashbook;
  final CashbookEntry? cashbookEntry;
  final String? debtTransactionId;
}

/// تصفية صفوف الدفتر الموحّد (صندوق + ديون) — نفس منطق شاشة الأرشيف.
enum UnifiedLedgerListFilter { all, debtsOnly, cashIncomeOnly, cashExpenseOnly }

extension UnifiedLedgerListFilterX on UnifiedLedgerListFilter {
  String get labelAr => switch (this) {
    UnifiedLedgerListFilter.all => 'كل الحركات',
    UnifiedLedgerListFilter.debtsOnly => 'ديون فقط',
    UnifiedLedgerListFilter.cashIncomeOnly => 'وارد فقط',
    UnifiedLedgerListFilter.cashExpenseOnly => 'صادر فقط',
  };
}

class UnifiedLedgerMath {
  UnifiedLedgerMath._();

  static List<UnifiedLedgerRowUi> applyListFilter(
    List<UnifiedLedgerRowUi> all,
    UnifiedLedgerListFilter f,
  ) {
    switch (f) {
      case UnifiedLedgerListFilter.all:
        return List<UnifiedLedgerRowUi>.from(all);
      case UnifiedLedgerListFilter.debtsOnly:
        return [
          for (final r in all)
            if (!r.isCashbook) r,
        ];
      case UnifiedLedgerListFilter.cashIncomeOnly:
        return [
          for (final r in all)
            if (r.isCashbook &&
                r.cashbookEntry != null &&
                r.cashbookEntry!.isIncome)
              r,
        ];
      case UnifiedLedgerListFilter.cashExpenseOnly:
        return [
          for (final r in all)
            if (r.isCashbook &&
                r.cashbookEntry != null &&
                !r.cashbookEntry!.isIncome)
              r,
        ];
    }
  }

  static String debtName(List<DebtorUi> debtors, String id) {
    for (final d in debtors) {
      if (d.id == id) {
        final n = d.name.trim();
        return n.isEmpty ? 'بدون اسم (معرّف $id)' : n;
      }
    }
    return 'غير مربوط بسجل زبون (معرّف $id)';
  }

  static List<UnifiedLedgerRowUi> buildRowsNewestFirst({
    required List<CashbookEntry> cash,
    required List<TransactionUi> txs,
    required List<DebtorUi> debtors,
  }) {
    final base = _buildRowsUnsorted(cash: cash, txs: txs, debtors: debtors);
    base.sort((a, b) => b.sortTime.compareTo(a.sortTime));
    return base;
  }

  /// ترتيب زمني من الأقدم للأحدث (لخط زمني بصافٍ تراكمي).
  static List<UnifiedLedgerRowUi> buildRowsOldestFirst({
    required List<CashbookEntry> cash,
    required List<TransactionUi> txs,
    required List<DebtorUi> debtors,
  }) {
    final base = _buildRowsUnsorted(cash: cash, txs: txs, debtors: debtors);
    base.sort((a, b) => a.sortTime.compareTo(b.sortTime));
    return base;
  }

  static List<UnifiedLedgerRowUi> _buildRowsUnsorted({
    required List<CashbookEntry> cash,
    required List<TransactionUi> txs,
    required List<DebtorUi> debtors,
  }) {
    final rows = <UnifiedLedgerRowUi>[];
    for (final e in cash) {
      if (e.isDeleted) continue;
      final signed = e.isIncome ? e.amount : -e.amount;
      final hint = [
        if (e.title.isNotEmpty) e.title,
        if (e.category != null && e.category!.isNotEmpty) e.category!,
      ].join(' — ');
      rows.add(
        UnifiedLedgerRowUi(
          sortTime: e.date,
          headline: e.isIncome ? 'وارد — صندوق' : 'صادر — صندوق',
          detailLine: hint.isEmpty ? '—' : hint,
          deltaSigned: signed,
          icon: e.isIncome ? LucideIcons.trendingUp : LucideIcons.trendingDown,
          isCashbook: true,
          cashbookEntry: e,
        ),
      );
    }
    for (final t in txs) {
      if (t.isDeleted) continue;
      final name = debtName(debtors, t.customerId);
      final isGave = t.type == TransactionType.gave;
      // مواءمة مع الوارد / الصادر في البطاقة: قيمة خارجة = سالب، واردة للصندوق = موجب
      final signed = isGave ? -t.amount : t.amount;
      rows.add(
        UnifiedLedgerRowUi(
          sortTime: t.date,
          headline: isGave ? 'دين جديد' : 'سداد',
          detailLine: name,
          deltaSigned: signed,
          icon: LucideIcons.bookMarked,
          isCashbook: false,
          debtTransactionId: t.id,
        ),
      );
    }
    return rows;
  }

  /// صافٍ = إجمالي الوارد − إجمالي الصادر (صندوق + ديون)، يتماشى مع بطاقة «الدخل / المصروف».
  static double netSignedTotal({
    required List<CashbookEntry> cash,
    required List<TransactionUi> txs,
  }) {
    final io = inflowOutflowSplit(cash: cash, txs: txs);
    return io.inflow - io.outflow;
  }

  /// تقسيم لعرض «دخل / مصروف» في البطاقة (موجب = وارد، سالب = منصرف).
  static ({double inflow, double outflow}) inflowOutflowSplit({
    required List<CashbookEntry> cash,
    required List<TransactionUi> txs,
  }) {
    double infl = 0, outf = 0;
    for (final e in cash) {
      if (e.isDeleted) continue;
      if (e.isIncome) {
        infl += e.amount;
      } else {
        outf += e.amount;
      }
    }
    for (final t in txs) {
      if (t.isDeleted) continue;
      if (t.type == TransactionType.gave) {
        outf += t.amount;
      } else {
        infl += t.amount;
      }
    }
    return (inflow: infl, outflow: outf);
  }
}
