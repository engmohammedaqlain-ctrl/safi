import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

/// OTP عبر Firebase يعمل بشكل رسمي على Android و iOS و Web (مع اختبار reCaptcha).
bool get isFirebasePhoneVerificationSupported {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return false;
    case TargetPlatform.fuchsia:
      return false;
  }
}
