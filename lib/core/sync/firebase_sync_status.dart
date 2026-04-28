import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_status.dart';
import 'ledger_firestore_sync.dart';

/// نص حالة للواجهة: شبكة، سحابة، أوفلاين.
final firebaseSyncStatusSubtitleProvider = Provider<String>((ref) {
  final authAsync = ref.watch(firebaseAuthStateProvider);
  final online = ref.watch(isOnlineProvider);

  return authAsync.when(
    data: (user) {
      if (user == null) {
        return 'سجّل الدخول لربط بياناتك بالسحابة';
      }
      if (!online) {
        return 'أوفلاين — كل التعديلات تُحفظ وتُرفع عند العودة';
      }
      return 'أونلاين — البيانات تُحدَّث تلقائيًا بين الأجهزة';
    },
    loading: () => 'جاري تهيئة الاتصال…',
    error: (_, _) => 'تعذر التحقق من الحالة',
  );
});
