import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/bootstrap/startup_ledger_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/debts/providers/debts_ui_provider.dart';
import '../../../features/sales/providers/cashbook_ui_provider.dart';

/// شاشة البداية — ثم الانتقال: تسجيل دخول → إن لزم الإعداد الأولي → التطبيق
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _heroFade;
  late final Animation<double> _heroScale;
  late final Animation<double> _textSlide;
  late final Animation<double> _barFade;

  static const _splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFAF8FC),
      Color(0xFFF2EDF8),
      Color(0xFFEAE4F3),
    ],
    stops: [0.0, 0.35, 0.72, 1.0],
  );

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 640),
    );
    final motion = CurvedAnimation(
      parent: _c,
      curve: Curves.easeOutCubic,
    );
    // لا تبدأ من شفافية كاملة — أول إطار يكون واضحاً
    _heroFade = Tween<double>(begin: 0.2, end: 1).animate(motion);
    _heroScale = Tween<double>(begin: 0.92, end: 1).animate(motion);
    _textSlide = Tween<double>(begin: 8, end: 0).animate(motion);
    _barFade = Tween<double>(begin: 0.35, end: 1).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.25, 1.0, curve: Curves.easeOut)),
    );

    _c.forward();
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
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FC),
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: _splashGradient),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -64,
                right: -40,
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: Container(
                      width: 188,
                      height: 188,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.052),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -28,
                left: -56,
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: Container(
                      width: 156,
                      height: 156,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryLight.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Semantics(
                  label: 'صافي، تطبيق محاسبة، جاري التحميل',
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) {
                      return Opacity(
                        opacity: _heroFade.value,
                        child: Transform.scale(
                          scale: _heroScale.value,
                          child: Transform.translate(
                            offset: Offset(0, _textSlide.value * 0.35),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.18),
                                        blurRadius: 26,
                                        offset: const Offset(0, 14),
                                        spreadRadius: -8,
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      gradient: AppColors.primaryGradient,
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.38),
                                        width: 1.25,
                                      ),
                                    ),
                                    child: const Icon(
                                      LucideIcons.wallet,
                                      size: 34,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 26),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 300),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'صافي',
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.displayMedium
                                            .copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w900,
                                          height: 1.12,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'محاسبة واضحة لمحلّك',
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 22 + bottomInset,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _barFade.value,
                      child: Center(
                        child: SizedBox(
                          width: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              backgroundColor: AppColors.outlineSoft,
                              color:
                                  AppColors.primary.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
