import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safi_button.dart';
import '../providers/debts_ui_provider.dart';

/// تسجيل دفعة. [forCustomer] عند فتحها من صفحة الزبون — لا حاجة لكتابة الاسم.
class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({super.key, this.forCustomer});

  final DebtorUi? forCustomer;

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _customer = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  bool _lockCustomer = false;
  DebtorUi? _pickedFromList;

  @override
  void initState() {
    super.initState();
    final c = widget.forCustomer;
    if (c != null) {
      _customer.text = c.name;
      _lockCustomer = true;
    }
  }

  @override
  void dispose() {
    _customer.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _selectDebtor(DebtorUi d) {
    setState(() {
      _pickedFromList = d;
      _customer.text = d.name;
      _lockCustomer = true;
    });
  }

  void _clearPickUseManual() {
    setState(() {
      _pickedFromList = null;
      if (widget.forCustomer == null) {
        _customer.clear();
        _lockCustomer = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(debtorsUiProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل دفعة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            _lockCustomer
                ? 'الدفعة تُسجّل لصالح نفس العميل المعروض.'
                : 'اختر من عملائك أو اكتب اسم العميل.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.forCustomer == null) ...[
            Text('لأي عميل؟', style: AppTextStyles.titleSmall),
            const SizedBox(height: 6),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.users, size: 20),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DebtorUi>(
                        isExpanded: true,
                        value: _pickedFromList,
                        hint: const Text('اختر عميلاً مسجّلاً (اختياري)'),
                        items: all
                            .map(
                              (d) => DropdownMenuItem<DebtorUi>(
                                value: d,
                                child: Text(
                                  d.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (d) {
                          if (d != null) _selectDebtor(d);
                        },
                      ),
                    ),
                  ),
                  if (_pickedFromList != null)
                    TextButton(
                      onPressed: _clearPickUseManual,
                      child: const Text('عميل غير مُدرج؟ أدخل الاسم يدوياً'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_lockCustomer) ...[
            GlassCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.success.withValues(alpha: 0.12),
                  child: const Icon(
                    LucideIcons.user,
                    color: AppColors.success,
                  ),
                ),
                title: Text(
                  _customer.text,
                  style: AppTextStyles.titleSmall,
                ),
                trailing: widget.forCustomer == null
                    ? TextButton(
                        onPressed: _clearPickUseManual,
                        child: const Text('تغيير'),
                      )
                    : null,
              ),
            ),
          ] else
            GlassCard(
              child: TextField(
                controller: _customer,
                decoration: const InputDecoration(
                  labelText: 'اسم العميل',
                  prefixIcon: Icon(LucideIcons.user, size: 20),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
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
                    prefixIcon: Icon(LucideIcons.wallet, size: 20),
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
          const SizedBox(height: AppSpacing.xl),
          SafiButton(
            label: 'تأكيد الدفعة',
            icon: LucideIcons.check,
            onPressed: () {
              if (_customer.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('حدد العميل أو اسمه')),
                );
                return;
              }
              if (_amount.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('أدخل مبلغ الدفعة')),
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
