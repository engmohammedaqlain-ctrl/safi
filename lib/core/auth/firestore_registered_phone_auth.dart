import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'phone_e164.dart';

/// تسجيل الدخول باسم هاتف اصطناعي (Email/Password في Firebase Auth) بعد التحقق من الرمز في الواجهة.
///
/// كلمة المرور في Firebase لمستخدمي النظام الاصطناعي تكون عادة **`123456`** (نفس [otpForLogin])؛ الحسابات الأقدم
/// قد تعمل بـ [firebaseEmailPasswordLegacy] ويُحاول التطبيقها تلقائياً.
///
/// مجموعة **`registered_phones`**: لتحميل [displayName] وتصنيف «مسجّل» للواجهة؛ اختياري لنجاح Auth نفسه.
abstract final class FirestoreRegisteredPhoneAuth {
  static const registeredPhonesCollection = 'registered_phones';

  /// رمز الواجهة — يُفترض أن تكون كلمة المرور المعتمدة في Firebase لمستخدمي هذا الشكل أيضاً هي نفس القيمة.
  static const otpForLogin = '123456';

  /// كلمة مرور حساب مصطنع قديم (قبل المواءمة مع otpForLogin).
  static const firebaseEmailPasswordLegacy = 'SafiOtp123456';

  static String documentIdFromE164(String e164DigitsAndPlus) =>
      e164DigitsAndPlus.replaceAll(RegExp(r'[^\d]'), '');

  static String emailForPhoneDoc(String documentIdDigits) =>
      '$documentIdDigits@safi-phone.firebase';

  /// يُستدعى بعد نجاح [signInWithRegisteredPhoneAllowed]: يحدّث مستند الهاتف للمسجّلين (اختياري).
  /// يُفشل صامتاً إذا منعت قواعد Firestore الكتابة.
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

  /// يتحقّق من وجود مستند اختياري في Firestore (للاسم وعبارة «مسجّل بالنظام»).
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

  /// أسباب «فشل بيانات الدخول» التي نعالجها بمحاولة كلمة مرور أخرى أو إنشاء حساب.
  static bool _isRecoverableCredentialFailure(FirebaseAuthException e) {
    return e.code == 'wrong-password' ||
        e.code == 'invalid-credential' ||
        e.code == 'user-not-found';
  }

  static List<String> get _passwordTryOrder =>
      <String>[otpForLogin, firebaseEmailPasswordLegacy];

  /// بعد التحقق من رمز الواجهة يربط نفس حساب Firebase على كل الأجهزة.
  ///
  /// يحاول تسجيل الدخول بـ [otpForLogin] ثم بالقديمة، ثم **إنشاء مستخدم جديد** (`createUserWithEmailAndPassword`)
  /// إن لم يكن الحساب موجوداً — إنشاء «تقليدي» عبر واجهة Firebase.
  static Future<UserCredential> signInWithRegisteredPhoneAllowed({
    required String rawPhoneDigits,
  }) async {
    final e164 = phoneDigitsToE164(rawPhoneDigits.trim());
    final docId = documentIdFromE164(e164);
    final email = emailForPhoneDoc(docId);
    final auth = FirebaseAuth.instance;

    Future<UserCredential> signIn(String password) => auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

    Future<UserCredential> createNew() => auth.createUserWithEmailAndPassword(
          email: email,
          password: otpForLogin,
        );

    for (final pw in _passwordTryOrder) {
      try {
        return await signIn(pw);
      } on FirebaseAuthException catch (e) {
        if (!_isRecoverableCredentialFailure(e)) rethrow;
        // جرّب كلمة المرور التالية أو إنشاء حساب لاحقاً
      }
    }

    try {
      return await createNew();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        for (final pw in _passwordTryOrder) {
          try {
            return await signIn(pw);
          } on FirebaseAuthException catch (e2) {
            if (!_isRecoverableCredentialFailure(e2)) rethrow;
          }
        }
      }
      rethrow;
    }
  }
}
