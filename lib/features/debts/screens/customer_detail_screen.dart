import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../cash_flow/providers/accounts_provider.dart';
import '../../cash_flow/data/financial_account_model.dart';
import '../../../core/widgets/vault_branded_shell.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/router/app_page_route.dart';
import '../models/debt_category_model.dart';
import '../providers/debt_categories_provider.dart';
import '../providers/debts_ui_provider.dart';
import '../utils/customer_name_limits.dart';
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
    final canDelete = permsAsync.value?.contains('delete_records') ?? false;
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
                        if (currentDebtor.dueDate != null && numericAmount > 0) ...[
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
                      if (isOwner || canDelete) _QuickCircle(
                        icon: LucideIcons.trash2,
                        label: 'حذف',
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              title: const Text('حذف الزبون؟'),
                              content: Text(
                                'سيتم حذف "${currentDebtor.name}" وجميع معاملاته نهائياً.',
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
                          ref
                              .read(debtorsUiProvider.notifier)
                              .removeCustomer(currentDebtor.id);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          showAppSnackBar(context, 'تم حذف الزبون');
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
                  if ((isOwner || canAddDebt) && (isOwner || canRecordPayment) && numericAmount > 0) const SizedBox(width: 12),
                  if ((isOwner || canRecordPayment) && numericAmount > 0) Expanded(
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
    final all = ref.watch(activeDebtCategoriesProvider);
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
    
    final isGave = tx.type == TransactionType.gave;
    final color = isGave ? Colors.red : Colors.green;
    const icon = LucideIcons.bookMarked;
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (tx.wasEdited) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.orange.shade200,
                              ),
                            ),
                            child: Text(
                              'معدّل',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
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
    final accounts = ref.watch(activeAccountsProvider);
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
    const icon = LucideIcons.bookMarked;

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
                  if (tx.wasEdited) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.pencil,
                              size: 12,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'تم تعديل هذه المعاملة',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (tx.editHistory.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.history, size: 14, color: Colors.orange.shade800),
                              const SizedBox(width: 6),
                              Text(
                                'سجل التعديلات',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (int i = 0; i < tx.editHistory.length; i++) ...[
                            if (i > 0) Divider(height: 12, color: Colors.orange.shade200),
                            _buildHistoryEntry(tx.editHistory[i], i + 1, accounts),
                          ],
                        ],
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
                                  debtor.isSupplier ? 'بائع الجملة' : 'الزبون',
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
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _openEditTransactionSheet(
                                context,
                                ref,
                                debtor,
                                tx,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade800,
                              side: BorderSide(color: Colors.orange.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.pencil,
                                  size: 16,
                                  color: Colors.orange.shade800,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'تعديل',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                                    'سُحذف السجل ويُعدَّل الرصيد تلقائياً.',
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

  Widget _buildHistoryEntry(EditHistoryEntry h, int index, List<FinancialAccount> accounts) {
    final dateStr = '${h.date.year}/${h.date.month}/${h.date.day}';
    final editedAtStr =
        '${h.editedAt.day}/${h.editedAt.month}/${h.editedAt.year} ${_two(h.editedAt.hour)}:${_two(h.editedAt.minute)}';
    final method = transactionPayMethodLabel(h.payMethodId, accounts: accounts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تعديل #$index — $editedAtStr',
          style: TextStyle(
            color: Colors.orange.shade900,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(LucideIcons.coins, size: 12, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              'المبلغ: ${h.amount.toStringAsFixed(1)} ₪',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 12),
            Icon(LucideIcons.calendar, size: 12, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              dateStr,
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
        if (h.note.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(LucideIcons.messageSquare, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  h.note,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

void _openEditTransactionSheet(
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
    builder: (ctx) => _EditTransactionSheet(debtor: debtor, transaction: tx),
  );
}

class _EditTransactionSheet extends ConsumerStatefulWidget {
  const _EditTransactionSheet({
    required this.debtor,
    required this.transaction,
  });

  final DebtorUi debtor;
  final TransactionUi transaction;

  @override
  ConsumerState<_EditTransactionSheet> createState() =>
      _EditTransactionSheetState();
}

class _EditTransactionSheetState extends ConsumerState<_EditTransactionSheet> {
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  late DateTime _date;
  String? _payMethodId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _amountCtrl = TextEditingController(
      text: tx.amount == tx.amount.toInt()
          ? tx.amount.toInt().toString()
          : tx.amount.toStringAsFixed(2),
    );
    _noteCtrl = TextEditingController(text: tx.note);
    _date = tx.date;
    _payMethodId = tx.payMethodId;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_isSaving) return;
    final newAmount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (newAmount <= 0) {
      showAppSnackBar(context, 'الرجاء إدخال مبلغ صحيح');
      return;
    }

    setState(() => _isSaving = true);

    final tx = widget.transaction;
    final oldAmount = ref.read(transactionsProvider.notifier).editTransaction(
      txId: tx.id,
      newAmount: newAmount,
      newNote: _noteCtrl.text.trim(),
      newDate: _date,
      newPayMethodId: _payMethodId,
      newImagePath: tx.imagePath,
    );

    if (oldAmount != null) {
      // عكس المبلغ القديم ثم تطبيق المبلغ الجديد
      // gave: المبلغ يضاف كدين (موجب)
      // received: المبلغ يُخصم كسداد (سالب)
      final isGave = tx.type == TransactionType.gave;
      final balanceDelta = isGave
          ? (newAmount - oldAmount)   // الفرق في الدين
          : -(newAmount - oldAmount); // الفرق في السداد (عكسي)
      ref
          .read(debtorsUiProvider.notifier)
          .updateCustomerBalance(tx.customerId, balanceDelta);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnackBar(context, 'تم تعديل المعاملة');
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final isGave = tx.type == TransactionType.gave;
    final color = isGave ? Colors.red : Colors.green;
    final typeLabel = isGave ? 'تعديل دين' : 'تعديل سداد';
    final keyboardSpace = MediaQuery.viewInsetsOf(context).bottom;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final accounts = ref.watch(activeAccountsProvider);
    final dateStr =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.only(top: 48),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.pencil, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.debtor.name,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  (keyboardSpace > 0 ? keyboardSpace : bottom) + 16,
                ),
                shrinkWrap: true,
                children: [
                  // ── المبلغ ──
                  const Text(
                    'المبلغ',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        suffixText: '₪',
                        suffixStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: color, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── الملاحظة ──
                  const Text(
                    'ملاحظة',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    minLines: 1,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'ملاحظة (اختياري)',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── التاريخ ──
                  const Text(
                    'التاريخ',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final d =
                            await AppTheme.showAppCalendarPickerSheet(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _date = d);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              dateStr,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── الحساب المالي (فقط للسداد) ──
                  if (!isGave && accounts.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'الحساب المالي',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      textDirection: TextDirection.rtl,
                      children: [
                        for (final a in accounts)
                          _editPayChip(a),
                      ],
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── أزرار ──
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: color,
                            disabledBackgroundColor: color.withValues(alpha: 0.4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'حفظ التعديلات',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
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
          ],
        ),
      ),
    );
  }

  Widget _editPayChip(FinancialAccount a) {
    final sel = _payMethodId == a.id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(
          () => _payMethodId = _payMethodId == a.id ? null : a.id,
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: const BoxConstraints(maxWidth: 200),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: sel ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          child: Text(
            a.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: sel ? Colors.white : AppColors.textSecondary,
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
    final role = widget.debtor.isSupplier ? 'بائع الجملة' : 'الزبون';

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
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.debtor;
    _nameCtrl = TextEditingController(text: d.name);
    var p = d.phone.replaceAll(RegExp(r'\D'), '');
    if (p.startsWith('00')) p = p.substring(2);
    _phoneCtrl = TextEditingController(text: p);
    _addressCtrl = TextEditingController(text: d.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.viewInsetsOf(context).bottom;
    final role = widget.debtor.isSupplier ? 'بائع الجملة' : 'الزبون';

    return Container(
      margin: const EdgeInsetsDirectional.only(top: 48),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
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
            const SizedBox(height: 16),
            Text(
              'معلومات $role',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'يُحفظ على الجهاز فوراً ويُرفَع للسحابة عند توفر الاتصال',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(24, 0, 24, keyboardSpace + 16),
                children: [
                  const Text(
                    'الاسم',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    textAlign: TextAlign.right,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(kMaxCustomerNameLength),
                    ],
                    decoration: _sheetInputDecoration('اسم $role'),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'رقم الجوال',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: false,
                              decimal: false,
                            ),
                            textInputAction: TextInputAction.next,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(15),
                            ],
                            decoration: _sheetInputDecoration('أرقام فقط'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 52,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '+',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'الموقع / العنوان',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressCtrl,
                    maxLines: 3,
                    minLines: 1,
                    textAlign: TextAlign.right,
                    decoration:
                        _sheetInputDecoration('اختياري — عنوان أو موقع'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final err = ref
                          .read(debtorsUiProvider.notifier)
                          .updateCustomerCoreDetails(
                            customerId: widget.debtor.id,
                            name: _nameCtrl.text,
                            phoneRaw: _phoneCtrl.text,
                            addressRaw: _addressCtrl.text,
                          );
                      if (!context.mounted) return;
                      if (err != null) {
                        showAppSnackBar(context, err, backgroundColor: Colors.red);
                        return;
                      }
                      Navigator.pop(context);
                      showAppSnackBar(context, 'تم حفظ التعديلات');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'حفظ التعديلات',
                      style: TextStyle(fontWeight: FontWeight.w700),
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

  InputDecoration _sheetInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}
