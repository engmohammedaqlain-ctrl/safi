import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'phone_e164.dart';

class PhoneAuthService {
  PhoneAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  String normalizePhoneOrThrow(String raw) {
    try {
      return phoneDigitsToE164(raw);
    } on FormatException {
      throw FirebaseAuthException(
        code: 'invalid-phone-number',
        message: 'normalize',
      );
    }
  }

  Future<void> startVerification({
    required String rawPhoneDigits,
    int? forceResendingToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required Future<void> Function(UserCredential credential) onSignedIn,
    required void Function(FirebaseAuthException e) onFailed,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    late final String phoneNumber;
    try {
      phoneNumber = normalizePhoneOrThrow(rawPhoneDigits);
    } on FirebaseAuthException catch (e) {
      onFailed(e);
      return;
    }

    debugPrint('╔══════════════════════════════════════════╗');
    debugPrint('║ Firebase Phone Auth: verifyPhoneNumber   ║');
    debugPrint('║ rawInput: "$rawPhoneDigits"');
    debugPrint('║ normalized (E.164): "$phoneNumber"');
    debugPrint('╚══════════════════════════════════════════╝');

    final done = Completer<void>();
    void markDone() {
      if (!done.isCompleted) done.complete();
    }

    unawaited(
      _auth
          .verifyPhoneNumber(
            phoneNumber: phoneNumber,
            forceResendingToken: forceResendingToken,
            verificationCompleted: (PhoneAuthCredential credential) async {
              debugPrint('[PhoneAuth] ✅ Auto-verification completed');
              try {
                final uc = await _auth.signInWithCredential(credential);
                await onSignedIn(uc);
              } catch (e, st) {
                debugPrint('PhoneAuth auto verification failed: $e\n$st');
              } finally {
                markDone();
              }
            },
            verificationFailed: (FirebaseAuthException e) {
              debugPrint('[PhoneAuth] ❌ verificationFailed: code=${e.code}, message=${e.message}');
              onFailed(e);
              markDone();
            },
            codeSent: (verificationId, resendToken) {
              debugPrint('[PhoneAuth] 📩 codeSent: verificationId=${verificationId.substring(0, 10)}...');
              onCodeSent(verificationId, resendToken);
              markDone();
            },
            codeAutoRetrievalTimeout: (_) {
              debugPrint('[PhoneAuth] ⏰ codeAutoRetrievalTimeout');
            },
            timeout: timeout,
          )
          .catchError((Object e, StackTrace st) {
            debugPrint('[PhoneAuth] 💥 catchError: $e\n$st');
            if (e is FirebaseAuthException) {
              onFailed(e);
            }
            markDone();
          }),
    );
    await done.future;
  }

  Future<UserCredential> submitSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    return _auth.signInWithCredential(credential);
  }

  PhoneAuthFailureKind classify(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
      case 'invalid-phone':
      case 'missing-phone-number':
        return PhoneAuthFailureKind.invalidPhone;
      default:
        return PhoneAuthFailureKind.other;
    }
  }
}

enum PhoneAuthFailureKind {
  invalidPhone,
  other,
}
