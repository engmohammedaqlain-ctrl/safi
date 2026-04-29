import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_status.dart';
import '../theme/app_colors.dart';
import 'ledger_firestore_sync.dart';

/// لون نقطة حالة المزامنة: أخضر = جاهز، أحمر = خطأ أو بانتظار رفع، برتقالي = أوفلاين.
final ledgerSyncDotColorProvider = Provider<Color?>((ref) {
  final auth = ref.watch(firebaseAuthStateProvider);
  final online = ref.watch(isOnlineProvider);
  final ui = ref.watch(ledgerSyncUiProvider);
  return auth.when(
    data: (user) {
      if (user == null) return AppColors.error;
      if (!online) return AppColors.warning;
      if (ui.lastPushError != null || ui.needsCloudPush) {
        return AppColors.error;
      }
      return AppColors.success;
    },
    loading: () => null,
    error: (_, __) => AppColors.error,
  );
});

/// نص حالة للواجهة: شبكة، سحابة، أوفلاين، وآخر خطأ مزامنة إن وُجد.
final firebaseSyncStatusSubtitleProvider = Provider<String>((ref) {
  final authAsync = ref.watch(firebaseAuthStateProvider);
  final online = ref.watch(isOnlineProvider);
  final ui = ref.watch(ledgerSyncUiProvider);

  return authAsync.when(
    data: (user) {
      if (user == null) {
        return 'سجّل الدخول لربط بياناتك بالسحابة';
      }
      if (!online) {
        if (ui.lastPushError != null) {
          return 'أوفلاين — ${ui.lastPushError}';
        }
        return 'أوفلاين — التعديلات تُحفظ محلياً وتُرفع تلقائياً عند عودة الشبكة';
      }
      if (ui.lastPushError != null) {
        return ui.lastPushError!;
      }
      if (ui.needsCloudPush) {
        return 'تعديلات بانتظار الرفع — ستُرفع تلقائياً أو اضغط للمزامنة الآن';
      }
      return 'متزامن — البيانات محدَّثة مع السحابة';
    },
    loading: () => 'جاري تهيئة الاتصال…',
    error: (_, _) => 'تعذر التحقق من الحالة',
  );
});
