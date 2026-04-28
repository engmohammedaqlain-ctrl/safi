import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_keys.dart';
import 'startup_ledger_data.dart';

/// يوافق [PrefsKeys.loggedIn] مع حالة جلسة Firebase بعد الإقلاع (مثلاً بعد مسح بيانات التطبيق مع بقاء حساب آخر).
Future<void> syncFirebaseAuthWithPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final hasLocalSession = prefs.getBool(PrefsKeys.loggedIn) ?? false;
  final hasFirebaseUser = FirebaseAuth.instance.currentUser != null;
  if (hasLocalSession != hasFirebaseUser) {
    await prefs.setBool(PrefsKeys.loggedIn, hasFirebaseUser);
  }
}

/// يضمن أن البيانات المحفوظة محلياً تخصّ نفس `FirebaseAuth.currentUser.uid` —
/// وإلا يُصفَّر الدفتر (تصحّيح انتقالات الحساب دون تنزيل بيانات المستخدم الآخر عن طريق الخطأ).
Future<void> syncLedgerOwnerUidWithFirebaseAuth() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final p = await SharedPreferences.getInstance();
  final stored = p.getString(PrefsKeys.ledgerOwnerUid);
  if (stored == uid) return;

  await StartupLedgerData.wipeLocalLedgerStorageAndPersist();
  await p.setString(PrefsKeys.ledgerOwnerUid, uid);
  await StartupLedgerData.reloadFromDiskIntoMemory();
}
