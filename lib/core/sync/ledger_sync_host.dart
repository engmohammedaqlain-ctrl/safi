import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../bootstrap/prefs_keys.dart';
import '../bootstrap/app_session.dart';
import '../network/connectivity_status.dart';
import 'ledger_firestore_sync.dart';
import 'post_login_loading.dart';

/// يقيِّد مزامنة الحافظة مع المصادقة ويعرض تنبيهًا أنيقًا عند انقطاع الشبكة.
class LedgerSyncHost extends ConsumerStatefulWidget {
  const LedgerSyncHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LedgerSyncHost> createState() => _LedgerSyncHostState();
}

class _LedgerSyncHostState extends ConsumerState<LedgerSyncHost> {
  ProviderSubscription<AsyncValue<User?>>? _authSub;
  StreamSubscription<DocumentSnapshot>? _kickSub;

  Future<void> _syncFromAuthAsync(AsyncValue<User?> auth) async {
    final sync = ref.read(ledgerFirestoreSyncProvider);
    final loading = ref.read(postLoginLedgerLoadingProvider.notifier);
    await auth.when(
      loading: () async {},
      error: (_, _) async {
        await sync.detach();
        loading.setLoading(false);
      },
      data: (User? user) async {
        if (user == null || user.uid.isEmpty) {
          await sync.detach();
          loading.setLoading(false);
        } else {
          try {
            final prefs = await SharedPreferences.getInstance();
            final targetUid = prefs.getString(PrefsKeys.ledgerOwnerUid) ?? user.uid;
            await sync.attachIfNeeded(targetUid);
            
            // Listen for kick if not owner
            final role = prefs.getString(PrefsKeys.userRole) ?? 'owner';
            final myPhoneDocId = prefs.getString(PrefsKeys.phoneDocId);
            
            _kickSub?.cancel();
            if (myPhoneDocId != null && role != 'owner') {
              _kickSub = FirebaseFirestore.instance
                  .collection('user_sessions')
                  .doc(myPhoneDocId)
                  .snapshots()
                  .listen((snap) {
                if (snap.data()?['kicked'] == true) {
                  ref.read(appSessionProvider.notifier).logout();
                }
              });
            }
          } catch (e, st) {
            debugPrint('LedgerSyncHost attachIfNeeded: $e\n$st');
          } finally {
            loading.setLoading(false);
          }
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    Future<void> boot() async {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      await _syncFromAuthAsync(ref.read(firebaseAuthStateProvider));

      _authSub ??= ref.listenManual<AsyncValue<User?>>(
        firebaseAuthStateProvider,
        (previous, next) {
          unawaited(_syncFromAuthAsync(next));
        },
        onError: (error, stack) {
          debugPrint('LedgerSyncHost authSub error: $error\n$stack');
        },
      );
    }

    unawaited(boot());
  }

  @override
  void dispose() {
    _authSub?.close();
    _kickSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(ledgerFirestoreSyncProvider);

    ref.listen<bool>(isOnlineProvider, (previous, next) {
      if (next == true && previous != true) {
        ref.read(ledgerFirestoreSyncProvider).schedulePushDebounced();
      }
    });

    return widget.child;
  }
}
