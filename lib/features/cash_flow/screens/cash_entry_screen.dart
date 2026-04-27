import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/account_selector.dart';
import '../../../core/widgets/safi_button.dart';
import '../../cash_flow/providers/accounts_provider.dart';
import '../../sales/models/cashbook_entry.dart';
import '../../sales/providers/cashbook_ui_provider.dart';

class CashEntryScreen extends ConsumerStatefulWidget {
  const CashEntryScreen({super.key, this.initialIncome = true});

  final bool initialIncome;

  @override
  ConsumerState<CashEntryScreen> createState() => _CashEntryScreenState();
}

class _CashEntryScreenState extends ConsumerState<CashEntryScreen> {
  late bool _income;
  final _amount = TextEditingController();
  final _label = TextEditingController();
  final _note = TextEditingController();
  String? _paymentMethodId;

  @override
  void initState() {
    super.initState();
    _income = widget.initialIncome;
  }

  @override
  void dispose() {
    _amount.dispose();
    _label.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _amount.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل المبلغ')),
      );
      return;
    }
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مبلغ غير صالح')),
      );
      return;
    }
    final accounts = ref.read(accountsProvider);
    var accId = _paymentMethodId;
    if (accId == null && accounts.isNotEmpty) {
      accId = accounts.first.id;
    }
    if (accId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف حساباً من «إدارة الحسابات» أولاً')),
      );
      return;
    }
    final title = _label.text.trim().isEmpty ? 'حركة نقدية' : _label.text.trim();
    final entry = CashbookEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      amount: value,
      isIncome: _income,
      date: DateTime.now(),
      note: _note.text.trim(),
      accountId: accId,
    );
    ref.read(cashbookEntriesProvider.notifier).add(entry);
    if (!context.mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_income ? '+ دخل جديد' : '- مصروف جديد')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: _TypeChip(
                  label: '+ دخل',
                  icon: LucideIcons.trendingUp,
                  selected: _income,
                  color: AppColors.success,
                  onTap: () => setState(() => _income = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TypeChip(
                  label: '- مصروف',
                  icon: LucideIcons.trendingDown,
                  selected: !_income,
                  color: AppColors.error,
                  onTap: () => setState(() => _income = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _label,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'البند (مثال: بيع نقد، إيجار)',
              prefixIcon: Icon(LucideIcons.pencil, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'المبلغ',
              prefixIcon: const Icon(LucideIcons.coins, size: 20),
              suffixText: _income ? '+ ₪' : '- ₪',
              suffixStyle: TextStyle(
                color: _income ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w700,
              ),
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
          const SizedBox(height: 16),
          Text('أين تمت الحركة؟', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          AccountSelector(
            selectedAccountId: _paymentMethodId,
            onChanged: (acc) => setState(() => _paymentMethodId = acc.id),
          ),
          const SizedBox(height: AppSpacing.xl),
          SafiButton(
            label: _income ? 'حفظ الوارد' : 'حفظ المصروف',
            icon: LucideIcons.check,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.1)
              : AppColors.backgroundSecondary,
          borderRadius: AppRadius.rlg,
          border: Border.all(
            color: selected ? color : AppColors.outline.withValues(alpha: 0.6),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppColors.textMuted, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: selected ? color : AppColors.textMuted,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
