import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../debts/widgets/calculator_keypad.dart';
import '../../sales/models/cashbook_entry.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../data/financial_account_model.dart';
import '../providers/accounts_provider.dart';

/// شاشة إدخال دخل/مصروف — تستخدم نفس واجهة لوحة الحاسبة كصفحة «أخذ/أعطى»
class CashEntryScreen extends ConsumerStatefulWidget {
  const CashEntryScreen({
    super.key,
    this.initialIncome = true,
    this.initialAccountId,
  });

  final bool initialIncome;
  final String? initialAccountId;

  @override
  ConsumerState<CashEntryScreen> createState() => _CashEntryScreenState();
}

class _CashEntryScreenState extends ConsumerState<CashEntryScreen> {
  // ── حالة الحاسبة ──
  String _displayNum = '';
  double _acc = 0;
  String? _pendingOp;
  bool _fresh = true;
  String _expr = '';
  bool _isSubmitting = false;

  late bool _income;
  final _noteCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String? _accountId;
  String? _imagePath;
  bool _accountSynced = false;

  @override
  void initState() {
    super.initState();
    _income = widget.initialIncome;
    _accountId = widget.initialAccountId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_accountSynced) return;
    _accountSynced = true;
    final list = ref.read(accountsProvider);
    if (list.isEmpty) return;
    final id = _accountId;
    final valid = id != null && list.any((a) => a.id == id);
    if (!valid) {
      setState(() => _accountId = list.first.id);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  bool get _hasInput => _displayNum.isNotEmpty && _displayNum != '0';

  String get _displayText => _displayNum.isEmpty ? '0' : _displayNum;

  double get _displayValue => double.tryParse(_displayText) ?? 0;

  Color get _accent => _income ? Colors.green : Colors.deepOrange;

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
    if (amount <= 0) {
      setState(() => _isSubmitting = false);
      return;
    }

    final accounts = ref.read(accountsProvider);
    var accId = _accountId;
    if (accId == null && accounts.isNotEmpty) accId = accounts.first.id;
    if (accId == null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أضف محفظة أولاً من «المحافظ والبنوك»'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final note = _noteCtrl.text.trim();
    final cat = _categoryCtrl.text.trim();
    final title = note.isEmpty ? (_income ? 'دخل' : 'مصروف') : note;

    final entry = CashbookEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      isIncome: _income,
      date: _date,
      note: note,
      accountId: accId,
      category: cat.isEmpty ? null : cat,
      imagePath: _imagePath,
    );
    ref.read(cashbookEntriesProvider.notifier).add(entry);

    if (!context.mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 88,
    );
    if (x != null) setState(() => _imagePath = x.path);
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'اليوم';
    }
    return '${d.day}/${d.month}/${d.year}';
  }

  void _pickDate() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 400,
          child: Column(
            children: [
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
                      primary: AppColors.primary,
                      onSurface: Colors.black87,
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
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
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
          title: const Text(
            'حركة جديدة',
            style: TextStyle(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // ── منتقي دخل / مصروف ──
                          Row(
                            children: [
                              Expanded(
                                child: _TypeChip(
                                  label: '+ دخل',
                                  icon: LucideIcons.trendingUp,
                                  color: Colors.green,
                                  selected: _income,
                                  onTap: () =>
                                      setState(() => _income = true),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TypeChip(
                                  label: '− مصروف',
                                  icon: LucideIcons.trendingDown,
                                  color: Colors.deepOrange,
                                  selected: !_income,
                                  onTap: () =>
                                      setState(() => _income = false),
                                ),
                              ),
                            ],
                          ),

                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── المبلغ الكبير ──
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _displayText,
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: _accent,
                                    ),
                                  ),
                                ),

                                // ── المعادلة ──
                                if (_expr.isNotEmpty)
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      '$_expr${_fresh ? '' : _displayNum}',
                                      textDirection: TextDirection.ltr,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),

                                // ── العناصر تظهر فقط عند بدء الإدخال ──
                                if (_hasInput) ...[
                                  const SizedBox(height: 14),
                                  _Chip(
                                    label: _formatDate(_date),
                                    icon: LucideIcons.calendar,
                                    onTap: _pickDate,
                                    labelLtr: true,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.outlineSoft,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      textDirection: TextDirection.rtl,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
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
                                            maxLines: 3,
                                            decoration: const InputDecoration(
                                              hintText: 'ملاحظة / بيان...',
                                              hintStyle: TextStyle(fontSize: 12),
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                vertical: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.outlineSoft,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      textDirection: TextDirection.rtl,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Icon(
                                            LucideIcons.tag,
                                            size: 16,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _categoryCtrl,
                                            textAlign: TextAlign.right,
                                            textDirection: TextDirection.rtl,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                            minLines: 1,
                                            maxLines: 2,
                                            decoration: const InputDecoration(
                                              hintText: 'التصنيف (اختياري)',
                                              hintStyle: TextStyle(fontSize: 12),
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                vertical: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _Chip(
                                    label: _imagePath == null
                                        ? 'إضافة صورة'
                                        : 'تغيير الصورة',
                                    icon: LucideIcons.camera,
                                    onTap: _pickImage,
                                    labelLtr: false,
                                  ),
                                  if (_imagePath != null) ...[
                                    const SizedBox(height: 6),
                                    if (!kIsWeb)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          File(_imagePath!),
                                          height: 88,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      )
                                    else
                                      Text(
                                        'تم اختيار صورة',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                  const SizedBox(height: 6),
                                  if (accounts.isNotEmpty) ...[
                                    const Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'اختر المحفظة',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      reverse: true,
                                      child: Row(
                                        textDirection: TextDirection.rtl,
                                        children: [
                                          for (final a in accounts)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                left: 6,
                                                bottom: 2,
                                              ),
                                              child: _WalletPill(
                                                name: a.name,
                                                icon: a.type.icon,
                                                selected: a.id == _accountId,
                                                onTap: () => setState(
                                                  () => _accountId = a.id,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── زر التسجيل ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _hasInput ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _income
                        ? AppColors.successLight
                        : AppColors.errorLight,
                    foregroundColor: _accent,
                    disabledBackgroundColor: Colors.grey.shade100,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _income ? 'تسجيل الدخل' : 'تسجيل المصروف',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
}

// ════════════════════════════════════════════════════════════════
//  شريحة محفظة (اسم + أيقونة)
// ════════════════════════════════════════════════════════════════
class _WalletPill extends StatelessWidget {
  const _WalletPill({
    required this.name,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outlineSoft,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  منتقي دخل/مصروف
// ════════════════════════════════════════════════════════════════
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.10)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color
                : Colors.grey.shade200,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : Colors.grey.shade500, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Chip صغير (تاريخ / محفظة)
// ════════════════════════════════════════════════════════════════
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.labelLtr = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool labelLtr;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
