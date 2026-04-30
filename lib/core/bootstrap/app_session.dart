import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_keys.dart';
import 'startup_ledger_data.dart';
import '../router/main_shell.dart' as main_shell_router;
import '../router/nav_provider.dart';
import '../sync/ledger_firestore_sync.dart';
import '../sync/post_login_loading.dart';
import '../../features/cash_flow/providers/accounts_provider.dart';
import '../../features/debts/providers/debt_categories_provider.dart';
import '../../features/debts/providers/debts_ui_provider.dart';
import '../../features/sales/providers/cashbook_ui_provider.dart';
import '../../features/settings/providers/team_provider.dart';

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
    NotifierProvider<AppSessionNotifier, AppSessionPhase>(
      AppSessionNotifier.new,
    );

class AppSessionNotifier extends Notifier<AppSessionPhase> {
  @override
  AppSessionPhase build() {
    // البيانات مُحمّلة قبل runApp في `main()` — نحسم المرحلة فوراً بدون انتظار.
    final logged = StartupLedgerData.bootstrapLoggedIn;
    final nameRaw = StartupLedgerData.bootstrapUserName?.trim();
    final hasName = nameRaw != null && nameRaw.isNotEmpty;
    final done = StartupLedgerData.bootstrapOnboardingDone;
    if (!logged) return AppSessionPhase.login;
    if (!hasName) return AppSessionPhase.nameSetup;
    if (!done) return AppSessionPhase.onboarding;
    return AppSessionPhase.main;
  }

  /// بعد إدخال رقم الهاتف (وتأكيد OTP).
  ///
  /// [displayNameFromFirestore]: من مستند `registered_phones/{doc}` إذا وُجد.
  Future<void> onLoginSuccess({
    required String phoneDocId,
    String? displayNameFromFirestore,
    String? ownerUidOverride,
    String? role,
    List<String>? permissions,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(PrefsKeys.loggedIn, true);
    await p.setString(PrefsKeys.phoneDocId, phoneDocId);

    final resolvedRole = role ?? 'owner';
    final resolvedPerms = List<String>.from(permissions ?? []);

    await p.setString(PrefsKeys.userRole, resolvedRole);
    await p.setStringList(PrefsKeys.userPermissions, resolvedPerms);

    // ◀ تحديث فوري للواجهة قبل أي await آخر
    ref
        .read(userRoleNotifierProvider.notifier)
        .setRole(resolvedRole, resolvedPerms);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final targetUid = ownerUidOverride ?? uid;
      final storedOwner = p.getString(PrefsKeys.ledgerOwnerUid);
      if (storedOwner != targetUid) {
        await StartupLedgerData.wipeLocalLedgerStorageAndPersist();
        await p.setString(PrefsKeys.ledgerOwnerUid, targetUid);
        await StartupLedgerData.reloadFromDiskIntoMemory();
        _invalidateLedgerUi();

        // ◀ إعادة المزامنة مع Firestore لجلب بيانات المالك الجديد
        try {
          final sync = ref.read(ledgerFirestoreSyncProvider);
          await sync.detach();
          await sync.attachIfNeeded(targetUid);
        } catch (e) {
          debugPrint('AppSession: re-sync after ownerUid change: $e');
        }
      }
    }
    final trimmedRemote = displayNameFromFirestore?.trim();
    final existingName = p.getString(PrefsKeys.userName)?.trim();
    if ((existingName == null || existingName.isEmpty) &&
        trimmedRemote != null &&
        trimmedRemote.isNotEmpty) {
      await p.setString(PrefsKeys.userName, trimmedRemote);
    }
    await StartupLedgerData.refreshCachedUserName();
    final display = (p.getString(PrefsKeys.userName) ?? '').trim();
    ref
        .read(main_shell_router.displayStoreNameProvider.notifier)
        .setFromSavedName(display);
    _invalidateTeamProviders();
    await _advanceAfterName(p);
  }

