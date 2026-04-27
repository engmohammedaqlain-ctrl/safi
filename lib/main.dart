import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/bootstrap/startup_ledger_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StartupLedgerData.load();
  runApp(
    const ProviderScope(
      child: SafiApp(),
    ),
  );
}
