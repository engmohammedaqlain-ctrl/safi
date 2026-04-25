import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// نظام الخطوط - يستخدم Cairo كبديل لـ Alexandria حتى يتم إضافتها كـ asset
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base(double size, FontWeight weight, {Color? color}) {
    return GoogleFonts.cairo(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      height: 1.4,
    );
  }

  // العناوين
  static TextStyle displayLarge = _base(32, FontWeight.w900);
  static TextStyle displayMedium = _base(28, FontWeight.w800);
  static TextStyle headlineMedium = _base(26, FontWeight.w800);
  static TextStyle headlineSmall = _base(22, FontWeight.w700);

  // العناوين الفرعية
  static TextStyle titleLarge = _base(20, FontWeight.w700);
  static TextStyle titleMedium = _base(17, FontWeight.w700);
  static TextStyle titleSmall = _base(15, FontWeight.w700);

  // النصوص العامة
  static TextStyle bodyLarge = _base(16, FontWeight.w600);
  static TextStyle bodyMedium = _base(14, FontWeight.w500, color: AppColors.textSecondary);
  static TextStyle bodySmall = _base(13, FontWeight.w500, color: AppColors.textMuted);

  // الملصقات
  static TextStyle labelLarge = _base(14, FontWeight.w700);
  static TextStyle labelMedium = _base(12, FontWeight.w700);
  static TextStyle labelSmall = _base(11, FontWeight.w700);

  /// أنماط للأرقام - دائماً tabular figures + bold
  static TextStyle numberHuge = GoogleFonts.cairo(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.1,
  );

  static TextStyle numberLarge = GoogleFonts.cairo(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.1,
  );

  static TextStyle numberMedium = GoogleFonts.cairo(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
