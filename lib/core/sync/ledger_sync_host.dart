import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
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
            await sync.attachIfNeeded(user.uid);
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
      );
    }

    unawaited(boot());
  }

  @override
  void dispose() {
    _authSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(ledgerFirestoreSyncProvider);

    final online = ref.watch(isOnlineProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: online
              ? const SizedBox.shrink()
              : Material(
                  key: const ValueKey<String>('offline'),
                  elevation: 0,
                  color: AppColors.warning.withValues(alpha: 0.22),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      8,
                      AppSpacing.md,
                      8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 20,
                          color: AppColors.textPrimary.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'لا يوجد اتصال — التعديلات تُحفظ على الجهاز وتُزامن عند استعادة الاتصال.',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.9,
                              ),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
