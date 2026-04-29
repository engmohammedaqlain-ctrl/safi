import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/bootstrap/app_session.dart';
import 'core/router/main_shell.dart';
import 'core/sync/ledger_sync_host.dart';
import 'core/sync/post_login_loading.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/name_setup_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

import 'core/services/notification_service.dart';
import 'features/debts/screens/customer_detail_screen.dart';
import 'features/debts/providers/debts_ui_provider.dart';
import 'features/reports/screens/statistics_screen.dart';

class SafiApp extends ConsumerWidget {
  const SafiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'الصافي',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService().navigatorKey,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: (settings) {
        if (settings.name == '/customer') {
          final id = settings.arguments as String;
          final debtor = ref.read(debtorByIdProvider(id));
          if (debtor != null) {
            return MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(debtor: debtor),
            );
          }
        } else if (settings.name == '/statistics') {
          return MaterialPageRoute(
            builder: (_) => const StatisticsScreen(),
          );
        }
        return null;
      },
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const LedgerSyncHost(child: _SessionRoot()),
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
      AppSessionPhase.main => const _MainLoadedGate(),
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
      child: KeyedSubtree(key: ValueKey(phase), child: body),
    );
  }
}

/// انتظار أوّل جلب من Firebase بعد الدخول (يُزاد من شاشة تسجيل الدخول).
class _MainLoadedGate extends ConsumerWidget {
  const _MainLoadedGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(postLoginLedgerLoadingProvider);
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        const MainShell(),
        if (loading)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.42),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 18),
                      Text(
                        'جاري تحميل البيانات…',
                        style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ) ??
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
