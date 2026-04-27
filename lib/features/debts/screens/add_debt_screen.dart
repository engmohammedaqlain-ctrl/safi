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

class AddDebtScreen extends ConsumerStatefulWidget {
  const AddDebtScreen({super.key, this.forCustomer});

  final DebtorUi? forCustomer;

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
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
    _customerPhoneCtrl.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(debtorsUiProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل دين/سلف')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── قسم العميل ──
          Text('تفاصيل العميل', style: AppTextStyles.titleSmall),
          const SizedBox(height: 6),

          if (widget.forCustomer != null)
            GlassCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: const Icon(LucideIcons.user, color: AppColors.primary),
                ),
                title: Text(
                  widget.forCustomer!.name,
                  style: AppTextStyles.titleSmall,
                ),
                subtitle: const Text('سيتم تقييد الدين على هذا العميل'),
              ),
            )
          else if (_isNewCustomer)
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customerPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الجوال (اختياري)',
                      prefixIcon: Icon(LucideIcons.smartphone, size: 20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _isNewCustomer = false;
                        _customerNameCtrl.clear();
                        _customerPhoneCtrl.clear();
                      }),
                      icon: const Icon(LucideIcons.arrowRight, size: 16),
                      label: const Text('عودة للبحث في العملاء'),
                    ),
                  ),
                ],
              ),
            )
          else
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

          // ── تفاصيل الدين ──
          Text('تفاصيل الدين', style: AppTextStyles.titleSmall),
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
                    labelText: 'مبلغ الدين (₪)',
                    prefixIcon: Icon(LucideIcons.coins, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة (سبب الدين/التفاصيل)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(LucideIcons.fileText, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── طريقة الخروج (من أين تم إخراج المبلغ) ──
          Text(
            'طريقة الدفع (في حال كانت سلفة)',
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: 6),
          AccountSelector(
            selectedAccountId: _paymentMethodId,
            onChanged: (acc) => setState(() => _paymentMethodId = acc.id),
          ),

          const SizedBox(height: AppSpacing.xl),
          SafiButton(
            label: 'تأكيد الدين',
            icon: LucideIcons.check,
            onPressed: () {
              if (_pickedFromList == null &&
                  _customerNameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء تحديد العميل')),
                );
                return;
              }
              if (_amount.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء إدخال مبلغ الدين')),
                );
                return;
              }

              final parsedAmount =
                  double.tryParse(_amount.text.trim()) ?? 0;
              if (parsedAmount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح')),
                );
                return;
              }

              // إذا كان عميل جديد، أنشئه أولًا
              String customerId;
              if (_pickedFromList != null) {
                customerId = _pickedFromList!.id;
              } else {
                customerId =
                    DateTime.now().millisecondsSinceEpoch.toString();
                final newCustomer = DebtorUi(
                  id: customerId,
                  name: _customerNameCtrl.text.trim(),
                  phone: _customerPhoneCtrl.text.trim().isNotEmpty
                      ? '+${_customerPhoneCtrl.text.trim()}'
                      : '',
                  amount: '0.0',
                  status: 'اليوم',
                  urgency: DebtUrgency.low,
                );
                ref
                    .read(debtorsUiProvider.notifier)
                    .addCustomer(newCustomer);
              }

              // أضف المعاملة
              final tx = TransactionUi(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                customerId: customerId,
                amount: parsedAmount,
                type: TransactionType.gave,
                note: _note.text.trim(),
                date: DateTime.now(),
              );
              ref.read(transactionsProvider.notifier).addTransaction(tx);

              // حدّث رصيد العميل (أعطيت = الدين يزيد)
              ref
                  .read(debtorsUiProvider.notifier)
                  .updateCustomerBalance(customerId, parsedAmount);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'تم تسجيل دين ₪ ${parsedAmount.toStringAsFixed(1)}'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
  }
}
