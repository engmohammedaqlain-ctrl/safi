import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safi_button.dart';
import '../providers/debts_ui_provider.dart';

/// تسجيل دين جديد. [forCustomer] عند فتح الشاشة من ملف الزبون — لا حاجة لإعادة إدخال الاسم.
class AddDebtScreen extends ConsumerStatefulWidget {
  const AddDebtScreen({super.key, this.forCustomer});

  /// عند الضبط: يُربط الدين بهذا العميل ويُقفل حقل اسم العميل
  final DebtorUi? forCustomer;

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  bool _lockCustomer = false;
  DebtorUi? _pickedFromList;

  @override
  void initState() {
    super.initState();
    final c = widget.forCustomer;
    if (c != null) {
      _name.text = c.name;
      _phone.text = c.phone;
      _lockCustomer = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _selectDebtor(DebtorUi d) {
    setState(() {
      _pickedFromList = d;
      _name.text = d.name;
      _phone.text = d.phone;
      _lockCustomer = true;
    });
  }

  void _clearPickUseManual() {
    setState(() {
      _pickedFromList = null;
      if (widget.forCustomer == null) {
        _name.clear();
        _phone.clear();
        _lockCustomer = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(debtorsUiProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل دين'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            _lockCustomer
                ? 'الدين سيُسجّل للعميل المحدد أدناه.'
                : 'اختر عميلاً مسجّلاً أو أدخل بيانات عميل جديد لربط الدين.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.forCustomer == null) ...[
            Text('ربط بعميل', style: AppTextStyles.titleSmall),
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
                        hint: const Text('اختر من عملائك المسجّلين (اختياري)'),
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
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: _clearPickUseManual,
                        child: const Text('ليس مُدرجاً؟ إدخال عميل جديد'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_lockCustomer) ...[
            Text('العميل', style: AppTextStyles.titleSmall),
            const SizedBox(height: 6),
            GlassCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(LucideIcons.user, color: AppColors.primary),
                ),
                title: Text(_name.text, style: AppTextStyles.titleSmall),
                subtitle: Text(
                  _phone.text.isNotEmpty ? _phone.text : 'بدون رقم',
                  style: AppTextStyles.bodySmall,
                ),
                trailing: widget.forCustomer == null
                    ? TextButton(
                        onPressed: _clearPickUseManual,
                        child: const Text('تغيير'),
                      )
                    : null,
              ),
            ),
          ] else ...[
            GlassCard(
              child: Column(
                children: [
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'اسم العميل',
                      prefixIcon: Icon(LucideIcons.user, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الجوال (اختياري)',
                      prefixIcon: Icon(LucideIcons.smartphone, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
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
            label: 'حفظ الدين',
            icon: LucideIcons.check,
            onPressed: () {
              if (_name.text.trim().isEmpty || _amount.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الاسم والمبلغ مطلوبان'),
                  ),
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
