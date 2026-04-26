import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safi_button.dart';
import '../providers/sales_ui_provider.dart';
import '../widgets/product_quick_tile.dart';

/// شبكة المنتجات وملخص السلة — لشاشة «بيع جديد»
class SalesPosCatalog extends ConsumerWidget {
  const SalesPosCatalog({super.key, this.bottomInset = 0});

  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(quickProductsProvider);
    final w = MediaQuery.sizeOf(context).width;
    final crossAxis = w > 700 ? 3 : 2;
    final bottomPad = 12.0 + bottomInset;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomPad,
      ),
      children: [
        Text(
          'نقطة البيع',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.35,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'ابحث باسم المنتج...',
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            prefixIcon: const Icon(
              LucideIcons.search,
              color: AppColors.textMuted,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.rlg,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.rlg,
              borderSide: BorderSide(color: AppColors.outlineSoft),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.rlg,
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'إضافة سريعة للسلة',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.35,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'اضغط على المنتج لعرض التفاصيل',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxis,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, i) =>
              ProductQuickTile(product: products[i]),
        ),
        const SizedBox(height: AppSpacing.xl),
        GlassCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي السلة',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MAD 426',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.flowIn,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SafiButton(
                label: 'إتمام البيع',
                icon: LucideIcons.check,
                isExpanded: false,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
