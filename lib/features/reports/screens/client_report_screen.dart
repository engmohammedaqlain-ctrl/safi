import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:printing/printing.dart';

import '../../../core/bootstrap/startup_ledger_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_feedback.dart';
import '../../debts/providers/debts_ui_provider.dart';
import '../services/app_report_pdf.dart';

/// شاشة تقرير عميل/مورد — تتيح اختيار الفترة وتصدير PDF مُلوَّن.
class ClientReportScreen extends ConsumerStatefulWidget {
  const ClientReportScreen({super.key, required this.client});

  final DebtorUi client;

  @override
  ConsumerState<ClientReportScreen> createState() => _ClientReportScreenState();
}

class _ClientReportScreenState extends ConsumerState<ClientReportScreen> {
  late DateTime _from;
  late DateTime _to;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _from = DateTime(n.year, n.month, 1);
    _to = DateTime(n.year, n.month, n.day);
  }

  DebtorUi get _client =>
      ref.read(debtorByIdProvider(widget.client.id)) ?? widget.client;

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

  Future<Uint8List> _buildBytes() async {
    final txs = ref.read(transactionsProvider);
    return AppReportPdfBuilder.buildClientReport(
      client: _client,
      fromInclusive: _from,
      toInclusive: _to,
      allTxs: txs,
      storeName: StartupLedgerData.bootstrapUserName,
    );
  }

  Future<void> _exportPdf() async {
    if (_from.isAfter(_to)) {
      showAppSnackBar(context, 'تاريخ البداية يجب أن يكون قبل النهاية');
      return;
    }
    setState(() => _busy = true);
    try {
      final bytes = await _buildBytes();
      if (!mounted) return;
      final name = _client.name.replaceAll(' ', '_');
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'safi-client-$name-${_from.year}${_from.month}${_from.day}.pdf',
      );
      if (mounted) showAppSnackBar(context, 'تم تجهيز الملف');
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
    late Uint8List bytes;
    try {
      bytes = await _buildBytes();
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
    final name = _client.name.replaceAll(' ', '_');
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'safi-client-$name',
    );
    if (mounted) setState(() => _busy = false);
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final client = _client;
    final topPad = MediaQuery.paddingOf(context).top;
    final isSupplier = client.isSupplier;
    final typeLabel = isSupplier ? 'مورد' : 'عميل';

    final balance =
        double.tryParse(client.amount.replaceAll('₪', '').trim()) ?? 0.0;
    final balColor = balance > 0 ? AppColors.error : AppColors.success;
    final balLabel = balance > 0
        ? 'يدين لك ${balance.abs().toStringAsFixed(1)} ش'
        : balance < 0
        ? 'أنت مدين ${balance.abs().toStringAsFixed(1)} ش'
        : 'لا يوجد رصيد';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F8),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header Band ──────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        const Color(0xFF1A0A24),
                        AppColors.primaryDark,
                        AppColors.primary.withValues(alpha: 0.92),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, topPad + 6, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            BackButton(
                              color: Colors.white,
                              onPressed: () => Navigator.maybePop(context),
                            ),
                            const Spacer(),
                            // Balance badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Text(
                                balLabel,
                                style: TextStyle(
                                  color: balance == 0
                                      ? Colors.white70
                                      : (balance > 0
                                            ? const Color(0xFFFF8A80)
                                            : const Color(0xFF69F0AE)),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'كشف حساب $typeLabel',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          client.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                            height: 1.2,
                          ),
                        ),
                        if (client.phone.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            client.phone,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Content ──────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                    child: AbsorbPointer(
                      absorbing: _busy,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Date range card
                          _whiteCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle(
                                  LucideIcons.calendarDays,
                                  'فترة التقرير',
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

                          const SizedBox(height: 16),

                          // Info card
                          _whiteCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle(
                                  LucideIcons.fileText,
                                  'محتوى التقرير',
                                ),
                                const SizedBox(height: 10),
                                _infoRow(
                                  LucideIcons.user,
                                  'الجهة',
                                  '${client.name} ($typeLabel)',
                                ),
                                const SizedBox(height: 8),
                                _infoRow(
                                  LucideIcons.wallet,
                                  'الرصيد الحالي',
                                  balLabel,
                                  color: balColor,
                                ),
                                const SizedBox(height: 8),
                                _infoRow(
                                  LucideIcons.listChecks,
                                  'محتوى',
                                  'كل المعاملات (دين + سداد) في الفترة المحددة',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Export button
                          _gradientButton(
                            icon: LucideIcons.fileDown,
                            label: 'تصدير كشف الحساب PDF',
                            onPressed: _exportPdf,
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
                            'يتضمن التقرير معلومات العميل، ملخص الرصيد، وجدول كل المعاملات بألوان واضحة.',
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

            // Loading overlay
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
              Center(
                child: Card(
                  elevation: 8,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
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
    );
  }

  // ─── Widget helpers ──────────────────────────────────────────────────────────

  Widget _whiteCard({required Widget child}) => Container(
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

  Widget _sectionTitle(IconData icon, String label) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      const SizedBox(width: 10),
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AppColors.primary,
        ),
      ),
    ],
  );

  Widget _dateTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) => Material(
    color: AppColors.surfaceVariant,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(LucideIcons.calendar, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) =>
      Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: color ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _gradientButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) => DecoratedBox(
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
