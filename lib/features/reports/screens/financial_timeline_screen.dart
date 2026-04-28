import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/main_shell.dart' show hideBalanceProvider;
import '../../../core/theme/app_colors.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../providers/financial_timeline_provider.dart';

String _formatDateTimeAr(DateTime utc) {
  final d = utc.toLocal();
  String p2(int n) => n.toString().padLeft(2, '0');
  return '${d.year}/${p2(d.month)}/${p2(d.day)}  ${p2(d.hour)}:${p2(d.minute)}';
}

/// تقرير زمني: دخل، مصروف، دين، سداد — مع عمود صافٍ مركّز.
class FinancialTimelineScreen extends ConsumerWidget {
  const FinancialTimelineScreen({super.key});

  static String fmt(double v, bool hide) =>
      hide ? obscureAmountText() : formatShekelAmount(v.abs());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(financialTimelineItemsProvider);
    final netSigned = ref.watch(financialTimelineNetSignedProvider);
    final hidden = ref.watch(hideBalanceProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primary,
          title: const Text(
            'الخط الزمني المالي',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineSoft.withValues(alpha: 0.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'الصافي الكلي للمعروض أدناه',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₪ ${fmt(netSigned, hidden)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: netSigned >= 0
                            ? const Color(0xFF0D7A53)
                            : const Color(0xFFB42318),
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'الحركات (${items.length})',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Text(
                  'لا توجد حركات بعد — سجّل من الصافي أو دفتر الديون.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.45),
                ),
              )
            else
              ...items.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(e.icon, size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  e.subtitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatDateTimeAr(e.sortTime),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${e.delta >= 0 ? '+' : '−'}₪ ${fmt(e.delta, hidden)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: e.delta >= 0
                                      ? const Color(0xFF0D7A53)
                                      : const Color(0xFFB42318),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '⇲ ${fmt(e.runningNetSigned, hidden)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
