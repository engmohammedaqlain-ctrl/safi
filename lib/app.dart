import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart' show bootstrapCompleteNotifier;
import 'core/bootstrap/app_session.dart';
import 'core/bootstrap/prefs_keys.dart';
import 'core/router/main_shell.dart';
import 'core/sync/ledger_firestore_sync.dart';
import 'core/sync/ledger_sync_host.dart';
import 'core/sync/post_login_loading.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/name_setup_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

import 'core/services/notification_service.dart';
import 'features/debts/screens/customer_detail_screen.dart';
import 'features/debts/providers/debts_ui_provider.dart';
import 'features/reports/screens/statistics_screen.dart';
import 'features/more/screens/notifications_screen.dart';
import 'features/settings/providers/team_provider.dart';
import 'features/settings/providers/pin_lock_provider.dart';
import 'features/settings/screens/pin_lock_screen.dart';

class SafiApp extends ConsumerStatefulWidget {
  const SafiApp({super.key});

  @override
  ConsumerState<SafiApp> createState() => _SafiAppState();
}

class _SafiAppState extends ConsumerState<SafiApp> {
  @override
  void initState() {
    super.initState();
    // Listen for new invites to show local notifications
    ref.listenManual(pendingInvitesProvider, (prev, next) {
      next.whenData((invites) {
        final prevList = prev?.value ?? [];
        for (final invite in invites) {
          if (!prevList.any((p) => p.id == invite.id)) {
            NotificationService().showInviteNotification(
              storeName: invite.storeName,
              role: invite.role,
            );
          }
        }
      });
    });
    // إن انقطعت جلسة Firebase بينما التطبيق يعتقد أن المستخدم مسجّل — نصحّح الجلسة (وإلا فشل المزامنة).
    ref.listenManual<AsyncValue<User?>>(firebaseAuthStateProvider, (prev, next) {
      if (next case AsyncData<User?>(:final value)) {
        if (value != null) return;
      } else {
        return;
      }
      Future<void>.delayed(const Duration(milliseconds: 700), () async {
        if (!mounted) return;
        if (FirebaseAuth.instance.currentUser != null) return;
        final p = await SharedPreferences.getInstance();
        if (p.getBool(PrefsKeys.loggedIn) == true) {
          await ref.read(appSessionProvider.notifier).logout();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
        } else if (settings.name == '/notifications') {
          return MaterialPageRoute(
            builder: (_) => const NotificationsScreen(),
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

/// جذر الجلسة: يعرض شاشة إقلاع خفيفة حتى تكتمل التهيئة الأساسية، ثم ينقل بين المراحل.
class _SessionRoot extends ConsumerStatefulWidget {
  const _SessionRoot();

  @override
  ConsumerState<_SessionRoot> createState() => _SessionRootState();
}

class _SessionRootState extends ConsumerState<_SessionRoot> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ready = bootstrapCompleteNotifier.value;
    if (!_ready) {
      bootstrapCompleteNotifier.addListener(_onBootstrapDone);
    }
  }

  void _onBootstrapDone() {
    if (!bootstrapCompleteNotifier.value) return;
    bootstrapCompleteNotifier.removeListener(_onBootstrapDone);
    if (!mounted) return;
    // أعد حساب المرحلة بعد اكتمال تحميل البيانات
    ref.invalidate(appSessionProvider);
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    bootstrapCompleteNotifier.removeListener(_onBootstrapDone);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      // شاشة إقلاع خفيفة — نفس ألوان native splash
      return Scaffold(
        backgroundColor: const Color(0xFFF3EFF7),
        body: Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              'ص',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onPrimary,
                fontSize: 52,
                fontWeight: FontWeight.w900,
                fontFamily: AppFonts.family,
                height: 1,
              ),
            ),
          ),
        ),
      );
    }

    final phase = ref.watch(appSessionProvider);

    final body = switch (phase) {
      AppSessionPhase.welcomeOnboarding => const OnboardingScreen(),
      AppSessionPhase.login => const LoginScreen(),
      AppSessionPhase.nameSetup => const NameSetupScreen(),
      AppSessionPhase.main => const _PinLockGate(),
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

/// بوابة قفل PIN — تعرض شاشة القفل فوق المحتوى إذا كان PIN مُفعّلاً
class _PinLockGate extends ConsumerStatefulWidget {
  const _PinLockGate();

  @override
  ConsumerState<_PinLockGate> createState() => _PinLockGateState();
}

class _PinLockGateState extends ConsumerState<_PinLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // عند فتح التطبيق لأول مرة — قفل إن كان مُفعّلاً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pinLockGateProvider.notifier).lockIfEnabled();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // عند العودة من الخلفية — أعد القفل
    if (state == AppLifecycleState.resumed) {
      ref.read(pinLockGateProvider.notifier).lockIfEnabled();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(pinLockGateProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        const _MainLoadedGate(),
        if (isLocked)
          const Positioned.fill(
            child: PinLockScreen(),
          ),
      ],
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

    if (loading) {
      Future.delayed(const Duration(seconds: 10), () {
        if (context.mounted && ref.read(postLoginLedgerLoadingProvider)) {
          ref.read(postLoginLedgerLoadingProvider.notifier).setLoading(false);
        }
      });
    }

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
