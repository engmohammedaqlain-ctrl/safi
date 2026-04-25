import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/metric_stat_card.dart';
import '../../../core/widgets/safi_button.dart';
import '../providers/sales_ui_provider.dart';
import '../widgets/product_quick_tile.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key, this.bottomInset = 100});

  /// هامش سفلي: أكبر داخل الـ MainShell (فوق شريط التنقّل)، أصغر داخل شاشة مضافة
  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(quickProductsProvider);
    final w = MediaQuery.sizeOf(context).width;
    final crossAxis = w > 700 ? 3 : 2;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        bottomInset,
      ),
      children: [
        TextField(
          style: AppTextStyles.bodyLarge,
          decoration: const InputDecoration(
            hintText: 'بحث باسم المنتج أو رقم...',
            prefixIcon: Icon(LucideIcons.search, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const BarcodeCtaButton(),
        const SizedBox(height: AppSpacing.lg),
        Text('إضافة سريعة', style: AppTextStyles.titleSmall),
        const SizedBox(height: 10),
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
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('إجمالي السلة', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Text('₪ 426', style: AppTextStyles.numberLarge),
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
