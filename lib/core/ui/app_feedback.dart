import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// إشعار سفلي عائم بعيداً عن المركز ومتماشٍ مع ثيم الصافي.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 4),
}) {
  final bottom = MediaQuery.paddingOf(context).bottom;
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isError
          ? const Color(0xFF1E1A26)
          : AppColors.primary.withValues(alpha: 0.96),
      content: Text(
        message,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          height: 1.35,
          color: isError
              ? Colors.white.withValues(alpha: 0.94)
              : AppColors.onPrimary,
        ),
      ),
      duration: duration,
    ),
  );
}

String userFacingPdfError(Object error) {
  debugPrint('[PDF] $error');
  if (error is StateError) {
    final m = error.message;
    if (m.isNotEmpty) return m;
  }
  return 'تعذّر إنشاء ملف التقرير.';
}
