import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/bootstrap/startup_ledger_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/widgets/reports_style_shell.dart';
import '../../debts/providers/debts_ui_provider.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../../reports/services/app_report_excel.dart';
import '../../reports/services/app_report_pdf.dart';
import '../data/financial_account_model.dart';
import '../providers/accounts_provider.dart';
import '../providers/include_debts_in_wallet_balance_provider.dart';
import '../utils/wallet_balance_math.dart';

/// شاشة تقرير محفظة — تتيح اختيار الفترة وتصدير PDF شامل.
class WalletReportScreen extends ConsumerStatefulWidget {
  const WalletReportScreen({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<WalletReportScreen> createState() => _WalletReportScreenState();
}

class _WalletReportScreenState extends ConsumerState<WalletReportScreen> {
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

  FinancialAccount get _acc {
    final accounts = ref.read(accountsProvider);
    return accounts.firstWhere(
      (a) => a.id == widget.accountId,
      orElse: () => const FinancialAccount(
        id: '_missing',
        name: '—',
        type: AccountType.wallet,
      ),
    );
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

  Future<Uint8List> _buildBytes() async {
    final acc = _acc;
    final activeAccounts = ref.read(activeAccountsProvider);
    final allEntries = ref.read(cashbookEntriesProvider);
    final allTx = ref.read(transactionsProvider);
    final debtors = ref.read(debtorsUiProvider);
    final includeDebts = ref.read(includeDebtsInWalletBalanceProvider);

    // Filter cash entries for this wallet
    final cashEntries = allEntries.where((e) {
      if (e.isDeleted) return false;
      final rid = resolvedCashAccountIdForEntry(e, activeAccounts);
      return rid == acc.id;
    }).toList(growable: false);

    // Filter debt txs for this wallet
    final debtTxs = includeDebts
        ? allTx
            .where(
              (t) =>
                  !t.isDeleted &&
                  debtPayTouchesWallet(t, acc, activeAccounts),
            )
            .toList(growable: false)
        : <TransactionUi>[];

    final effectiveBalance = effectiveWalletBalance(
      acc: acc,
      entries: allEntries,
      txs: allTx,
      accounts: activeAccounts,
      includeDebtEffect: includeDebts,
    );

    return AppReportPdfBuilder.buildWalletReport(
      account: acc,
      fromInclusive: _from,
      toInclusive: _to,
      cashEntries: cashEntries,
      debtTxs: debtTxs,
      debtors: debtors,
      effectiveBalance: effectiveBalance,
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
      final name = _acc.name.replaceAll(' ', '_');
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'safi-wallet-$name-${_from.year}${_from.month}${_from.day}.pdf',
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
    final name = _acc.name.replaceAll(' ', '_');
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'safi-wallet-$name',
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
      final acc = _acc;
      final activeAccounts = ref.read(activeAccountsProvider);
      final allEntries = ref.read(cashbookEntriesProvider);
      final allTx = ref.read(transactionsProvider);
      final debtors = ref.read(debtorsUiProvider);
      final includeDebts = ref.read(includeDebtsInWalletBalanceProvider);

      final cashEntries = allEntries.where((e) {
        if (e.isDeleted) return false;
        final rid = resolvedCashAccountIdForEntry(e, activeAccounts);
        return rid == acc.id;
      }).toList(growable: false);

      final debtTxs = includeDebts
          ? allTx
              .where(
                (t) =>
                    !t.isDeleted &&
                    debtPayTouchesWallet(t, acc, activeAccounts),
              )
              .toList(growable: false)
          : <TransactionUi>[];

      final effectiveBalance = effectiveWalletBalance(
        acc: acc,
        entries: allEntries,
        txs: allTx,
        accounts: activeAccounts,
        includeDebtEffect: includeDebts,
      );

      final bytes = AppReportExcelBuilder.buildWalletReport(
        account: acc,
        fromInclusive: _from,
        toInclusive: _to,
        cashEntries: cashEntries,
        debtTxs: debtTxs,
        debtors: debtors,
        effectiveBalance: effectiveBalance,
        storeName: StartupLedgerData.bootstrapUserName,
      );

      if (!mounted) return;

      final name = acc.name.replaceAll(' ', '_');
      final fileName =
          'safi-wallet-$name-${_from.year}${_from.month}${_from.day}.xlsx';

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
          subject: 'تقرير محفظة ${acc.name}',
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
    final acc = _acc;
    final topPad = MediaQuery.paddingOf(context).top;
    final activeAccounts = ref.watch(activeAccountsProvider);
    final allEntries = ref.watch(cashbookEntriesProvider);
    final allTx = ref.watch(transactionsProvider);
    final includeDebts = ref.watch(includeDebtsInWalletBalanceProvider);

    final cashEntries = allEntries.where((e) {
      if (e.isDeleted) return false;
      final rid = resolvedCashAccountIdForEntry(e, activeAccounts);
      return rid == acc.id;
    }).toList(growable: false);

    final debtTxs = includeDebts
        ? allTx
            .where(
              (t) =>
                  !t.isDeleted &&
                  debtPayTouchesWallet(t, acc, activeAccounts),
            )
            .toList(growable: false)
        : <TransactionUi>[];

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

    final effectiveBalance = effectiveWalletBalance(
      acc: acc,
      entries: allEntries,
      txs: allTx,
      accounts: activeAccounts,
      includeDebtEffect: includeDebts,
    );

    final balStr = '${formatShekelAmount(effectiveBalance)} ₪';
    final typeLabel = acc.type.label;

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
                  // ── Header ──
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.92),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'تقرير المحفظة',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            acc.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Content ──
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                      child: AbsorbPointer(
                        absorbing: _busy,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Summary card
                            _whiteCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle(
                                    LucideIcons.wallet,
                                    'ملخص المحفظة',
                                  ),
                                  const SizedBox(height: 12),
                                  _infoRow(
                                    LucideIcons.creditCard,
                                    'اسم المحفظة',
                                    acc.name,
                                  ),
                                  const SizedBox(height: 8),
                                  _infoRow(
                                    LucideIcons.banknote,
                                    'الرصيد الفعلي',
                                    balStr,
                                    color: effectiveBalance >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                  const SizedBox(height: 8),
                                  _infoRow(
                                    LucideIcons.trendingUp,
                                    'إجمالي الوارد',
                                    '${formatShekelAmount(income)} ₪',
                                    color: AppColors.flowIn,
                                  ),
                                  const SizedBox(height: 8),
                                  _infoRow(
                                    LucideIcons.trendingDown,
                                    'إجمالي الصادر',
                                    '${formatShekelAmount(expense)} ₪',
                                    color: AppColors.flowOut,
                                  ),
                                  const SizedBox(height: 8),
                                  _infoRow(
                                    LucideIcons.layers,
                                    'عدد الحركات',
                                    '$movementCount حركة',
                                  ),
                                  if (acc.accountOwner != null &&
                                      acc.accountOwner!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _infoRow(
                                      LucideIcons.user,
                                      'صاحب الحساب',
                                      acc.accountOwner!,
                                    ),
                                  ],
                                  if (acc.accountNumber != null &&
                                      acc.accountNumber!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _infoRow(
                                      LucideIcons.hash,
                                      'رقم الحساب',
                                      acc.accountNumber!,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

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

                            const SizedBox(height: 14),

                            // Content info card
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
                                    LucideIcons.listChecks,
                                    'يشمل',
                                    'حركات الصندوق + الديون المرتبطة',
                                  ),
                                  const SizedBox(height: 8),
                                  _infoRow(
                                    LucideIcons.fileBarChart,
                                    'الملخص',
                                    'رصيد ابتدائي + وارد + صادر + صافي',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Export button
                            _gradientButton(
                              icon: LucideIcons.fileDown,
                              label: 'تصدير تقرير المحفظة PDF',
                              onPressed: _exportPdf,
                            ),

                            const SizedBox(height: 10),

                            // Excel export button
                            _excelButton(
                              icon: LucideIcons.fileSpreadsheet,
                              label: 'تصدير تقرير المحفظة Excel',
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
                              'يتضمن التقرير ملخص المحفظة وجدول كل الحركات بألوان واضحة.',
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
      ),
    );
  }

  // ─── Widget helpers ──────────────────────────────────────────────────

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
  }) =>
      Material(
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
                    Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: AppColors.primary,
                    ),
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
  }) =>
      DecoratedBox(
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

  Widget _excelButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) =>
      DecoratedBox(
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
