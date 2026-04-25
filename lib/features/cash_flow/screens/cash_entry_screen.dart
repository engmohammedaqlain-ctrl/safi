import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safi_button.dart';

/// قيد مالي: وارد أو صادر
class CashEntryScreen extends StatefulWidget {
  const CashEntryScreen({super.key, this.initialIncome = true});

  final bool initialIncome;

  @override
  State<CashEntryScreen> createState() => _CashEntryScreenState();
}

class _CashEntryScreenState extends State<CashEntryScreen> {
  late bool _income;
  final _amount = TextEditingController();
  final _label = TextEditingController();
  final _note = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قيد مالي'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'سجّل وارد (بيع نقد) أو صادر (مصروف) ليظهر في التدفق المالي.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('وارد'),
                      icon: Icon(LucideIcons.trendingUp, size: 18),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('صادر'),
                      icon: Icon(LucideIcons.trendingDown, size: 18),
                    ),
                  ],
                  selected: {_income},
                  onSelectionChanged: (s) {
                    setState(() => _income = s.first);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _label,
                  decoration: const InputDecoration(
                    labelText: 'البند (مثال: دفعة نقد، إيجار)',
                    prefixIcon: Icon(LucideIcons.pencil, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'المبلغ (₪)',
                    prefixIcon: Icon(LucideIcons.coins, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(LucideIcons.fileText, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SafiButton(
            label: 'حفظ القيد',
            icon: LucideIcons.check,
            onPressed: () {
              if (_amount.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('أدخل المبلغ')),
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
