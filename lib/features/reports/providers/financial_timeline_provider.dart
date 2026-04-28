import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../debts/providers/debts_ui_provider.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../../sales/providers/unified_ledger_math.dart';

/// صف واحد في الخط الزمني المالي (ديون + صافي نقدي).
class FinancialTimelineItem {
  const FinancialTimelineItem({
    required this.sortTime,
    required this.title,
    required this.subtitle,
    required this.delta,
    required this.runningNetSigned,
    required this.icon,
  });

  final DateTime sortTime;
  final String title;
  final String subtitle;

  /// أثر هذا السطر على المحصّلة الموقّعة.
  final double delta;

  /// صاف موقّع إلى هذه النقطة (ترتيب زمني تصاعدي ثم العرض من الأحدث في القائمة).
  final double runningNetSigned;
  final IconData icon;
}

final financialTimelineItemsProvider =
    Provider<List<FinancialTimelineItem>>((ref) {
  final cash = ref.watch(cashbookEntriesProvider);
  final txs = ref.watch(transactionsProvider);
  final debtors = ref.watch(debtorsUiProvider);

  final asc = UnifiedLedgerMath.buildRowsOldestFirst(
    cash: cash,
    txs: txs,
    debtors: debtors,
  );

  double run = 0;
  final chronoItems = <FinancialTimelineItem>[];
  for (final r in asc) {
    run += r.deltaSigned;
    chronoItems.add(
      FinancialTimelineItem(
        sortTime: r.sortTime,
        title: r.headline,
        subtitle: r.detailLine.isEmpty ? '—' : r.detailLine,
        delta: r.deltaSigned,
        runningNetSigned: run,
        icon: r.icon,
      ),
    );
  }

  return chronoItems.reversed.toList();
});

final financialTimelineNetSignedProvider = Provider<double>((ref) {
  final cash = ref.watch(cashbookEntriesProvider);
  final txs = ref.watch(transactionsProvider);
  return UnifiedLedgerMath.netSignedTotal(cash: cash, txs: txs);
});
