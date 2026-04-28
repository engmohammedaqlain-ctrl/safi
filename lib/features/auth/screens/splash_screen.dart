import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/bootstrap/startup_ledger_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/debts/providers/debts_ui_provider.dart';
import '../../../features/sales/providers/cashbook_ui_provider.dart';

/// شاشة البداية — بسيطة وبلا خطوط خارجية في أول إطار لتفادي الشاشة الفارغة.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _bgTop = Color(0xFFFFFFFF);
  static const _bgMid = Color(0xFFFAF8FC);
  static const _bgBottom = Color(0xFFEAE4F3);

  static const _titleStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static const _subtitleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.35,
    letterSpacing: 0.2,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapAfterFirstFrame());
    });
  }

  Future<void> _bootstrapAfterFirstFrame() async {
    await StartupLedgerData.ensureLoaded();
    if (!mounted) return;
    ref
      ..invalidate(debtorsUiProvider)
      ..invalidate(transactionsProvider)
      ..invalidate(cashbookEntriesProvider);
    await ref.read(appSessionProvider.notifier).completeSplashGate();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _bgMid,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _bgTop,
                _bgMid,
                _bgBottom,
              ],
              stops: [0.0, 0.52, 1.0],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -48,
                right: -32,
                child: IgnorePointer(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -24,
                left: -48,
                child: IgnorePointer(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              ),
              Center(
                child: Semantics(
                  label: 'صافي، تطبيق محاسبة، جاري التحميل',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                              spreadRadius: -4,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.wallet,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('صافي', style: _titleStyle),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'محاسبة واضحة لمحلّك',
                          textAlign: TextAlign.center,
                          style: _subtitleStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 20 + bottomInset,
                child: Center(
                  child: SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: AppColors.outlineSoft,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
