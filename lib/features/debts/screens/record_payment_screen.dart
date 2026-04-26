import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/account_selector.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safi_button.dart';
import '../providers/debts_ui_provider.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({super.key, this.forCustomer});

  final DebtorUi? forCustomer;

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _customerNameCtrl = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  DebtorUi? _pickedFromList;
  bool _isNewCustomer = false;
  String? _paymentMethodId;

  @override
  void initState() {
    super.initState();
    final c = widget.forCustomer;
    if (c != null) {
      _pickedFromList = c;
    }
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(debtorsUiProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل دفعة')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── قسم العميل ──
          Text('تفاصيل العميل', style: AppTextStyles.titleSmall),
          const SizedBox(height: 6),

          if (widget.forCustomer != null)
            // عميل مقفل من ملفه الشخصي
            GlassCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.success.withValues(alpha: 0.12),
                  child: const Icon(LucideIcons.user, color: AppColors.success),
                ),
                title: Text(
                  widget.forCustomer!.name,
                  style: AppTextStyles.titleSmall,
                ),
                subtitle: const Text('الدفعة ترتبط بهذا العميل تلقائياً'),
              ),
            )
          else if (_isNewCustomer)
            // إدخال عميل جديد
            GlassCard(
              child: Column(
                children: [
                  TextField(
                    controller: _customerNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم العميل الجديد',
                      prefixIcon: Icon(LucideIcons.userPlus, size: 20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _isNewCustomer = false;
                        _customerNameCtrl.clear();
                      }),
                      icon: const Icon(LucideIcons.arrowRight, size: 16),
                      label: const Text('عودة للبحث في العملاء'),
                    ),
                  ),
                ],
              ),
            )
          else
            // اختيار / بحث عن عميل موجود
            GlassCard(
              child: Column(
                children: [
                  InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.search, size: 20),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DebtorUi>(
                        isExpanded: true,
                        value: _pickedFromList,
                        hint: const Text('ابحث أو اختر عميلاً...'),
                        items: all
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(d.name),
                              ),
                            )
                            .toList(),
                        onChanged: (d) => setState(() => _pickedFromList = d),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _isNewCustomer = true;
                        _pickedFromList = null;
                      }),
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('إضافة عميل جديد'),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.lg),

          // ── تفاصيل الدفعة ──
          Text('تفاصيل الدفعة', style: AppTextStyles.titleSmall),
          const SizedBox(height: 6),
          GlassCard(
            child: Column(
              children: [
                TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'مبلغ الدفعة (₪)',
                    prefixIcon: Icon(LucideIcons.coins, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة (اختياري)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(LucideIcons.fileText, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── طريقة الدفع ──
          Text('كيف استلمت الدفعة؟', style: AppTextStyles.titleSmall),
          const SizedBox(height: 6),
          AccountSelector(
            selectedAccountId: _paymentMethodId,
            onChanged: (acc) => setState(() => _paymentMethodId = acc.id),
          ),

          const SizedBox(height: AppSpacing.xl),
          SafiButton(
            label: 'تأكيد الدفعة',
            icon: LucideIcons.check,
            onPressed: () {
              if (_pickedFromList == null &&
                  _customerNameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء اختيار أو إدخال اسم العميل'),
                  ),
                );
                return;
              }
              if (_amount.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء إدخال مبلغ الدفعة')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
  }
}
