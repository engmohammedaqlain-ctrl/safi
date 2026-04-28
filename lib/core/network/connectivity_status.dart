import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// تدفق آخر نتيجة اتصال من [connectivity_plus].
final connectivityListProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) {
  return Connectivity().onConnectivityChanged;
});

/// هل يوجد اتصال قابل للاستخدام (واي فاي / بيانات / إيثرنت).
final isOnlineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityListProvider);
  return async.when(
    data: isOnlineConnectivityResults,
    loading: () => true,
    error: (Object _, StackTrace _) => true,
  );
});

bool isOnlineConnectivityResults(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  return results.any((e) => e != ConnectivityResult.none);
}

/// نقطة واحدة لمزامنة الدخول: يجب استدعاؤها قبل جلب أو التحقّق مع Firestore.
Future<bool> checkDeviceOnlineNow() async {
  final results = await Connectivity().checkConnectivity();
  return isOnlineConnectivityResults(results);
}
