import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/bootstrap/auth_prefs_sync.dart';
import 'core/bootstrap/startup_ledger_data.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await syncFirebaseAuthWithPrefs();

  await StartupLedgerData.ensureLoaded();
  await syncLedgerOwnerUidWithFirebaseAuth();

  runApp(const ProviderScope(child: SafiApp()));
}
