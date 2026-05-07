import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/pin_lock_provider.dart';

/// شاشة قفل التطبيق بـ PIN — تظهر عند فتح التطبيق إذا كان القفل مفعّلاً
class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _entered = [];
  bool _error = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitTap(String digit) {
    if (_entered.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _entered.add(digit);
      _error = false;
    });

    if (_entered.length == 4) {
      _verify();
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _entered.removeLast();
      _error = false;
    });
  }

  Future<void> _verify() async {
    final pin = _entered.join();
    final ok = ref.read(pinLockProvider.notifier).verifyPin(pin);
    if (ok) {
      HapticFeedback.mediumImpact();
      ref.read(pinLockGateProvider.notifier).unlock();
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _error = true);
      _shakeController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() {
          _entered.clear();
          _error = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // ── أيقونة القفل ──
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'أدخل رمز الدخول',
              style: AppTextStyles.headlineSmall,
            ),

            const SizedBox(height: 8),

            Text(
              'أدخل رمز PIN للمتابعة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),

            const SizedBox(height: 40),

            // ── نقاط PIN ──
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final progress = _shakeController.value;
                final dx = _error
                    ? _shakeAnimation.value *
                        ((progress * 8).toInt().isEven ? 1 : -1) *
                        (1 - progress)
                    : 0.0;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _entered.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _error
                          ? AppColors.error
                          : filled
                              ? AppColors.primary
                              : Colors.transparent,
                      border: Border.all(
                        color: _error
                            ? AppColors.error
                            : filled
                                ? AppColors.primary
                                : AppColors.outline,
                        width: 2.5,
                      ),
                      boxShadow: filled && !_error
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),

            if (_error) ...[
              const SizedBox(height: 18),
              Text(
                'رمز خاطئ، حاول مرة أخرى',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const Spacer(flex: 2),

            // ── لوحة الأرقام ──
            _buildNumpad(),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((key) {
                  if (key.isEmpty) {
                    return const SizedBox(width: 72, height: 72);
                  }
                  if (key == 'back') {
                    return _PinKey(
                      onTap: _onBackspace,
                      child: Icon(
                        Icons.backspace_outlined,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    );
                  }
                  return _PinKey(
                    onTap: () => _onDigitTap(key),
                    child: Text(
                      key,
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// زر رقم واحد في لوحة PIN
class _PinKey extends StatelessWidget {
  const _PinKey({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(36),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceVariant,
              border: Border.all(
                color: AppColors.outlineSoft,
                width: 1,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
