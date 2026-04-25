import 'package:flutter/material.dart';

/// صافي — ثيم فاتح: أبيض + أزرق (بسيط وواضح)
class AppColors {
  AppColors._();

  // ─── الخلفيات / الأسطح ───
  static const Color background = Color(0xFFF5F8FC);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8F1FA);

  // حدود وظلال خفيفة
  static const Color outline = Color(0xFFBBDEFB);
  static const Color outlineSoft = Color(0xFFE3F2FD);
  static const Color divider = Color(0xFFE0E7EF);

  // ─── الأزرق (الهوية) ───
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // توافق مع الأسماء القديمة
  static const Color electricBlue = primary;
  static const Color glass = Color(0xFFE3F2FD);
  static const Color glassBorder = Color(0xFF90CAF9);

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
      Color(0xFFF0F6FF),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1976D2),
      Color(0xFF1565C0),
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
