import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/debts_ui_provider.dart';
import '../widgets/calculator_keypad.dart';
import 'transaction_success_screen.dart';
import 'package:safi/core/router/app_page_route.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({super.key, this.forCustomer});
  final DebtorUi? forCustomer;

  @override
  ConsumerState<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  String _displayNum = '';
  double _acc = 0;
  String? _pendingOp;
  bool _fresh = true;
  String _expr = '';
  bool _isSubmitting = false;

  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String? _payMethod;

  bool get _hasInput => _displayNum.isNotEmpty && _displayNum != '0';
  String get _displayText => _displayNum.isEmpty ? '0' : _displayNum;
  double get _displayValue => double.tryParse(_displayText) ?? 0;

  void _onKey(String k) {
    setState(() {
      if (k == 'C') {
        _displayNum = ''; _acc = 0; _pendingOp = null; _fresh = true; _expr = '';
      } else if (k == '⌫') {
        _displayNum = _displayNum.length > 1
            ? _displayNum.substring(0, _displayNum.length - 1) : '';
      } else if ('0123456789.'.contains(k)) {
        if (_fresh) { _displayNum = k == '.' ? '0.' : k; _fresh = false; }
        else { if (k == '.' && _displayNum.contains('.')) return; _displayNum += k; }
      } else if (['+', '-', 'x', '/'].contains(k)) {
        final cur = double.tryParse(_displayNum) ?? 0;
        if (_pendingOp != null) {
          _acc = _calc(_acc, cur, _pendingOp!);
          _expr += '$_displayNum$k';
        } else { _acc = cur; _expr = '$_displayNum$k'; }
        _pendingOp = k; _fresh = true; _displayNum = '';
      } else if (k == '=') {
        final cur = double.tryParse(_displayNum) ?? 0;
        if (_pendingOp != null) {
          _acc = _calc(_acc, cur, _pendingOp!);
          _expr += _displayNum;
          _displayNum = _fmtNum(_acc);
          _pendingOp = null; _fresh = true;
        }
      } else if (k == '%') {
        final v = double.tryParse(_displayNum) ?? 0;
        _displayNum = _fmtNum(v / 100);
      }
    });
  }

  double _calc(double a, double b, String op) {
    switch (op) {
      case '+': return a + b;
      case '-': return a - b;
      case 'x': return a * b;
      case '/': return b != 0 ? a / b : 0;
      default: return b;
    }
  }

  String _fmtNum(double v) =>
      v == v.toInt() ? v.toInt().toString() : v.toStringAsFixed(2);

  void _submit() {
    setState(() => _isSubmitting = true);
    if (_pendingOp != null) _onKey('=');
    final amount = _displayValue;
    if (amount <= 0 || widget.forCustomer == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    if (_payMethod == null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد مصدر الدفع: كاش، محفظة، أو بنك فلسطين')),
      );
      return;
    }

    final cid = widget.forCustomer!.id;
    final tx = TransactionUi(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      customerId: cid,
      amount: amount,
      type: TransactionType.received,
      note: _noteCtrl.text.trim(),
      date: _date,
      payMethodId: _payMethod,
    );
    ref.read(transactionsProvider.notifier).addTransaction(tx);
    ref.read(debtorsUiProvider.notifier).updateCustomerBalance(cid, -amount);

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      AppPageRoute(
        builder: (_) => TransactionSuccessScreen(
          customerName: widget.forCustomer!.name,
          amount: amount,
          type: TransactionType.received,
          date: tx.date,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.forCustomer;
    final dateStr =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          c?.name ?? '',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      // في RTL: start = يمين الشاشة
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _displayText,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: AppColors.flowIn,
                              ),
                            ),
                          ),
                          if (_expr.isNotEmpty)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                '$_expr${_fresh ? '' : _displayNum}',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey.shade500),
                              ),
                            ),

                          if (_hasInput) ...[
                            const SizedBox(height: 14),
                            _chip(
                              dateStr,
                              LucideIcons.calendar,
                              () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                builder: (ctx) => SafeArea(
                                  child: Container(
                                    height: 400,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    child: Column(
                                      children: [
                                        // مؤشر السحب (Drag Handle)
                                        Container(
                                          margin: const EdgeInsets.only(top: 12, bottom: 4),
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        Expanded(
                                          child: Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: const ColorScheme.light(
                                                primary: AppColors.primary, // لون التحديد
                                                onSurface: Colors.black87, // لون الأيام
                                              ),
                                            ),
                                            child: CalendarDatePicker(
                                              initialDate: _date,
                                              firstDate: DateTime(2020),
                                              lastDate: DateTime(2100),
                                              onDateChanged: (d) {
                                                setState(() => _date = d);
                                                Navigator.pop(ctx);
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                              labelLtr: true,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.outlineSoft),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                textDirection: TextDirection.rtl,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Icon(
                                      LucideIcons.list,
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _noteCtrl,
                                      textAlign: TextAlign.right,
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                      minLines: 1,
                                      maxLines: 4,
                                      keyboardType: TextInputType.multiline,
                                      decoration: const InputDecoration(
                                        hintText: 'ملاحظة...',
                                        hintStyle: TextStyle(fontSize: 12),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            _chip(
                              'إضافة صورة',
                              LucideIcons.camera,
                              () {},
                              labelLtr: false,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              alignment: WrapAlignment.start,
                              textDirection: TextDirection.rtl,
                              children: [
                                _payChip('كاش', 'cash'),
                                _payChip('محفظة', 'wallet'),
                                _payChip('بنك فلسطين', 'bank'),
                              ],
                            ),
                          ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _hasInput ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successLight,
                  foregroundColor: AppColors.flowIn,
                  disabledBackgroundColor: Colors.grey.shade100,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('تسجيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          if (MediaQuery.of(context).viewInsets.bottom == 0 && !_isSubmitting)
            CalculatorKeypad(onKeyTap: _onKey),
        ],
      ),
    );
  }

  Widget _chip(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool labelLtr = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineSoft),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                textDirection:
                    labelLtr ? TextDirection.ltr : TextDirection.rtl,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _payChip(String label, String id) {
    final sel = _payMethod == id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _payMethod = _payMethod == id ? null : id),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: sel ? AppColors.primary : AppColors.outlineSoft,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
              color: sel ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
