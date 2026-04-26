import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';

/// نموذج عرض موحّد للمنتج (قائمة + تفصيل + كاشير)
class ProductUi {
  const ProductUi({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.barcode,
    this.badge,
    this.badgeColor,
    this.dotColor,
    this.icon = LucideIcons.package,
  });

  final String id;
  final String name;
  final String price;
  final String stock;
  final String? barcode;
  final String? badge;
  final Color? badgeColor;
  final Color? dotColor;
  final IconData icon;
}

String _stockStatusLabel(String stock) {
  final n = int.tryParse(stock) ?? 0;
  if (n <= 0) return 'نافد';
  if (n < 6) return 'منخفض';
  if (n < 12) return 'طبيعي';
  return 'متوفر';
}

Color _stockStatusColor(String stock) {
  final n = int.tryParse(stock) ?? 0;
  if (n <= 0) return AppColors.error;
  if (n < 6) return AppColors.warning;
  return AppColors.success;
}

extension ProductUiLabels on ProductUi {
  String get stockStatusLabel => _stockStatusLabel(stock);
  Color get stockStatusColor => _stockStatusColor(stock);
}
