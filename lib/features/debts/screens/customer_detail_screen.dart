import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../cash_flow/providers/accounts_provider.dart';
import '../../../core/widgets/vault_branded_shell.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/router/app_page_route.dart';
import '../models/debt_category_model.dart';
import '../providers/debt_categories_provider.dart';
import '../providers/debts_ui_provider.dart';
import '../utils/debt_transaction_share.dart';
import '../../reports/screens/client_report_screen.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../../settings/providers/team_provider.dart';
import 'add_debt_screen.dart';
import 'record_payment_screen.dart';

Future<void> _launchDialer(BuildContext context, String phone) async {
  final normalized = _normalizePhoneForTel(phone);
  if (normalized.isEmpty) {
    showAppSnackBar(context, 'لا يوجد رقم مسجل');
    return;
  }
  // Uri.parse يحافظ على + في الأرقام الدولية بشكل موثوق مع tel:
  final uri = Uri.parse('tel:$normalized');

  try {
    // على أندرويد 11+ قد يُرجع canLaunchUrl خطأً رغم أن المكالمة تعمل — نعتمد launchUrl مباشرة.
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted) return;
    if (!launched) {
      showAppSnackBar(context, 'تعذّر فتح تطبيق الاتصال');
    }
  } catch (_) {
    if (!context.mounted) return;
    showAppSnackBar(context, 'تعذّر فتح تطبيق الاتصال');
  }
}

