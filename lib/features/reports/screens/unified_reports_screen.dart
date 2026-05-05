import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lucide_icons/lucide_icons.dart';

import 'package:printing/printing.dart';

import 'package:share_plus/share_plus.dart';

import '../../../core/bootstrap/startup_ledger_data.dart';

import '../../../core/theme/app_colors.dart';

import '../../../core/widgets/reports_style_shell.dart';

import '../../../core/theme/app_theme.dart';

import '../../../core/ui/app_feedback.dart';

import '../../debts/providers/debts_ui_provider.dart';

import '../../sales/providers/cashbook_ui_provider.dart';

import '../services/app_report_excel.dart';

import '../services/app_report_pdf.dart';

export '../services/app_report_pdf.dart' show AppReportDebtFilter;

/// تقارير شاملة بتصميم Fintech ومزامنة مع ثيم الرئيسية.

class UnifiedReportsScreen extends ConsumerStatefulWidget {
  const UnifiedReportsScreen({
    super.key,

    this.initialFilter = AppReportDebtFilter.unifiedAll,

    this.lockDebtScope = false,
  });

  /// عند القدوم من «دفتر الديون»: يُستخدم التبويب (عملاء / بائع جملةين) فقط — دون خطوة اختيار نطاق.

  final AppReportDebtFilter initialFilter;

  /// إخفاء نطاق «كل التطبيق / عملاء / بائع جملةين» واعتماد [initialFilter] فقط.

  final bool lockDebtScope;

  @override
  ConsumerState<UnifiedReportsScreen> createState() =>
      _UnifiedReportsScreenState();
}

class _UnifiedReportsScreenState extends ConsumerState<UnifiedReportsScreen> {
  late DateTime _from;

  late DateTime _to;

  late AppReportDebtFilter _filter;

  bool _busy = false;

  @override
  void initState() {
    super.initState();

    final n = DateTime.now();

    _from = DateTime(n.year, n.month, 1);

    _to = DateTime(n.year, n.month, n.day);

    _filter = widget.initialFilter;
  }

  String get _heroTitle {
    if (widget.lockDebtScope) {
      return switch (_filter) {
        AppReportDebtFilter.customersOnly => 'تقارير الزبائن',

        AppReportDebtFilter.suppliersOnly => 'تقارير بائعي الجملة',

        AppReportDebtFilter.unifiedAll => 'التقارير',
      };
    }

    return 'التقارير والتصدير';
  }

  String get _heroSubtitle {
    if (widget.lockDebtScope) {
      return 'حركات الذمم خلال الفترة التي تختارها — تصدير PDF منسّق';
    }

    return 'صندوق + ديون في تقرير واحد، أو تفريق الزبائن عن بائعي الجملة';
  }

  Future<void> _pickFrom() async {
    final d = await AppTheme.showAppDatePicker(
      context: context,

      initialDate: _from,

      firstDate: DateTime(2000),

      lastDate: DateTime(2100),
    );

    if (d != null) setState(() => _from = d);
  }

  Future<void> _pickTo() async {
    final d = await AppTheme.showAppDatePicker(
      context: context,

      initialDate: _to,

      firstDate: DateTime(2000),

      lastDate: DateTime(2100),
    );

    if (d != null) setState(() => _to = d);
  }

  Future<Uint8List> _buildPdfBytes() async {
    final cash = ref.read(activeCashbookEntriesProvider);
    final txs = ref.read(transactionsProvider);
    final debtors = ref.read(debtorsUiProvider);
    // Use the cached user name as the report header (no extra async call needed)
    final storeName = StartupLedgerData.bootstrapUserName;

    return AppReportPdfBuilder.build(
      fromInclusive: _from,
      toInclusive: _to,
      filter: _filter,
      cash: cash,
      txs: txs,
      debtors: debtors,
      storeName: storeName,
    );
  }

