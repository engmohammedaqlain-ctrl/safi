import 'package:flutter/material.dart';

/// صافي — ثيم فاتح: أبيض + أزرق (بسيط وواضح)
class AppColors {
  AppColors._();

  // ─── الخلفيات / الأسطح (متوافق مع PRD: bgLight) ───
  static const Color background = Color(0xFFF8F8FA);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEDEAFB);

  // حدود وظلال خفيفة
  static const Color outline = Color(0xFFD4D0F0);
  static const Color outlineSoft = Color(0xFFEEEEF4);
  static const Color divider = Color(0xFFE0E7EF);

  // ─── الهوية (PRD: أرجواني هادئ 0xFF7B68EE) ───
  static const Color primary = Color(0xFF7B68EE);
  static const Color primaryLight = Color(0xFF9285F0);
  static const Color primaryDark = Color(0xFF5B4AC7);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // توافق مع الأسماء القديمة
  static const Color electricBlue = primary;
  static const Color glass = Color(0xFFF0EEFF);
  static const Color glassBorder = Color(0xFFC9C0F5);

  // ─── دلالي ───
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFF57C00);
  static const Color neonGreen = success;
  static const Color electricRed = error;
  static const Color warningAmber = warning;
  // ذكاء: بنفسجي مائِل للأزرق يناسب الخلفية الفاتحة
  static const Color aiPurple = Color(0xFF5C6BC0);

  // ─── نصوص ───
  static const Color textPrimary = Color(0xFF0D2137);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textMuted = Color(0xFF78909C);
  static const Color textDisabled = Color(0xFFB0BEC5);

  // ─── تدرجات ───
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8F8FC),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9285F0),
      Color(0xFF7B68EE),
    ],
  );

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5C6BC0),
      Color(0xFF3949AB),
    ],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFC62828)],
  );
}
