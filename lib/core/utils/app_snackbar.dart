import 'package:flutter/material.dart';

/// هامش ثابت للـ SnackBar العائم يحترم المنطقة الآمنة السفلية.
EdgeInsets _margin(BuildContext context) {
  final bottom = MediaQuery.paddingOf(context).bottom;
  return EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom);
}

/// رسائل تحقق وتنبيه لا تعيد قياس جسم الـ [Scaffold] ولا تدفع الأزرار السفلية.
void showAppSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: _margin(context),
      backgroundColor: backgroundColor,
      duration: duration,
    ),
  );
}
