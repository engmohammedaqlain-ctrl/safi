import 'package:flutter/material.dart';

import 'app_colors.dart';

/// خط ThmanyahSans محلي حصريًا — الأسود للعناوين والمسائل المهمة، العادي للنص الجاري.
abstract final class AppFonts {
  static const family = 'ThmanyahSans';
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _regular(double size, FontWeight weight, {Color? color}) {
    return TextStyle(
      fontFamily: AppFonts.family,
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      height: 1.4,
    );
  }

  static TextStyle _black(double size, {Color? color}) {
    return TextStyle(
      fontFamily: AppFonts.family,
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color ?? AppColors.textPrimary,
      height: 1.4,
    );
  }

  // العناوين والعناصر البارزة
  static TextStyle displayLarge = _black(32);
  static TextStyle displayMedium = _black(28);
  static TextStyle headlineMedium = _black(26);
  static TextStyle headlineSmall = _black(22);

  static TextStyle titleLarge = _black(20);
  static TextStyle titleMedium = _black(17);
  static TextStyle titleSmall = _black(15);

  // النصوص العامة — Regular
  static TextStyle bodyLarge = _regular(16, FontWeight.w600);
  static TextStyle bodyMedium = _regular(14, FontWeight.w500, color: AppColors.textSecondary);
  static TextStyle bodySmall = _regular(13, FontWeight.w500, color: AppColors.textMuted);

  // ملصقات وواجهة — أسود بوضوح ضمن الواجهة
  static TextStyle labelLarge = _black(14);
  static TextStyle labelMedium = _black(12);
  static TextStyle labelSmall = _black(11);

  /// أرقام — وزن ثقيل + أرقام ثابتة العرض
  static TextStyle numberHuge = TextStyle(
    fontFamily: AppFonts.family,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.1,
  );

  static TextStyle numberLarge = TextStyle(
    fontFamily: AppFonts.family,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.1,
  );

  static TextStyle numberMedium = TextStyle(
    fontFamily: AppFonts.family,
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