  Future<void> _exportPdf() async {
    if (_from.isAfter(_to)) {
      showAppSnackBar(context, 'تاريخ البداية يجب أن يكون قبل النهاية');

      return;
    }

    setState(() => _busy = true);

    try {
      final bytes = await _buildPdfBytes();

      if (!mounted) return;

      await Printing.sharePdf(
        bytes: bytes,

        filename:
            'safi-report-${_from.year}-${_from.month}-${_from.day}-${_to.year}-${_to.month}-${_to.day}.pdf',
      );

      if (mounted) {
        showAppSnackBar(context, 'تم تجهيز الملف — اختر المشاركة أو الحفظ');
      }
    } catch (e, st) {
      debugPrint('$e\n$st');

      if (mounted) {
        showAppSnackBar(context, userFacingPdfError(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _previewPdf() async {
    if (_from.isAfter(_to)) {
      showAppSnackBar(context, 'تاريخ البداية يجب أن يكون قبل النهاية');

      return;
    }

    setState(() => _busy = true);

    late final Uint8List bytes;

    try {
      bytes = await _buildPdfBytes();
    } catch (e, st) {
      debugPrint('$e\n$st');

      if (mounted) {
        showAppSnackBar(context, userFacingPdfError(e), isError: true);

        setState(() => _busy = false);
      }

      return;
    }

    if (!mounted) {
      setState(() => _busy = false);

      return;
    }

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,

      name:
          'safi-report-${_from.year}${_from.month}${_from.day}-${_to.year}${_to.month}${_to.day}',
    );

    if (mounted) setState(() => _busy = false);
  }

  Future<void> _exportExcel() async {
    if (_from.isAfter(_to)) {
      showAppSnackBar(context, 'تاريخ البداية يجب أن يكون قبل النهاية');
      return;
    }
    setState(() => _busy = true);
    try {
      final cash = ref.read(activeCashbookEntriesProvider);
      final txs = ref.read(transactionsProvider);
      final debtors = ref.read(debtorsUiProvider);
      final storeName = StartupLedgerData.bootstrapUserName;
      final excelFilter = switch (_filter) {
        AppReportDebtFilter.unifiedAll => AppReportDebtFilterExcel.unifiedAll,
        AppReportDebtFilter.customersOnly => AppReportDebtFilterExcel.customersOnly,
        AppReportDebtFilter.suppliersOnly => AppReportDebtFilterExcel.suppliersOnly,
      };
      final bytes = AppReportExcelBuilder.buildUnifiedReport(
        fromInclusive: _from,
        toInclusive: _to,
        filter: excelFilter,
        cash: cash,
        txs: txs,
        debtors: debtors,
        storeName: storeName,
      );
      if (!mounted) return;
      final fileName =
          'safi-report-${_from.year}${_from.month}${_from.day}-${_to.year}${_to.month}${_to.day}.xlsx';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              name: fileName,
            ),
          ],
          subject: 'تقرير الصافي',
        ),
      );
      if (mounted) showAppSnackBar(context, 'تم تجهيز ملف Excel');
    } catch (e, st) {
      debugPrint('$e\n$st');
      if (mounted) {
        showAppSnackBar(context, 'تعذّر تصدير Excel: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: ReportsStyleSurfaces.bodyBackdrop,

          body: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [
                  ReportsStyleHeaderBand(
                    topPadding: topPad,

                    title: _heroTitle,

                    subtitle: _heroSubtitle,

                    onBack: () => Navigator.maybePop(context),

                    filterBadgeLabel: widget.lockDebtScope
                        ? _scopeBadge()
                        : null,
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),

                      child: AbsorbPointer(
                        absorbing: _busy,

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,

                          children: [
                            _whiteCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  const _SectionTitle(
                                    icon: LucideIcons.calendarDays,

                                    label: 'فترة التقرير',
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _dateTile(
                                          label: 'من',

                                          value:
                                              '${_from.year}/${_from.month}/${_from.day}',

                                          onTap: _pickFrom,
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      Expanded(
                                        child: _dateTile(
                                          label: 'إلى',

                                          value:
                                              '${_to.year}/${_to.month}/${_to.day}',

                                          onTap: _pickTo,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            if (!widget.lockDebtScope) ...[
                              const SizedBox(height: 14),

                              _whiteCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    const _SectionTitle(
                                      icon: LucideIcons.layers,

                                      label: 'نطاق التقرير',
                                    ),

                                    const SizedBox(height: 10),

                                    _filterTile(
                                      'كل التطبيق (صندوق + ديون)',

                                      AppReportDebtFilter.unifiedAll,
                                    ),

                                    const SizedBox(height: 8),

                                    _filterTile(
                                      'ديون الزبائن فقط',

                                      AppReportDebtFilter.customersOnly,
                                    ),

                                    const SizedBox(height: 8),

                                    _filterTile(
                                      'ديون بائعي الجملة فقط',

                                      AppReportDebtFilter.suppliersOnly,
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 18),

                            _primaryGradientButton(
                              icon: LucideIcons.fileDown,

                              label: 'تصدير PDF',

                              onPressed: _exportPdf,
                            ),

                            const SizedBox(height: 10),

                            _excelGradientButton(
                              icon: LucideIcons.fileSpreadsheet,
                              label: 'تصدير Excel',
                              onPressed: _exportExcel,
                            ),

                            const SizedBox(height: 10),

                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,

                                side: BorderSide(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.45,
                                  ),
                                ),

                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,

                                  horizontal: 16,
                                ),

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),

                              onPressed: _previewPdf,

                              icon: const Icon(LucideIcons.eye, size: 20),

                              label: const Text(
                                'معاينة قبل الطباعة',

                                style: TextStyle(
                                  fontWeight: FontWeight.w600,

                                  fontSize: 15,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Text(
                              'يُنشأ الملف بجداول وخط عربي مضمّن، ويمكن مشاركته من نافذة النظام.',

                              textAlign: TextAlign.center,

                              style: TextStyle(
                                fontSize: 12,

                                height: 1.5,

                                color: Colors.grey.shade600,

                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (_busy)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ModalBarrier(
                      color: Color(0x33000000),

                      dismissible: false,
                    ),
                  ),
                ),

              if (_busy)
                const Center(
                  child: Card(
                    elevation: 8,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),

                    child: Padding(
                      padding: EdgeInsets.all(24),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          SizedBox(
                            width: 28,

                            height: 28,

                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,

                              color: AppColors.primary,
                            ),
                          ),

                          SizedBox(height: 12),

                          Text(
                            'جاري تجهيز التقرير…',

                            style: TextStyle(
                              fontWeight: FontWeight.w600,

                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _scopeBadge() {
    return switch (_filter) {
      AppReportDebtFilter.customersOnly => 'نطاق: الزبائن',

      AppReportDebtFilter.suppliersOnly => 'نطاق: بائعي الجملة',

      AppReportDebtFilter.unifiedAll => 'نطاق: الكل',
    };
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade200),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),

            blurRadius: 18,

            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: child,
    );
  }

  Widget _filterTile(String label, AppReportDebtFilter v) {
    final sel = _filter == v;

    return Material(
      color: sel ? AppColors.lavender : const Color(0xFFFAFAFC),

      borderRadius: BorderRadius.circular(14),

      child: InkWell(
        borderRadius: BorderRadius.circular(14),

        onTap: () => setState(() => _filter = v),

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),

            border: Border.all(
              color: sel ? AppColors.primary : Colors.grey.shade300,

              width: sel ? 2 : 1,
            ),
          ),

          child: Row(
            children: [
              Icon(
                sel ? LucideIcons.checkCircle2 : LucideIcons.circle,

                color: sel ? AppColors.primary : Colors.grey,

                size: 20,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  label,

                  style: TextStyle(
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w500,

                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateTile({
    required String label,

    required String value,

    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceVariant,

      borderRadius: BorderRadius.circular(14),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(14),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                label,

                style: TextStyle(
                  fontSize: 12,

                  fontWeight: FontWeight.w600,

                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    size: 17,
                    color: AppColors.primary,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    value,

                    style: const TextStyle(
                      fontWeight: FontWeight.w600,

                      fontSize: 15,

                      color: AppColors.textPrimary,
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

  Widget _primaryGradientButton({
    required IconData icon,

    required String label,

    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),

            blurRadius: 16,

            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: _busy ? null : onPressed,

          borderRadius: BorderRadius.circular(16),

          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Icon(icon, color: Colors.white, size: 22),

                const SizedBox(width: 10),

                Text(
                  label,

                  style: const TextStyle(
                    fontWeight: FontWeight.w600,

                    fontSize: 16,

                    color: Colors.white,

                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _excelGradientButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _busy ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 0.3,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),

          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.09),

            borderRadius: BorderRadius.circular(10),
          ),

          child: Icon(icon, color: AppColors.primary, size: 19),
        ),

        const SizedBox(width: 10),

        Text(
          label,

          style: const TextStyle(
            fontWeight: FontWeight.w600,

            fontSize: 16,

            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
