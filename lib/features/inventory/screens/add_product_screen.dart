import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safi_button.dart';

/// شاشة إضافة منتج — نموذج إنتاجي
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _name = TextEditingController();
  final _barcode = TextEditingController();
  final _qty = TextEditingController(text: '0');
  final _price = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _barcode.dispose();
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة منتج'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'أدخل بيانات المنتج. يمكنك لاحقاً تعديل الكمية من المخزون.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج',
                    prefixIcon: Icon(LucideIcons.tag, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _barcode,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'الباركود (اختياري)',
                    prefixIcon: Icon(LucideIcons.scanLine, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _qty,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الكمية',
                    prefixIcon: Icon(LucideIcons.layers, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'سعر البيع (₪)',
                    prefixIcon: Icon(LucideIcons.coins, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SafiButton(
            label: 'حفظ المنتج',
            icon: LucideIcons.check,
            onPressed: () {
              if (_name.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال اسم المنتج')),
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
