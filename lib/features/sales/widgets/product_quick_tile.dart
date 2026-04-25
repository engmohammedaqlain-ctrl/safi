import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/sales_ui_provider.dart';

class ProductQuickTile extends StatelessWidget {
  const ProductQuickTile({super.key, required this.product});

  final QuickProduct product;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
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
                  color: product.color,
                  boxShadow: [
                    BoxShadow(
                      color: product.color.withValues(alpha: 0.6),
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
    );
  }
}