/// أرقام وعلامة + في البداية فقط — صالح لـ tel:
String _normalizePhoneForTel(String raw) {
  final s = raw.trim().replaceAll(RegExp(r'\s'), '');
  if (s.isEmpty) return '';
  final buf = StringBuffer();
  final digit = RegExp(r'[0-9]');
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    if (ch == '+' && buf.isEmpty) {
      buf.write('+');
    } else if (digit.hasMatch(ch)) {
      buf.write(ch);
    }
  }
  return buf.toString();
}

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.debtor});

  final DebtorUi debtor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDebtor = ref.watch(debtorByIdProvider(debtor.id)) ?? debtor;
    final transactions = ref.watch(customerTransactionsProvider(debtor.id));
    final permsAsync = ref.watch(userPermissionsProvider);
    final roleAsync = ref.watch(userRoleProvider);
    final canAddDebt = permsAsync.value?.contains('add_debt') ?? false;
    final canRecordPayment = permsAsync.value?.contains('record_payment') ?? false;
    final isOwner = roleAsync.when(
      data: (r) => r == 'owner',
      loading: () => true,
      error: (_, __) => true,
    );

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

    final noteTrimmed = (currentDebtor.note ?? '').trim();
    final hasCustomerNote = noteTrimmed.isNotEmpty;

    String formatTime(DateTime date) {
      final h = date.hour;
      final m = date.minute.toString().padLeft(2, '0');
      final ampm = h >= 12 ? 'م' : 'ص';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h12:$m $ampm';
    }

    String formatTimeRemaining(DateTime date) {
      final now = DateTime.now();
      final diff = date.difference(now);
      if (diff.isNegative) {
        final days = diff.inDays.abs();
        if (days == 0) return 'متأخر منذ اليوم';
        return 'متأخر منذ $days يوم';
      } else {
        final days = diff.inDays;
        if (days == 0) {
          final hours = diff.inHours;
          if (hours == 0) {
            return 'متبقي ${diff.inMinutes} دقيقة';
          }
          return 'متبقي $hours ساعة';
        }
        return 'متبقي $days يوم';
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: VaultInsetPageShell(
        headerExtent: hasCustomerNote ? 74 : kToolbarHeight,
        title: GestureDetector(
          onTap: () {
            _showCustomerInfo(context, ref, currentDebtor);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentDebtor.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasCustomerNote)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    noteTrimmed,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        child: Column(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                      fontWeight: FontWeight.w600,
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
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: _CustomerCategoryChipsInline(
                                debtor: currentDebtor,
                              ),
                            ),
                          ],
                        ),
                        if (currentDebtor.dueDate != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: currentDebtor.dueDate!.isBefore(
                                DateTime.now(),
                              )
                                  ? Colors.red.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              textDirection: TextDirection.rtl,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    LucideIcons.calendarClock,
                                    size: 16,
                                    color: currentDebtor.dueDate!.isBefore(
                                      DateTime.now(),
                                    )
                                        ? Colors.red
                                        : Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'موعد السداد: ${currentDebtor.dueDate!.year}/${currentDebtor.dueDate!.month}/${currentDebtor.dueDate!.day} ${formatTime(currentDebtor.dueDate!)} (${formatTimeRemaining(currentDebtor.dueDate!)})',
                                    style: TextStyle(
                                      color: currentDebtor.dueDate!.isBefore(
                                        DateTime.now(),
                                      )
                                          ? Colors.red
                                          : Colors.orange.shade800,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                        onTap: () =>
                            _showCustomerNoteSheet(context, currentDebtor),
                      ),
                      _QuickCircle(
                        icon: LucideIcons.phone,
                        label: 'اتصل',
                        onTap: () =>
                            _launchDialer(context, currentDebtor.phone),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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

            // ── أزرار دين جديد / تسجيل سداد ──
            if (isOwner || canAddDebt || canRecordPayment) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
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
                  if (isOwner || canAddDebt) Expanded(
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if ((isOwner || canAddDebt) && (isOwner || canRecordPayment)) const SizedBox(width: 12),
                  if (isOwner || canRecordPayment) Expanded(
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
                        'تسجيل سداد',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
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

  void _showCustomerNoteSheet(BuildContext context, DebtorUi debtor) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerNoteSheet(debtor: debtor),
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
              fontWeight: FontWeight.w600,
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
    final permsAsync = ref.watch(userPermissionsProvider);
    final roleAsync = ref.watch(userRoleProvider);
    final canDelete = permsAsync.value?.contains('delete_records') ?? false;
    final isOwner = roleAsync.when(
      data: (r) => r == 'owner',
      loading: () => true,
      error: (_, __) => true,
    );
    
    final isGave = tx.type == TransactionType.gave;
    final color = isGave ? Colors.red : Colors.green;
    final icon = isGave ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight;
    final label = isGave ? 'دين' : 'سداد';
    final sign = isGave ? '−' : '+';
    final amountWest = tx.amount.toStringAsFixed(1);
    final dateStr = _formatTxListDate(tx.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openTransactionDetailSheet(context, ref, debtor, tx),
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
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

void _openDebtTxnAttachmentViewer(BuildContext context, String imagePath) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => _DebtTxnImageViewerPage(imagePath: imagePath),
    ),
  );
}

class _DebtTxnImageViewerPage extends StatelessWidget {
  const _DebtTxnImageViewerPage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'المرفق',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(48),
                minScale: 0.25,
                maxScale: 5,
                clipBehavior: Clip.none,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.imageOff,
                            size: 44,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'تعذّر فتح الصورة',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
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
    final permsAsync = ref.watch(userPermissionsProvider);
    final roleAsync = ref.watch(userRoleProvider);
    final canDelete = permsAsync.value?.contains('delete_records') ?? false;
    final isOwner = roleAsync.when(
      data: (r) => r == 'owner',
      loading: () => true,
      error: (_, __) => true,
    );

    final tx = transaction;
    final accounts = ref.watch(accountsProvider);
    final isGave = tx.type == TransactionType.gave;
    final color = isGave ? Colors.red : Colors.green;
    final typeLabel = isGave ? 'دين' : 'سداد';
    final sign = isGave ? '−' : '+';
    final amt = formatShekelAmount(tx.amount);
    final method = transactionPayMethodLabel(
      tx.payMethodId,
      accounts: accounts,
    );
    final when = _formatSheetHeaderDate(tx.date);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxSheetH = MediaQuery.sizeOf(context).height * 0.82;
    final icon = isGave ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight;

    final cardDecoration = BoxDecoration(
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
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetH),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(14, 6, 14, 8 + bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    debtor.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    typeLabel,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    when,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                        Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                textDirection: TextDirection.ltr,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$sign$amt',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      height: 1.0,
                                    ),
                                  ),
                                  Text(
                                    ' ₪',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.wallet,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'وسيلة الدفع',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    method,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (tx.note.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ملاحظة',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tx.note,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (tx.imagePath != null &&
                      tx.imagePath!.isNotEmpty &&
                      !kIsWeb) ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                        color: Colors.grey.shade100,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openDebtTxnAttachmentViewer(
                            context,
                            tx.imagePath!,
                          ),
                          child: SizedBox(
                            height: 112,
                            width: double.infinity,
                            child: Image.file(
                              File(tx.imagePath!),
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                child: Icon(
                                  LucideIcons.imageOff,
                                  size: 28,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await shareDebtTransactionReceipt(
                              context: context,
                              customerName: debtor.name,
                              amount: tx.amount,
                              type: tx.type,
                              date: tx.date,
                              counterpartyLabel:
                                  debtor.isSupplier ? 'المورد' : 'العميل',
                              paymentMethod: method,
                              note: tx.note.isEmpty ? null : tx.note,
                              attachmentPath: tx.imagePath,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.share2,
                                size: 17,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'مشاركة',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isOwner || canDelete) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  title: const Text('حذف المعاملة؟'),
                                  content: const Text(
                                    'سُحذف السجل ويُعدَّل الرصيد تلقائياً.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: const Color(0xFFE53935),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'حذف',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── إجراءات سريعة — أسلوب متوافق مع بطاقات صافي (بنفسجي هادئ) ──

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineSoft, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerNoteSheet extends ConsumerStatefulWidget {
  const _CustomerNoteSheet({required this.debtor});

  final DebtorUi debtor;

  @override
  ConsumerState<_CustomerNoteSheet> createState() =>
      _CustomerNoteSheetState();
}

class _CustomerNoteSheetState extends ConsumerState<_CustomerNoteSheet> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.debtor.note ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    final role = widget.debtor.isSupplier ? 'المورد' : 'العميل';

    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: keyboardSpace > 0 ? keyboardSpace + 16 : 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
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
            const SizedBox(height: 20),
            Text(
              'ملاحظة عن $role',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.debtor.name,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              maxLines: 4,
              minLines: 3,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'تذكير شخصي أو تفاصيل عن هذا الحساب…',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.4),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      ref
                          .read(debtorsUiProvider.notifier)
                          .updateCustomerNote(widget.debtor.id, _ctrl.text);
                      Navigator.pop(context);
                      showAppSnackBar(context, 'تم حفظ الملاحظة');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'حفظ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
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
              fontWeight: FontWeight.w600,
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
                          fontWeight: FontWeight.w600,
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
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                                color:
                                    (widget.debtor.address == null ||
                                        widget.debtor.address!.isEmpty)
                                    ? Colors.grey.shade500
                                    : AppColors.textPrimary,
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
                                      fontWeight: FontWeight.w600,
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
