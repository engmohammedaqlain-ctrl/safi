import 'package:flutter_riverpod/flutter_riverpod.dart';

/// يفعَّل قبل إكمال تسجيل الدخول ويُلغى بعد انتهاء [LedgerFirestoreSync.attachIfNeeded].
/// يستخدم لعرض طبقة تحميل فوق المحتوى بعد الانتقال للشاشة الرئيسية.
final postLoginLedgerLoadingProvider =
    NotifierProvider<PostLoginLedgerLoadingNotifier, bool>(
  PostLoginLedgerLoadingNotifier.new,
);

class PostLoginLedgerLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool value) => state = value;
}
