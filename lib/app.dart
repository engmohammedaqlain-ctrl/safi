import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/bootstrap/app_session.dart';
import 'core/router/main_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/name_setup_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

class SafiApp extends ConsumerWidget {
  const SafiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'صافي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const _SessionRoot(),
    );
  }
}

/// جذر الجلسة: ينقل بين المراحل بانتقال متناغم مع اتجاه RTL.
class _SessionRoot extends ConsumerWidget {
  const _SessionRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(appSessionProvider);

    final body = switch (phase) {
      AppSessionPhase.login => const LoginScreen(),
      AppSessionPhase.nameSetup => const NameSetupScreen(),
      AppSessionPhase.onboarding => const OnboardingScreen(),
      AppSessionPhase.main => const MainShell(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        // في RTL نُدخِل المحتوى الجديد من اليسار (اتجاه القراءة "للأمام").
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final beginX = isRtl ? -0.04 : 0.04;
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(beginX, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(phase),
        child: body,
      ),
    );
  }
}
