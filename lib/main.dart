import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/bootstrap/startup_ledger_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // شاشة النظام (Android 12+ Splash) تغطّي زمن قراءة الإعدادات؛
  // الانتظار هنا يجعل أول فريم لـ Flutter هو الشاشة الفعلية مباشرة.
  await StartupLedgerData.ensureLoaded();
  runApp(
    const ProviderScope(
      child: SafiApp(),
    ),
  );
}