import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_keys.dart';
import 'startup_ledger_data.dart';

/// ينتظر استعادة مستخدم Firebase من التخزين المحلي بعد [Firebase.initializeApp].
///
/// بدون هذا الانتظار، قد يكون [FirebaseAuth.instance.currentUser] ما زال `null` لبضع مئات الملّي ثانية
/// فيُعامَل المستخدم كغير مسجّل بينما [PrefsKeys.loggedIn] ما زال `true` — ولا تعمل المزامنة.
Future<User?> waitForRestoredFirebaseUser({
  Duration timeout = const Duration(seconds: 5),
}) async {
  var u = FirebaseAuth.instance.currentUser;
  if (u != null) return u;
  try {
    return await FirebaseAuth.instance
        .authStateChanges()
        .where((x) => x != null)
        .cast<User>()
        .timeout(timeout)
        .first;
  } on TimeoutException {
    return FirebaseAuth.instance.currentUser;
  } catch (_) {
    return FirebaseAuth.instance.currentUser;
  }
}

/// يوافق [PrefsKeys.loggedIn] مع حالة جلسة Firebase بعد الإقلاع (مثلاً بعد مسح بيانات التطبيق مع بقاء حساب آخر).
Future<void> syncFirebaseAuthWithPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final hasLocalSession = prefs.getBool(PrefsKeys.loggedIn) ?? false;

  User? firebaseUser = FirebaseAuth.instance.currentUser;
  if (hasLocalSession && firebaseUser == null) {
    firebaseUser = await waitForRestoredFirebaseUser();
  }

  final hasFirebaseUser = firebaseUser != null;
  if (hasLocalSession != hasFirebaseUser) {
    await prefs.setBool(PrefsKeys.loggedIn, hasFirebaseUser);
  }
}

/// يضمن أن البيانات المحفوظة محلياً تخصّ نفس `FirebaseAuth.currentUser.uid` —
/// وإلا يُصفَّر الدفتر (تصحّيح انتقالات الحساب دون تنزيل بيانات المستخدم الآخر عن طريق الخطأ).
Future<void> syncLedgerOwnerUidWithFirebaseAuth() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  final p = await SharedPreferences.getInstance();
  final storedOwnerUid = p.getString(PrefsKeys.ledgerOwnerUid);
  final currentUid = currentUser.uid;

  // حساب Firebase هو مالك دفتره المخزّن: يصحّح الدور إن بقي «كاشير» من جلسة قديمة
  if (storedOwnerUid != null &&
      storedOwnerUid.isNotEmpty &&
      storedOwnerUid == currentUid) {
    await p.setString(PrefsKeys.userRole, 'owner');
    await p.setStringList(PrefsKeys.userPermissions, <String>[]);
  }

  if (storedOwnerUid == null || storedOwnerUid.isEmpty) {
    await p.setString(PrefsKeys.ledgerOwnerUid, currentUid);
    return;
  }

  final role = p.getString(PrefsKeys.userRole) ?? 'owner';
  if (role != 'owner' && storedOwnerUid != currentUid) {
    return;
  }

  if (storedOwnerUid != currentUid) {
    await StartupLedgerData.wipeLocalLedgerStorageAndPersist();
    await p.setString(PrefsKeys.ledgerOwnerUid, currentUid);
    await StartupLedgerData.reloadFromDiskIntoMemory();
  }
}
