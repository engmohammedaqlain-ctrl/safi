import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/debts_ui_provider.dart';
import 'add_debt_screen.dart';
import 'record_payment_screen.dart';
import 'package:safi/core/router/app_page_route.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.debtor});

  final DebtorUi debtor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDebtor = ref.watch(debtorByIdProvider(debtor.id)) ?? debtor;
    final transactions = ref.watch(customerTransactionsProvider(debtor.id));

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
    final displayAmount = numericAmount.abs().toStringAsFixed(1);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            _showCustomerInfo(context, ref, currentDebtor);
          },
          child: Column(
            children: [
              Text(
                currentDebtor.name,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              const Text(
                'عرض معلومات العميل',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // ── بطاقة الرصيد ──
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('الرصيد',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        balanceLabel,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₪ $displayAmount',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                            color: balanceColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── الإجراءات السريعة ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickCircle(
                        icon: LucideIcons.fileEdit,
                        label: 'ملاحظة',
                        onTap: () {}),
                    _QuickCircle(
                        icon: LucideIcons.phone,
                        label: 'اتصل',
                        onTap: () {}),
                    _QuickCircle(
                        icon: LucideIcons.share2,
                        label: 'مشاركة',
                        onTap: () {}),
                    _QuickCircle(
                        icon: LucideIcons.fileText,
                        label: 'تقرير',
                        onTap: () {}),
                  ],
                ),
                const SizedBox(height: 32),

                // ── عنوان المعاملات ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'معاملات (${transactions.length})',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── قائمة المعاملات أو الحالة الفارغة ──
                if (transactions.isEmpty)
                  _buildEmptyState()
                else
                  ...transactions.map((tx) => _TransactionTile(tx: tx)),
              ],
            ),
          ),

          // ── أزرار أعطيت/أخذت ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
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
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('أعطيت',
                        style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
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
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('أخذت',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerInfo(BuildContext context, WidgetRef ref, DebtorUi currentDebtor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerInfoSheet(debtor: currentDebtor),
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
                    child: const Icon(Icons.attach_money,
                        color: Colors.white, size: 28),
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
                    child: const Icon(Icons.attach_money,
                        color: Colors.white, size: 24),
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
                      child: const Icon(Icons.arrow_upward_rounded,
                          color: Colors.white, size: 24),
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
                      child: const Icon(Icons.arrow_downward_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('لا توجد أي معاملة',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}

// ── بطاقة المعاملة ──

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final TransactionUi tx;

  @override
  Widget build(BuildContext context) {
    final isGave = tx.type == TransactionType.gave;
    final color = isGave ? Colors.red : Colors.green;
    final icon = isGave ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft;
    final label = isGave ? 'أعطيت' : 'أخذت';
    final sign = isGave ? '+' : '-';

    final dateStr = _formatTxDate(tx.date);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // أيقونة المعاملة
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),

          // تفاصيل المعاملة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                if (tx.note.isNotEmpty)
                  Text(tx.note,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          // المبلغ والتاريخ
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign₪ ${tx.amount.toStringAsFixed(1)}',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(dateStr,
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTxDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── الدائرة السريعة ──

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
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
      padding: EdgeInsets.only(bottom: keyboardSpace > 0 ? keyboardSpace + 16 : 32),
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
          const Text('معلومات العميل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                  child: const Icon(LucideIcons.phone, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('رقم الجوال', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(widget.debtor.phone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.copy, color: Colors.grey, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.debtor.phone));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رقم الجوال')));
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
                  child: const Icon(LucideIcons.mapPin, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _isEditingAddress
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تعديل الموقع', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _addressCtrl,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'أدخل موقع أو عنوان العميل',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
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
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      ref.read(debtorsUiProvider.notifier).updateCustomerAddress(widget.debtor.id, _addressCtrl.text.trim());
                                      setState(() => _isEditingAddress = false);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الموقع')));
                                    },
                                    child: const Text('حفظ', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    _addressCtrl.text = widget.debtor.address ?? '';
                                    setState(() => _isEditingAddress = false);
                                  },
                                  child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('الموقع / العنوان', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              (widget.debtor.address == null || widget.debtor.address!.isEmpty)
                                  ? 'لم يتم تسجيل موقع للعميل'
                                  : widget.debtor.address!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: (widget.debtor.address == null || widget.debtor.address!.isEmpty) ? FontWeight.normal : FontWeight.bold,
                                color: (widget.debtor.address == null || widget.debtor.address!.isEmpty) ? Colors.grey.shade500 : Colors.black87,
                              ),
                            ),
                            if (widget.debtor.address == null || widget.debtor.address!.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: InkWell(
                                  onTap: () => setState(() => _isEditingAddress = true),
                                  child: const Text('+ إضافة موقع', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              ),
                          ],
                        ),
                ),
                if (!_isEditingAddress && widget.debtor.address != null && widget.debtor.address!.isNotEmpty)
                  IconButton(
                    icon: const Icon(LucideIcons.edit2, color: Colors.grey, size: 20),
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
