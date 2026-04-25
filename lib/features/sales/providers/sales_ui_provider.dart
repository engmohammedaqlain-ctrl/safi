import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';

class QuickProduct {
  const QuickProduct({
    required this.name,
    required this.price,
    required this.stock,
    required this.color,
  });

  final String name;
  final String price;
  final String stock;
  final Color color;
}

final quickProductsProvider = Provider<List<QuickProduct>>((ref) {
  return const [
    QuickProduct(
      name: 'زيت دوار الشمس',
      price: '37',
      stock: '28',
      color: AppColors.electricBlue,
    ),
    QuickProduct(
      name: 'سكر 1 كغ',
      price: '8',
      stock: '86',
      color: AppColors.neonGreen,
    ),
    QuickProduct(
      name: 'حليب',
      price: '6',
      stock: '52',
      color: AppColors.aiPurple,
    ),
    QuickProduct(
      name: 'أرز',
      price: '29',
      stock: '16',
      color: AppColors.warningAmber,
    ),
  ];
});
