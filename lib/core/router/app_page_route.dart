import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════
//  AppPageRoute — انتقال بنكي ناعم: يدخل من اليمين، يخرج لليسار
//  مع تأخير خفيف في البداية يُعطي إحساس الوزن والاحترافية
// ══════════════════════════════════════════════════════════════════════════

class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 2000),
          reverseTransitionDuration: const Duration(milliseconds: 2000),
          transitionsBuilder: _buildTransition,
        );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // ─── منحنى الدخول والخروج: مرونة شديدة وانزلاق بطيء في النهاية ───
    final enterCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.fastLinearToSlowEaseIn,
    );

    final exitCurve = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.fastLinearToSlowEaseIn,
    );

    // في وضع RTL (العربية): Offset(-1.0, 0.0) تعني جسدياً "يمين الشاشة"
    // الدخول: الصفحة الجديدة تنزلق من اليمين إلى اليسار
    final slideIn = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(enterCurve);

    // الخروج: الصفحة السابقة (أو الحالية التي يتم تغطيتها) تنزلق نحو اليسار الجسدي
    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.3, 0.0),
    ).animate(exitCurve);

    // تلاشٍ خفيف للصفحة القادمة في البداية فقط
    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // تلاشٍ للصفحة الخارجة (لا تختفي كلياً لتعطي عمقاً)
    final fadeOut = Tween<double>(begin: 1.0, end: 0.5).animate(exitCurve);

    return SlideTransition(
      position: slideOut,
      child: FadeTransition(
        opacity: fadeOut,
        child: SlideTransition(
          position: slideIn,
          child: FadeTransition(
            opacity: fadeIn,
            child: child,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  PageTransitionsBuilder — يُضبط في ThemeData تلقائياً لكل route
// ══════════════════════════════════════════════════════════════════════════

class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AppPageRoute._buildTransition(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
