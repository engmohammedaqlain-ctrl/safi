import 'package:flutter/material.dart';

/// صافي — هوية أرجوانية مع تباين ألوان صحيح لبقية العناصر
class AppColors {
  AppColors._();

  // ─── أساسيات السطح ───
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F0F7); // بنفسجي خفيف جداً

  static const Color outline = Color(0xFFDDDAE3);
  static const Color outlineSoft = Color(0xFFEDEBF2);
  static const Color divider = Color(0xFFE8E5EF);

  // ─── أرجواني — لون العلامة التجارية ───
  static const Color primary = Color(0xFF6A1B9A);
  static const Color primaryLight = Color(0xFF8E24AA);
  static const Color primaryDark = Color(0xFF4A148C);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color lavender = Color(0xFFF3EEF8); // أفتح وأقل تشبعاً
  static const Color lavenderDeep = Color(0xFFDDD0ED);
  static const Color violet = Color(0xFF8E24AA);
  static const Color plum = Color(0xFF4A148C);

  /// واجهات قديمة اعتمدت «أزرق كهربائي» — يُوجَّه للبنفسجي
  static const Color electricBlue = primary;

  static const Color glass = Color(0xFFF3EEF8);
  static const Color glassBorder = Color(0xFFCEB8DF);

  // ─── تدفق نقدي: ألوان واضحة ومتباينة ───
  /// خروج / مصروف — أحمر-برتقالي
  static const Color flowOut = Color(0xFFB71C1C);

  /// دخول / وارد — أخضر داكن
  static const Color flowIn = Color(0xFF2E7D32);

  // ─── حالات النظام — ألوان صريحة ───
  static const Color success = Color(0xFF2E7D32); // أخضر
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFC62828); // أحمر
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFE65100); // برتقالي
  static const Color warningLight = Color(0xFFFFF3E0);

  // ─── aliases قديمة (للتوافق مع الكود الحالي) ───
  static const Color neonGreen = success;
  static const Color electricRed = error;
  static const Color warningAmber = warning;
  static const Color aiPurple = Color(0xFF5E35B1);

  // ─── نصوص — تباين عالي ───
  static const Color textPrimary = Color(0xFF1A1A2E); // شبه أسود
  static const Color textSecondary = Color(0xFF4A4560); // رمادي-بنفسجي داكن
  static const Color textMuted = Color(0xFF7B7890); // رمادي متوسط
  static const Color textDisabled = Color(0xFFB0AEC0);

  // ─── تدرجات ───
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A)],
  );

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7E57C2), Color(0xFF5E35B1)],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF43A047), Color(0xFF2E7D32)], // أخضر فعلي
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFC62828)], // أحمر فعلي
  );
}
