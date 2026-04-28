import 'package:firebase_auth/firebase_auth.dart';

String phoneAuthMessageAr(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-phone-number':
    case 'invalid-phone':
      return 'رقم الهاتف غير صالح أو غير مدعوم.';
    case 'missing-phone-number':
      return 'الرقم مفقود.';
    case 'too-many-requests':
      return 'طلبات كثيرة. انتظر قليلاً ثم حاول مرة أخرى.';
    case 'quota-exceeded':
      return 'حدّ المحاولات للتحقق. حاول لاحقاً.';
    case 'session-expired':
    case 'expired-action-code':
      return 'انتهت صلاحية الرمز. اطلب رمزاً جديداً.';
    case 'invalid-verification-code':
      return 'رمز التحقق غير صحيح.';
    case 'credential-already-in-use':
      return 'هذا الرقم مستخدم بحساب آخر.';
    case 'missing-verification-code':
      return 'أدخل الرمز المرسل.';
    default:
      if (e.message != null &&
          e.message!.isNotEmpty &&
          !e.message!.contains('Exception')) {
        return e.message!;
      }
      return 'تعذر إتمام التحقق. تحقق من الإنترنت وحاول مجدداً.';
  }
}
