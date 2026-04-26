import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../inventory/data/product_ui_model.dart';

/// منتجات سريعة في الكاشير (متوافقة مع `ProductUi` للتفصيل)
final quickProductsProvider = Provider<List<ProductUi>>((ref) {
  return const [
    ProductUi(
      id: 'p1',
      name: 'زيت دوار الشمس',
      price: '37',
      stock: '28',
      barcode: '6291041500214',
      dotColor: AppColors.electricBlue,
    ),
    ProductUi(
      id: 'p2',
      name: 'سكر 1 كغ',
      price: '8',
      stock: '86',
      dotColor: AppColors.neonGreen,
    ),
    ProductUi(
      id: 'p3',
      name: 'حليب',
      price: '6',
      stock: '52',
      dotColor: AppColors.aiPurple,
    ),
    ProductUi(
      id: 'p4',
      name: 'أرز',
      price: '29',
      stock: '16',
      dotColor: AppColors.warningAmber,
    ),
  ];
});