  void _invalidateTeamProviders() {
    // reload() يُعيد القراءة من Prefs ويُحدّث الـ state
    ref.read(userRoleNotifierProvider.notifier).reload();
    ref.invalidate(teamMembersProvider);
    ref.invalidate(pendingInvitesProvider);
    ref.invalidate(canManageTeamProvider);
  }

  /// تحديث منطق المرحلة بعد أي تغيير في الاسم المخزّن.
  Future<void> _advanceAfterName(SharedPreferences p) async {
    final name = (p.getString(PrefsKeys.userName) ?? '').trim();
    final ob = p.getBool(PrefsKeys.onboardingDone) ?? false;
    if (name.isEmpty) {
      state = AppSessionPhase.nameSetup;
    } else if (!ob) {
      state = AppSessionPhase.onboarding;
    } else {
      state = AppSessionPhase.main;
    }
  }

  /// بعد كتابة الاسم — يُحدَّث المستند السحابي إن رُبط بحساب هاتف.
  Future<void> saveName(String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(PrefsKeys.userName, name);
    await StartupLedgerData.refreshCachedUserName();
    ref
        .read(main_shell_router.displayStoreNameProvider.notifier)
        .setFromSavedName(name);
    final docId = p.getString(PrefsKeys.phoneDocId);
    if (docId != null && docId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('registered_phones')
            .doc(docId)
            .set({'displayName': name}, SetOptions(merge: true));
      } catch (_) {}
    }
    await _advanceAfterName(p);
    ref.invalidate(main_shell_router.userNameProvider);
    ref.invalidate(main_shell_router.storeCardDisplayProvider);
  }

  /// عند الضغط على «إنهاء» في الإعداد الأولي
  Future<void> onOnboardingComplete() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(PrefsKeys.onboardingDone, true);
    state = AppSessionPhase.main;
  }

  /// تسجيل خروج — يمسح المحتوى المحلي المرتبط بالحساب ويعيد لوحة إدخال الرقم.
  Future<void> logout() async {
    // أولاً: تحديث فوري للواجهة
    ref.read(userRoleNotifierProvider.notifier).setRole('owner', []);

    await StartupLedgerData.wipeLocalLedgerStorageAndPersist();

    final p = await SharedPreferences.getInstance();
    await p.setBool(PrefsKeys.loggedIn, false);
    await p.remove(PrefsKeys.phoneDocId);
    await p.remove(PrefsKeys.ledgerOwnerUid);
    await p.remove(PrefsKeys.userName);
    await p.remove(PrefsKeys.storeCurrencyLabel);
    await p.remove(PrefsKeys.storeAddress);
    await p.remove(PrefsKeys.onboardingDone);
    await p.remove(PrefsKeys.userRole);
    await p.remove(PrefsKeys.userPermissions);

    await StartupLedgerData.reloadFromDiskIntoMemory();

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    ref.read(postLoginLedgerLoadingProvider.notifier).setLoading(false);

    _invalidateLedgerUi();
    ref.invalidate(main_shell_router.userNameProvider);
    ref.invalidate(main_shell_router.storeCardDisplayProvider);
    ref.invalidate(main_shell_router.displayStoreNameProvider);
    _invalidateTeamProviders();
    ref.invalidate(ledgerSyncUiProvider);

    state = AppSessionPhase.login;
  }

  void _invalidateLedgerUi() {
    ref.invalidate(debtorsUiProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(cashbookEntriesProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(debtCategoriesProvider);
    ref.read(navIndexProvider.notifier).goTo(1);
  }

  /// مسح دفتر العمليات على هذا الجهاز فقط: عملاء، معاملات، صندوق، تصنيفات،
  /// وإعادة الحسابات الافتراضية (كاش / بنك / محفظة) برصيد صفر — دون تسجيل خروج.
  /// السحابة لا تُحدَّث تلقائياً.
  Future<void> resetLocalLedgerToFactoryDefaults() async {
    await StartupLedgerData.wipeLocalLedgerStorageAndPersist();
    ref.invalidate(debtorsUiProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(cashbookEntriesProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(debtCategoriesProvider);
  }
}
