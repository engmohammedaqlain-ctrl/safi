import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../data/product_ui_model.dart';
import 'add_product_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final ProductUi product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'تعديل',
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const AddProductScreen(),
                ),
              );
            },
            icon: const Icon(LucideIcons.pencil, size: 22),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: AppRadius.rlg,
                      ),
                      child: Icon(
                        product.icon,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سعر البيع',
                            style: AppTextStyles.bodySmall,
                          ),
                          Text(
                            '₪ ${product.price}',
                            style: AppTextStyles.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: product.stockStatusColor.withValues(alpha: 0.12),
                        borderRadius: AppRadius.rfull,
                      ),
                      child: Text(
                        product.stockStatusLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: product.stockStatusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _InfoLine(
                  icon: LucideIcons.hash,
                  label: 'الكمية في المخزن',
                  value: product.stock,
                ),
                const SizedBox(height: 8),
                _InfoLine(
                  icon: LucideIcons.hash,
                  label: 'الرمز الداخلي',
                  value: product.internalCode ?? '—',
                ),
                if (product.badge != null) ...[
                  const SizedBox(height: 8),
                  _InfoLine(
                    icon: LucideIcons.info,
                    label: 'تنبيه',
                    value: product.badge!,
                    valueColor: product.badgeColor,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('آخر حركات (تجريبي)', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          GlassCard(
            child: Text(
              'عند الربط مع المخزون الحقيقي يظهر هنا الاستلام والصرف تلقائياً.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTextStyles.bodySmall),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
