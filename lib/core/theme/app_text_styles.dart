import 'package:flutter/material.dart';

import 'app_colors.dart';

/// خط ThmanyahSans — عناوين بوسطن واضح (w600) والنص الجاري أوفر.
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

  /// عناوين وعناصر بارزة — موحّد مع بقية التطبيق (بدون Black 900)
  static TextStyle _emphasis(double size, {Color? color}) {
    return TextStyle(
      fontFamily: AppFonts.family,
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textPrimary,
      height: 1.4,
    );
  }

  // العناوين والعناصر البارزة
  static TextStyle displayLarge = _emphasis(32);
  static TextStyle displayMedium = _emphasis(28);
  static TextStyle headlineMedium = _emphasis(26);
  static TextStyle headlineSmall = _emphasis(22);

  static TextStyle titleLarge = _emphasis(20);
  static TextStyle titleMedium = _emphasis(17);
  static TextStyle titleSmall = _emphasis(15);

  // النصوص العامة — Regular
  static TextStyle bodyLarge = _regular(16, FontWeight.w500);
  static TextStyle bodyMedium = _regular(14, FontWeight.w500, color: AppColors.textSecondary);
  static TextStyle bodySmall = _regular(13, FontWeight.w500, color: AppColors.textMuted);

  // ملصقات وواجهة
  static TextStyle labelLarge = _emphasis(14);
  static TextStyle labelMedium = _emphasis(12);
  static TextStyle labelSmall = _emphasis(11);

  /// أرقام — أوزان موحّدة + أرقام ثابتة العرض
  static TextStyle numberHuge = TextStyle(
    fontFamily: AppFonts.family,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.1,
  );

  static TextStyle numberLarge = TextStyle(
    fontFamily: AppFonts.family,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.1,
  );

  static TextStyle numberMedium = TextStyle(
    fontFamily: AppFonts.family,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
