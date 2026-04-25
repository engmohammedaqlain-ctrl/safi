import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_keys.dart';

/// مراحل دخول المستخدم: شاشة البداية → دخول → إعداد أولي → التطبيق
enum AppSessionPhase {
  /// شعار وتحميل
  splash,

  /// تسجيل دخول (هاتف / OTP) — مرة أو بعد تسجيل خروج
  login,

  /// إعداد أولي للمحل (مرة بعد أول دخول ناجح)
  onboarding,

  /// الشل الرئيسي
  main,
}

final appSessionProvider =
    NotifierProvider<AppSessionNotifier, AppSessionPhase>(AppSessionNotifier.new);

class AppSessionNotifier extends Notifier<AppSessionPhase> {
  @override
  AppSessionPhase build() => AppSessionPhase.splash;

  /// تُستدعى مرة عند عرض [SplashView] (بعد التأخير ينتقل تلقائياً)
  Future<void> completeSplashGate() async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    final p = await SharedPreferences.getInstance();
    final logged = p.getBool(PrefsKeys.loggedIn) ?? false;
    final done = p.getBool(PrefsKeys.onboardingDone) ?? false;
    if (!logged) {
      state = AppSessionPhase.login;
    } else if (!done) {
      state = AppSessionPhase.onboarding;
    } else {
      state = AppSessionPhase.main;
    }
  }

  /// بعد إدخال رقم الهاتف (وتأكيد OTP) — يتبعها الإعداد إن لم يُكمل
  Future<void> onLoginSuccess() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(PrefsKeys.loggedIn, true);
    final ob = p.getBool(PrefsKeys.onboardingDone) ?? false;
    if (!ob) {
      state = AppSessionPhase.onboarding;
    } else {
      state = AppSessionPhase.main;
    }
  }

  /// عند الضغط على «إنهاء» في الإعداد الأولي
  Future<void> onOnboardingComplete() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(PrefsKeys.onboardingDone, true);
    state = AppSessionPhase.main;
  }

  /// تسجيل خروج (من الإعدادات) — يعيد لشاشة الدخول
  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(PrefsKeys.loggedIn, false);
    state = AppSessionPhase.login;
  }
}
