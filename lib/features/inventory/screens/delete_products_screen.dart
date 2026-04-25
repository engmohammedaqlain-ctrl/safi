import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
// بيانات عرض مؤقتة - في الإنتاج يأتي من مزوّد
List<_Deletable> _items() => [
      _Deletable('زيت دوار الشمس', '28', LucideIcons.package),
      _Deletable('أرز بسمتي', '4', LucideIcons.package),
      _Deletable('حليب', '0', LucideIcons.alertCircle),
    ];

class _Deletable {
  _Deletable(this.name, this.qty, this.icon);
  final String name;
  final String qty;
  final IconData icon;
}

/// حذف أو أرشفة منتجات — مع تأكيد
class DeleteProductsScreen extends StatefulWidget {
  const DeleteProductsScreen({super.key});

  @override
  State<DeleteProductsScreen> createState() => _DeleteProductsScreenState();
}

class _DeleteProductsScreenState extends State<DeleteProductsScreen> {
  late List<_Deletable> _list;

  @override
  void initState() {
    super.initState();
    _list = _items();
  }

  Future<void> _confirmRemove(_Deletable p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المنتج؟'),
        content: Text(
          'سيتم حذف «${p.name}» من القائمة. يمكنك استرجاعه من النسخ الاحتياطي إن وُجد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _list.remove(p);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف ${p.name}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حذف أو أرشفة'),
      ),
      body: _list.isEmpty
          ? Center(
              child: Text(
                'لا توجد منتجات في القائمة',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              itemCount: _list.length,
              separatorBuilder: (_, i) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = _list[i];
                return GlassCard(
                  child: Row(
                    children: [
                      Icon(p.icon, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: AppTextStyles.titleSmall),
                            Text(
                              'المخزون: ${p.qty}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'حذف',
                        onPressed: () => _confirmRemove(p),
                        icon: const Icon(
                          LucideIcons.trash2,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
