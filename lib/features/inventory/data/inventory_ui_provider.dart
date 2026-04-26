import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import 'product_ui_model.dart';

/// نفس عينات الكاشير + صفوف إضافية للمخزن (لاحقاً: مستودع واحد)
final inventoryCatalogProvider = Provider<List<ProductUi>>((ref) {
  return const [
    ProductUi(
      id: 'p1',
      name: 'زيت دوار الشمس',
      price: '37',
      stock: '28',
      barcode: '6291041500214',
      badge: 'طبيعي',
      badgeColor: AppColors.success,
      dotColor: AppColors.electricBlue,
    ),
    ProductUi(
      id: 'p2',
      name: 'أرز بسمتي',
      price: '29',
      stock: '4',
      barcode: '6281234567890',
      badge: 'منخفض',
      badgeColor: AppColors.warning,
    ),
    ProductUi(
      id: 'p3',
      name: 'حليب',
      price: '6',
      stock: '0',
      barcode: '6222000000000',
      badge: 'نافد',
      badgeColor: AppColors.error,
    ),
  ];
});
