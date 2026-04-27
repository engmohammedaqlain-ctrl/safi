import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════
//  AppPageRoute — منزلق سريع خفيف (لا يبطئ التنقّل بين الصفحات)
// ══════════════════════════════════════════════════════════════════════════

class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: _buildTransition,
        );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    // RTL: دخول من اليمين (Offset سلبي x)
    final slideIn = Tween<Offset>(
      begin: const Offset(-0.06, 0.0),
      end: Offset.zero,
    ).animate(enter);
    return FadeTransition(
      opacity: enter,
      child: SlideTransition(
        position: slideIn,
        child: child,
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
