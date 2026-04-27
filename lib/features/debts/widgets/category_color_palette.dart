import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// لون التصنيف الافتراضي (ARGB32)
int get defaultCategoryColorArgb => AppColors.primary.toARGB32();

/// لوحة ألوان للتصنيفات — تنوّع واضح مع بقاء الهوية البنفسجية لصافي
List<Color> get categoryColorPalette => const [
      Color(0xFF6A1B9A),
      Color(0xFF8E24AA),
      Color(0xFF4A148C),
      Color(0xFFAD1457),
      Color(0xFFD32F2F),
      Color(0xFFFF6F00),
      Color(0xFFF9A825),
      Color(0xFF7CB342),
      Color(0xFF00897B),
      Color(0xFF0277BD),
      Color(0xFF1565C0),
      Color(0xFF4527A0),
      Color(0xFF6D4C41),
      Color(0xFF5D4037),
      Color(0xFF78909C),
      Color(0xFF9E9E9E),
      Color(0xFFE0E0E0),
      Color(0xFFEDE7F6),
    ];
