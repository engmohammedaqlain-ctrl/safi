import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../cash_flow/data/financial_account_model.dart';
import '../../cash_flow/providers/accounts_provider.dart';
import '../providers/debts_ui_provider.dart';
import '../widgets/calculator_keypad.dart';
import 'transaction_success_screen.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({super.key, this.forCustomer});
  final DebtorUi? forCustomer;

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
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
  String? _imagePath;

  bool get _hasInput => _displayNum.isNotEmpty && _displayNum != '0';
  String get _displayText => _displayNum.isEmpty ? '0' : _displayNum;
  double get _displayValue => double.tryParse(_displayText) ?? 0;

  void _onKey(String k) {
    setState(() {
      if (k == 'C') {
        _displayNum = '';
        _acc = 0;
        _pendingOp = null;
        _fresh = true;
        _expr = '';
      } else if (k == '⌫') {
        _displayNum = _displayNum.length > 1
            ? _displayNum.substring(0, _displayNum.length - 1)
            : '';
      } else if ('0123456789.'.contains(k)) {
        if (_fresh) {
          _displayNum = k == '.' ? '0.' : k;
          _fresh = false;
        } else {
          if (k == '.' && _displayNum.contains('.')) return;
          _displayNum += k;
        }
      } else if (['+', '-', 'x', '/'].contains(k)) {
        final cur = double.tryParse(_displayNum) ?? 0;
        if (_pendingOp != null) {
          _acc = _calc(_acc, cur, _pendingOp!);
          _expr += '$_displayNum$k';
        } else {
          _acc = cur;
          _expr = '$_displayNum$k';
        }
        _pendingOp = k;
        _fresh = true;
        _displayNum = '';
      } else if (k == '=') {
        final cur = double.tryParse(_displayNum) ?? 0;
        if (_pendingOp != null) {
          _acc = _calc(_acc, cur, _pendingOp!);
          _expr += _displayNum;
          _displayNum = _fmtNum(_acc);
          _pendingOp = null;
          _fresh = true;
        }
      } else if (k == '%') {
        final v = double.tryParse(_displayNum) ?? 0;
        _displayNum = _fmtNum(v / 100);
      }
    });
  }

  double _calc(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case 'x':
        return a * b;
      case '/':
        return b != 0 ? a / b : 0;
      default:
        return b;
    }
  }

  String _fmtNum(double v) =>
      v == v.toInt() ? v.toInt().toString() : v.toStringAsFixed(2);

  void _submit() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    if (_pendingOp != null) _onKey('=');
    final amount = _displayValue;
    if (amount <= 0 || widget.forCustomer == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    if (_payMethod == null) {
      setState(() => _isSubmitting = false);
      showAppSnackBar(context, 'الرجاء اختيار محفظة التسديد');
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
      imagePath: _imagePath,
    );
    // Persist to UI Providers which sync to Local Storage & Firebase automatically
    ref.read(transactionsProvider.notifier).addTransaction(tx);
    ref.read(debtorsUiProvider.notifier).updateCustomerBalance(cid, -amount);

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      TransactionSuccessScreen.route(
        customerName: widget.forCustomer!.name,
        amount: amount,
        type: TransactionType.received,
        date: tx.date,
      ),
    );
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 88,
    );
    if (x != null) setState(() => _imagePath = x.path);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.forCustomer;
    final accounts = ref.watch(accountsProvider);
    final dateStr =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          c?.name ?? 'تحصيل دين',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Input Area
                        GlassCard(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'المبلغ المحصل',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _displayText,
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(
                                      fontSize: 54,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors
                                          .flowIn, // Green because it's collection
                                      letterSpacing: -1,
                                    ),
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.fastOutSlowIn,
                          child: _hasInput
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 24),
                                    Text(
                                      'إلى محفظة:',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (accounts.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: Text(
                                          'لا توجد محافظ. أضف من «المحافظ والبنوك»',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.warning,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        reverse: true,
                                        clipBehavior: Clip.none,
                                        child: Row(
                                          textDirection: TextDirection.rtl,
                                          children: [
                                            for (final a in accounts)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 8,
                                                ),
                                                child: _payChipForAccount(a),
                                              ),
                                          ],
                                        ),
                                      ),

                                    const SizedBox(height: 24),
                                    // Date, Note, Image
                                    Row(
                                      textDirection: TextDirection.rtl,
                                      children: [
                                        Expanded(
                                          child: _actionTile(
                                            dateStr,
                                            LucideIcons.calendarDays,
                                            () {
                                              showDatePicker(
                                                context: context,
                                                initialDate: _date,
                                                firstDate: DateTime(2020),
                                                lastDate: DateTime(2100),
                                                builder: (ctx, child) => Theme(
                                                  data: Theme.of(ctx).copyWith(
                                                    colorScheme:
                                                        const ColorScheme.light(
                                                          primary:
                                                              AppColors.primary,
                                                        ),
                                                  ),
                                                  child: child!,
                                                ),
                                              ).then((d) {
                                                if (d != null)
                                                  setState(() => _date = d);
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _actionTile(
                                            _imagePath == null
                                                ? 'أرفق إيصال'
                                                : 'تم اختيار صورة',
                                            LucideIcons.paperclip,
                                            _pickImage,
                                            isActive: _imagePath != null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.outlineSoft,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.03,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        textDirection: TextDirection.rtl,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 14,
                                            ),
                                            child: Icon(
                                              LucideIcons.penTool,
                                              size: 18,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextField(
                                              controller: _noteCtrl,
                                              textAlign: TextAlign.right,
                                              textDirection: TextDirection.rtl,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                              minLines: 1,
                                              maxLines: 3,
                                              keyboardType:
                                                  TextInputType.multiline,
                                              decoration: InputDecoration(
                                                hintText:
                                                    'اكتب ملاحظة (اختياري)...',
                                                hintStyle: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.textMuted,
                                                ),
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (_imagePath != null && !kIsWeb) ...[
                                      const SizedBox(height: 16),
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Image.file(
                                              File(_imagePath!),
                                              height: 140,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: InkWell(
                                              onTap: () => setState(
                                                () => _imagePath = null,
                                              ),
                                              child: CircleAvatar(
                                                radius: 14,
                                                backgroundColor: Colors.black
                                                    .withValues(alpha: 0.6),
                                                child: const Icon(
                                                  LucideIcons.x,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 32),
                                  ],
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              MediaQuery.of(context).padding.bottom + 10,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _hasInput ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.flowIn, // Green for receiving payment
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.textMuted.withValues(
                    alpha: 0.3,
                  ),
                  elevation: 6,
                  shadowColor: AppColors.flowIn.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'تسجيل التحصيل',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ),
          if (MediaQuery.of(context).viewInsets.bottom == 0 && !_isSubmitting)
            CalculatorKeypad(onKeyTap: _onKey),
        ],
      ),
    );
  }

  Widget _actionTile(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.outlineSoft,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _payChipForAccount(FinancialAccount a) {
    final id = a.id;
    final sel = _payMethod == id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _payMethod = _payMethod == id ? null : id),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 220),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: sel ? AppColors.primary : AppColors.outlineSoft,
              width: sel ? 1.5 : 1,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            a.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: sel ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
