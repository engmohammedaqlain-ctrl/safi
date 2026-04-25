import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/bootstrap/app_session.dart';
import 'core/router/main_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

class SafiApp extends ConsumerWidget {
  const SafiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(appSessionProvider);

    final home = switch (phase) {
      AppSessionPhase.splash => const SplashScreen(),
      AppSessionPhase.login => const LoginScreen(),
      AppSessionPhase.onboarding => const OnboardingScreen(),
      AppSessionPhase.main => const MainShell(),
    };

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
      home: home,
    );
  }
}
