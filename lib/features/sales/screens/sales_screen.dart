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
import 'new_sale_screen.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key, this.bottomInset = 0});

  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(quickProductsProvider);
    final w = MediaQuery.sizeOf(context).width;
    final crossAxis = w > 700 ? 3 : 2;
    final bottomPad = 12.0 + bottomInset;

    void push(Widget page) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        bottomPad,
      ),
      children: [
        TextField(
          style: AppTextStyles.bodyLarge,
          decoration: const InputDecoration(
            hintText: 'بحث باسم المنتج أو رقم...',
            prefixIcon: Icon(LucideIcons.search, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const BarcodeCtaButton(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => push(const NewSaleScreen()),
                icon: const Icon(LucideIcons.plusCircle, size: 18),
                label: const Text('بيع جديد'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('استخدم زر المسح أعلاه'),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.scanLine, size: 18),
                label: const Text('باركود'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('إضافة سريعة', style: AppTextStyles.titleSmall),
        const SizedBox(height: 6),
        Text(
          'اضغط على المنتج لعرض صفحته',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
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
                    const SizedBox(height: 2),
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
