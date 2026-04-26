import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safi_button.dart';
import '../data/inventory_ui_provider.dart';
import '../data/product_ui_model.dart';
import 'add_product_screen.dart';
import 'delete_products_screen.dart';
import 'product_detail_screen.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key, this.bottomContentPadding = 32});

  final double bottomContentPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(inventoryCatalogProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        bottomContentPadding,
      ),
      children: [
        Text('إدارة المخزون', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 6),
        Text('إضافة منتجات، رموز داخلية، وتنبيهات النفاذ', style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'بحث باسم أو رمز...',
                  prefixIcon: Icon(LucideIcons.search, color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SafiIconButton(
              onPressed: () {},
              icon: LucideIcons.listFilter,
            ),
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
        for (final p in catalog)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ProductRowCard(product: p),
          ),
      ],
        ),
      ),
    );
  }
}

class _ProductRowCard extends StatelessWidget {
  const _ProductRowCard({required this.product});

  final ProductUi product;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: GlassCard(
          child: Row(
            children: [
              Icon(product.icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: AppTextStyles.titleSmall),
                    Text(
                      'المخزون: ${product.stock} · ₪ ${product.price}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              if (product.badge != null)
                Flexible(
                  child: Text(
                    product.badge!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: product.badgeColor,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(
                LucideIcons.chevronLeft,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
