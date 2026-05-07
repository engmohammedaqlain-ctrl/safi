import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/pin_lock_provider.dart';

/// شاشة إعداد / تغيير / حذف رمز PIN
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  _PinSetupStep _step = _PinSetupStep.enterNew;
  final List<String> _firstPin = [];
  final List<String> _confirmPin = [];
  bool _error = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    final pinState = ref.read(pinLockProvider);
    if (pinState.isEnabled) {
      _step = _PinSetupStep.verifyOld;
    }
  }

  void _onDigitTap(String digit) {
    final list = _step == _PinSetupStep.confirm ? _confirmPin : _firstPin;
    if (list.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      list.add(digit);
      _error = false;
    });

    if (list.length == 4) {
      _handleComplete();
    }
  }

  void _onBackspace() {
    final list = _step == _PinSetupStep.confirm ? _confirmPin : _firstPin;
    if (list.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      list.removeLast();
      _error = false;
    });
  }

  Future<void> _handleComplete() async {
    switch (_step) {
      case _PinSetupStep.verifyOld:
        final ok =
            ref.read(pinLockProvider.notifier).verifyPin(_firstPin.join());
        if (ok) {
          setState(() {
            _firstPin.clear();
            _step = _PinSetupStep.enterNew;
          });
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _error = true;
            _errorMsg = 'الرمز الحالي غير صحيح';
          });
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) setState(() => _firstPin.clear());
        }
        break;

      case _PinSetupStep.enterNew:
        setState(() {
          _step = _PinSetupStep.confirm;
        });
        break;

      case _PinSetupStep.confirm:
        if (_firstPin.join() == _confirmPin.join()) {
          await ref.read(pinLockProvider.notifier).setPin(_firstPin.join());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تم تفعيل قفل التطبيق بنجاح'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _error = true;
            _errorMsg = 'الرمز غير متطابق، أعد المحاولة';
          });
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            setState(() {
              _confirmPin.clear();
              _firstPin.clear();
              _step = _PinSetupStep.enterNew;
            });
          }
        }
        break;
    }
  }

  String get _title {
    switch (_step) {
      case _PinSetupStep.verifyOld:
        return 'أدخل الرمز الحالي';
      case _PinSetupStep.enterNew:
        return 'أدخل رمز PIN جديد';
      case _PinSetupStep.confirm:
        return 'تأكيد الرمز';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _PinSetupStep.verifyOld:
        return 'أدخل رمز PIN الحالي للمتابعة';
      case _PinSetupStep.enterNew:
        return 'اختر 4 أرقام لحماية تطبيقك';
      case _PinSetupStep.confirm:
        return 'أدخل نفس الرمز مرة أخرى للتأكيد';
    }
  }

  IconData get _stepIcon {
    switch (_step) {
      case _PinSetupStep.verifyOld:
        return Icons.lock_open_rounded;
      case _PinSetupStep.enterNew:
        return Icons.pin_outlined;
      case _PinSetupStep.confirm:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dots = _step == _PinSetupStep.confirm ? _confirmPin : _firstPin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('إعداد رمز الدخول', style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── أيقونة ──
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Icon(
                _stepIcon,
                color: AppColors.primary,
                size: 30,
              ),
            ),

            const SizedBox(height: 22),

            Text(_title, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 6),
            Text(
              _subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 36),

            // ── نقاط PIN ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < dots.length;
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
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),

            if (_error) ...[
              const SizedBox(height: 14),
              Text(
                _errorMsg,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            // ── مؤشر الخطوات ──
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepIndicator(
                  active: _step == _PinSetupStep.verifyOld ||
                      _step == _PinSetupStep.enterNew,
                  done: _step == _PinSetupStep.confirm,
                ),
                const SizedBox(width: 8),
                _StepIndicator(
                  active: _step == _PinSetupStep.confirm,
                  done: false,
                ),
              ],
            ),

            const Spacer(flex: 1),

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

enum _PinSetupStep { verifyOld, enterNew, confirm }

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.active, required this.done});
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 24 : 10,
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: done
            ? AppColors.success
            : active
                ? AppColors.primary
                : AppColors.outline,
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
