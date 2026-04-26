import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
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
      appBar: AppBar(title: const Text('إدارة المخزون')),
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
            // ── شريط بحث سريع ──
            GlassCard(
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(
                    LucideIcons.search,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'بحث عن منتج...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.listFilter, size: 20),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── الإجراءات الرئيسية ──
            Row(
              children: [
                Expanded(
                  child: SafiButton(
                    label: 'إضافة منتج',
                    icon: LucideIcons.plus,
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AddProductScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SafiButton(
                    label: 'حظر / أرشفة',
                    icon: LucideIcons.trash2,
                    variant: SafiButtonVariant.outline,
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const DeleteProductsScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── تنبيهات المخزون ──
            _SectionLabel('تنبيهات'),
            GlassCard(
              padding: const EdgeInsets.all(12),
              background: AppColors.warningLight,
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.alertTriangle,
                      color: AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '4 منتجات قاربت على النفاذ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('عرض'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── قائمة المنتجات ──
            _SectionLabel('قائمة المنتجات (${catalog.length})'),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (int i = 0; i < catalog.length; i++) ...[
                    _ProductRowListTile(product: catalog[i]),
                    if (i < catalog.length - 1)
                      const Divider(height: 1, indent: 52),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _ProductRowListTile extends StatelessWidget {
  const _ProductRowListTile({required this.product});

  final ProductUi product;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: AppRadius.rmd,
        ),
        child: Icon(product.icon, color: AppColors.primary, size: 20),
      ),
      title: Text(product.name, style: AppTextStyles.titleSmall),
      subtitle: Text(
        'المخزون: ${product.stock} · ₪ ${product.price}',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (product.badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: product.badgeColor?.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                product.badge!,
                style: AppTextStyles.labelSmall.copyWith(
                  color: product.badgeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(
            LucideIcons.chevronLeft,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
