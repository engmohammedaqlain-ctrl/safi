import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../inventory/data/product_ui_model.dart';
import '../../inventory/screens/product_detail_screen.dart';

class ProductQuickTile extends StatelessWidget {
  const ProductQuickTile({super.key, required this.product});

  final ProductUi product;

  @override
  Widget build(BuildContext context) {
    final dot = product.dotColor ?? AppColors.primary;
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dot,
                      boxShadow: [
                        BoxShadow(
                          color: dot.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '₪ ${product.price}',
                style: AppTextStyles.numberMedium,
              ),
              Text('المخزون: ${product.stock}', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
