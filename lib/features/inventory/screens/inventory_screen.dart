import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safi_button.dart';
import 'add_product_screen.dart';
import 'delete_products_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        100,
      ),
      children: [
        Text('إدارة المخزون', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 6),
        Text('إضافة منتجات، باركود، وتنبيهات النفاذ', style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'بحث باسم أو باركود...',
                  prefixIcon: Icon(LucideIcons.search, color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SafiIconButton(onPressed: () {}, icon: LucideIcons.scanLine),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, c) {
            final narrow = c.maxWidth < 380;
            final add = SafiButton(
              label: 'إضافة منتج',
              icon: LucideIcons.plus,
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AddProductScreen(),
                  ),
                );
              },
            );
            final del = SafiButton(
              label: 'حذف / أرشفة',
              icon: LucideIcons.trash2,
              variant: SafiButtonVariant.outline,
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const DeleteProductsScreen(),
                  ),
                );
              },
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  add,
                  const SizedBox(height: 8),
                  del,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: add),
                const SizedBox(width: 8),
                Expanded(child: del),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          background: AppColors.warning.withValues(alpha: 0.08),
          child: Row(
            children: [
              const Icon(LucideIcons.alertTriangle, color: AppColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '4 منتجات قاربت على النفاذ',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('عرض'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final p in _mock)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
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
                          'المخزون: ${p.qty} · ₪ ${p.price}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Text(
                      p.badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: p.badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Mock {
  const _Mock(this.name, this.qty, this.price, this.badge, this.badgeColor, this.icon);
  final String name;
  final String qty;
  final String price;
  final String badge;
  final Color badgeColor;
  final IconData icon;
}

const _mock = <_Mock>[
  _Mock('زيت دوار الشمس', '28', '37', 'طبيعي', AppColors.success, LucideIcons.package),
  _Mock('أرز بسمتي', '4', '29', 'منخفض', AppColors.warning, LucideIcons.package),
  _Mock('حليب', '0', '6', 'نافد', AppColors.error, LucideIcons.alertCircle),
];
