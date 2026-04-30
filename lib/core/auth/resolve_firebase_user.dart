import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firestore_registered_phone_auth.dart';
import '../bootstrap/auth_prefs_sync.dart';
import '../sync/ledger_firestore_sync.dart';

/// يعيد المستخدم الحالي بعد استعادة جلسة Firebase إن تأخرت (شائع بعد الدخول أو على أجهزة بطيئة).
///
/// إن فشل كل شيء لكن التخزين المحلي يقول إن المستخدم مسجّل، يُجرى [FirestoreRegisteredPhoneAuth.trySilentReauthFromPrefs].
Future<User?> resolveFirebaseUserForAction(WidgetRef ref) async {
  var u = FirebaseAuth.instance.currentUser;
  u ??= await waitForRestoredFirebaseUser(timeout: const Duration(seconds: 3));
  if (u != null) return u;

  final async = ref.read(firebaseAuthStateProvider);
  switch (async) {
    case AsyncData<User?>(:final value):
      if (value != null) return value;
    case AsyncError():
      break;
    case AsyncLoading():
      break;
  }

  for (var i = 0; i < 24; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 75));
    u = FirebaseAuth.instance.currentUser;
    if (u != null) return u;
  }

  try {
    return await FirebaseAuth.instance
        .authStateChanges()
        .where((x) => x != null)
        .cast<User>()
        .timeout(const Duration(seconds: 5))
        .first;
  } on TimeoutException {
    u = FirebaseAuth.instance.currentUser;
    if (u != null) return u;
  } catch (_) {
    u = FirebaseAuth.instance.currentUser;
    if (u != null) return u;
  }

  return FirestoreRegisteredPhoneAuth.trySilentReauthFromPrefs();
}
