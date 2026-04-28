import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_keys.dart';
import 'startup_ledger_data.dart';

/// مراحل دخول المستخدم: دخول → اسم → إعداد أولي → التطبيق.
/// لا توجد مرحلة splash داخلية — شاشة النظام تغطّي الإقلاع.
enum AppSessionPhase {
  /// تسجيل دخول (هاتف / OTP) — مرة أو بعد تسجيل خروج
  login,

  /// تعيين اسم المستخدم (بعد الدخول لأول مرة)
  nameSetup,

  /// إعداد أولي للمحل (مرة بعد أول دخول ناجح)
  onboarding,

  /// الشل الرئيسي
  main,
}

final appSessionProvider =
    NotifierProvider<AppSessionNotifier, AppSessionPhase>(AppSessionNotifier.new);

class AppSessionNotifier extends Notifier<AppSessionPhase> {
  @override
  AppSessionPhase build() {
    // البيانات مُحمّلة قبل runApp في `main()` — نحسم المرحلة فوراً بدون انتظار.
    final logged = StartupLedgerData.bootstrapLoggedIn;
    final hasName = StartupLedgerData.bootstrapUserName != null;
    final done = StartupLedgerData.bootstrapOnboardingDone;
    if (!logged) return AppSessionPhase.login;
    if (!hasName) return AppSessionPhase.nameSetup;
    if (!done) return AppSessionPhase.onboarding;
    return AppSessionPhase.main;
  }

  /// بعد إدخال رقم الهاتف (وتأكيد OTP) — يتبعها إدخال الاسم
  Future<void> onLoginSuccess() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(PrefsKeys.loggedIn, true);
    final hasName = p.getString(PrefsKeys.userName) != null;
    if (!hasName) {
      state = AppSessionPhase.nameSetup;
    } else {
      final ob = p.getBool(PrefsKeys.onboardingDone) ?? false;
      if (!ob) {
        state = AppSessionPhase.onboarding;
      } else {
        state = AppSessionPhase.main;
      }
    }
  }

  /// بعد كتابة الاسم
  Future<void> saveName(String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(PrefsKeys.userName, name);
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
