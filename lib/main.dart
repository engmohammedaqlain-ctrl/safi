import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/bootstrap/startup_ledger_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  StartupLedgerData.ensureLoaded();
  runApp(
    const ProviderScope(
      child: SafiApp(),
    ),
  );
}