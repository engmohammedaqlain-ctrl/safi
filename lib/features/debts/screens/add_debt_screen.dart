import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/vault_branded_shell.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../cash_flow/data/financial_account_model.dart';
import '../../cash_flow/providers/accounts_provider.dart';
import '../providers/debts_ui_provider.dart';
import '../widgets/calculator_keypad.dart';
import 'transaction_success_screen.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  const AddDebtScreen({super.key, this.forCustomer});
  final DebtorUi? forCustomer;

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  // ── حالة الحاسبة (مثل حاسبة المحل) ──
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
        if (_displayNum.length > 1) {
          _displayNum = _displayNum.substring(0, _displayNum.length - 1);
        } else {
          _displayNum = '';
        }
      } else if ('0123456789.'.contains(k)) {
        if (_fresh) {
          _displayNum = (k == '.') ? '0.' : k;
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
      showAppSnackBar(context, 'الرجاء اختيار محفظة من القائمة');
      return;
    }

    final cid = widget.forCustomer!.id;
    final tx = TransactionUi(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      customerId: cid,
      amount: amount,
      type: TransactionType.gave,
      note: _noteCtrl.text.trim(),
      date: _date,
      payMethodId: _payMethod,
      imagePath: _imagePath,
    );
    ref.read(transactionsProvider.notifier).addTransaction(tx);
    ref.read(debtorsUiProvider.notifier).updateCustomerBalance(cid, amount);

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      TransactionSuccessScreen.route(
        customerName: widget.forCustomer!.name,
        amount: amount,
        type: TransactionType.gave,
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: VaultInsetPageShell(
        title: Text(
          c?.name ?? '',
          style: TextStyle(
            fontFamily: AppFonts.family,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const SizedBox(height: 4),

                        // المبلغ
                          Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                _displayText,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  fontFamily: AppFonts.family,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.flowOut,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // المعادلة
                          if (_expr.isNotEmpty)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                '$_expr${_fresh ? '' : _displayNum}',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                    fontFamily: AppFonts.family,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textMuted),
                              ),
                            ),

                          // ── العناصر تظهر فقط عند بدء الإدخال ──
                          if (_hasInput) ...[
                            const SizedBox(height: 10),
                            _chip(
                              dateStr,
                              LucideIcons.calendar,
                              () async {
                              final d = await AppTheme.showAppCalendarPickerSheet(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) setState(() => _date = d);
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
                                        fontFamily: AppFonts.family,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.textSecondary,
                                      ),
                                      minLines: 1,
                                      maxLines: 4,
                                      keyboardType: TextInputType.multiline,
                                      decoration: InputDecoration(
                                        hintText: 'ملاحظة (اختياري)',
                                        hintStyle: TextStyle(
                                          fontFamily: AppFonts.family,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textMuted,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            _chip(
                              _imagePath == null
                                  ? 'إضافة صورة'
                                  : 'تغيير الصورة',
                              LucideIcons.camera,
                              _pickImage,
                              labelLtr: false,
                            ),
                            if (_imagePath != null) ...[
                              const SizedBox(height: 6),
                              if (!kIsWeb)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 108,
                                      height: 64,
                                      child: Image.file(
                                        File(_imagePath!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  'تم اختيار صورة',
                                  style: TextStyle(
                                    fontFamily: AppFonts.family,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'المحفظة',
                                style: TextStyle(
                                  fontFamily: AppFonts.family,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (accounts.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  'لا توجد محافظ. أضف من «المحافظ والبنوك»',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontFamily: AppFonts.family,
                                    fontSize: 12,
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              )
                            else
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                alignment: WrapAlignment.start,
                                textDirection: TextDirection.rtl,
                                children: [
                                  for (final a in accounts) _payChipForAccount(a),
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

          // زر تسجيل
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _hasInput ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorLight,
                  foregroundColor: const Color(0xFFE53935),
                  disabledBackgroundColor: Colors.grey.shade100,
                  disabledForegroundColor: AppColors.textMuted,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'تسجيل',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),

          if (MediaQuery.of(context).viewInsets.bottom == 0 && !_isSubmitting)
            CalculatorKeypad(onKeyTap: _onKey),
        ],
      ),
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.outlineSoft),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                label,
                textDirection:
                    labelLtr ? TextDirection.ltr : TextDirection.rtl,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: const BoxConstraints(maxWidth: 200),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? AppColors.primary : AppColors.outlineSoft,
            ),
          ),
          child: Text(
            a.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: sel ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
