import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import 'app.dart';
import 'core/bootstrap/auth_prefs_sync.dart';
import 'core/bootstrap/startup_ledger_data.dart';
import 'firebase_options.dart';

import 'core/services/notification_service.dart';

/// يُخبر [SafiApp] أن التهيئة الأولية اكتملت — يتحوّل من شاشة الإقلاع للمحتوى.
final bootstrapCompleteNotifier = ValueNotifier<bool>(false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ▸ فقط Firebase يجب أن ينتهي قبل runApp (يحتاجه Provider الداخلي)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // ▸ نعرض التطبيق فوراً — المستخدم يرى شاشة الإقلاع بدل شاشة بيضاء
  runApp(const ProviderScope(child: SafiApp()));

  // ▸ تحميل البيانات المحلية فقط (سريع جداً — SharedPreferences)
  await StartupLedgerData.ensureLoaded();

  // ▸ نُخبر التطبيق أن كل شيء جاهز — السبلاش ينتهي هنا
  bootstrapCompleteNotifier.value = true;

  // ▸ مزامنة المصادقة والإشعارات في الخلفية (لا تُعطّل الواجهة)
  unawaited(
    Future.wait([
      NotificationService().init(),
      syncFirebaseAuthWithPrefs(),
    ]).then((_) => syncLedgerOwnerUidWithFirebaseAuth()),
  );
}
