import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap/prefs_keys.dart';
import 'phone_e164.dart';

/// نظام تسجيل الدخول برمز دخول مُشتق من رقم الجوال.
///
/// الرمز 4 خانات، يُحسب من أرقام الجوال نفسه:
/// - الخانة 1: مجموع آخر رقمين (رقم الآحاد)
/// - الخانة 2: الخانة الرابعة من رقم الجوال
/// - الخانة 3: الخانة السابعة من رقم الجوال
/// - الخانة 4: مجموع الخانة الثانية والتاسعة (رقم الآحاد)
///
/// مثال: `0591234567` → رمز الدخول = `3141`
abstract final class FirestoreRegisteredPhoneAuth {
  static const registeredPhonesCollection = 'registered_phones';

  /// كلمة مرور Firebase Auth الاصطناعية — تُستخدم داخلياً فقط.
  static const _firebasePassword = '123456';

  static String documentIdFromE164(String e164DigitsAndPlus) =>
      e164DigitsAndPlus.replaceAll(RegExp(r'[^\d]'), '');

  static String emailForPhoneDoc(String documentIdDigits) =>
      '$documentIdDigits@safi-phone.firebase';

  // ─────────────────────────────────────────────
  //  توليد رمز الدخول من رقم الجوال
  // ─────────────────────────────────────────────

  /// يُحوّل الرقم الخام إلى 10 أرقام محلية (مع صفر بادئ).
  /// مثال: "+970591234567" → "0591234567"
  ///        "591234567"    → "0591234567"
  ///        "0591234567"   → "0591234567"
  static String _toLocal10Digits(String rawPhoneDigits) {
    final digits = rawPhoneDigits.trim().replaceAll(RegExp(r'\D'), '');

    // إذا بدأ بـ 970 أو 972 (رقم دولي بدون +)
    if (digits.startsWith('970') && digits.length >= 12) {
      return '0${digits.substring(3)}';
    }
    if (digits.startsWith('972') && digits.length >= 12) {
      return '0${digits.substring(3)}';
    }

    // إذا 10 أرقام وبدأ بـ 0
    if (digits.length == 10 && digits.startsWith('0')) {
      return digits;
    }

    // إذا 9 أرقام وبدأ بـ 5
    if (digits.length == 9 && digits.startsWith('5')) {
      return '0$digits';
    }

    // محاولة أخيرة: أخذ آخر 10 أرقام
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }

    // إذا أقل من 10 أرقام — نضيف أصفار من اليسار
    return digits.padLeft(10, '0');
  }

  /// يُولّد رمز الدخول (4 خانات) من رقم الجوال.
  ///
  /// الخوارزمية:
  /// ```
  /// الرقم المحلي: d0 d1 d2 d3 d4 d5 d6 d7 d8 d9
  /// مثال: 0  5  9  1  2  3  4  5  6  7
  ///
  /// الخانة 1 = (d8 + d9) % 10  → مجموع آخر رقمين (الآحاد)
  /// الخانة 2 = d3               → الرقم الرابع
  /// الخانة 3 = d6               → الرقم السابع
  /// الخانة 4 = (d1 + d8) % 10  → مجموع الثاني والتاسع (الآحاد)
  /// ```
  static String generateAccessCode(String rawPhoneDigits) {
    final local = _toLocal10Digits(rawPhoneDigits);
    final d = local.split('').map(int.parse).toList();

    final c1 = (d[8] + d[9]) % 10;
    final c2 = d[3];
    final c3 = d[6];
    final c4 = (d[1] + d[8]) % 10;

    final code = '$c1$c2$c3$c4';
    debugPrint('[AccessCode] phone=$rawPhoneDigits → local=$local → code=$code');
    return code;
  }

  /// يتحقق من رمز الدخول المُدخَل مقابل الرمز المُشتق من رقم الجوال.
  static bool verifyAccessCode({
    required String rawPhoneDigits,
    required String code,
  }) {
    final expected = generateAccessCode(rawPhoneDigits);
    return code.trim() == expected;
  }

  // ─────────────────────────────────────────────
  //  تسجيل الدخول بـ Email/Password (للحفاظ على UID)
  // ─────────────────────────────────────────────

  /// يُحدّث مستند الهاتف عند الدخول (اختياري).
  static Future<void> mergePhoneRegistryDocFromLogin(String rawPhoneDigits) async {
    try {
      final e164 = phoneDigitsToE164(rawPhoneDigits.trim());
      final id = documentIdFromE164(e164);
      await FirebaseFirestore.instance
          .collection(registeredPhonesCollection)
          .doc(id)
          .set(
        {
          'e164': e164,
          'lastLoginMs': DateTime.now().millisecondsSinceEpoch,
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  /// يبحث عن مستند الهاتف في [registered_phones] (للاسم).
  static Future<DocumentSnapshot<Map<String, dynamic>>?> lookupPhone(
    String rawPhoneDigits,
  ) async {
    final e164 = phoneDigitsToE164(rawPhoneDigits.trim());
    final id = documentIdFromE164(e164);
    final snap = await FirebaseFirestore.instance
        .collection(registeredPhonesCollection)
        .doc(id)
        .get();
    if (!snap.exists) return null;
    return snap;
  }

  /// عند [PrefsKeys.loggedIn] لكن [FirebaseAuth.currentUser] مفقود.
  static Future<User?> trySilentReauthFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(PrefsKeys.loggedIn) != true) return null;
    final docId = p.getString(PrefsKeys.phoneDocId);
    if (docId == null || docId.length < 8) return null;
    try {
      final c = await signInWithRegisteredPhoneAllowed(rawPhoneDigits: docId);
      return c.user;
    } catch (_) {
      return null;
    }
  }

  /// تسجيل دخول email/password — أو إنشاء حساب جديد.
  static Future<UserCredential> signInWithRegisteredPhoneAllowed({
    required String rawPhoneDigits,
  }) async {
    final e164 = phoneDigitsToE164(rawPhoneDigits.trim());
    final docId = documentIdFromE164(e164);
    final email = emailForPhoneDoc(docId);
    final auth = FirebaseAuth.instance;

    // محاولة تسجيل الدخول
    try {
      return await auth.signInWithEmailAndPassword(
        email: email,
        password: _firebasePassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code != 'user-not-found' &&
          e.code != 'wrong-password' &&
          e.code != 'invalid-credential') {
        rethrow;
      }
    }

    // إنشاء حساب جديد
    try {
      return await auth.createUserWithEmailAndPassword(
        email: email,
        password: _firebasePassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return await auth.signInWithEmailAndPassword(
          email: email,
          password: _firebasePassword,
        );
      }
      rethrow;
    }
  }
}
