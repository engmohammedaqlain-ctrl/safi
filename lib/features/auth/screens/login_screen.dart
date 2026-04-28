import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/safi_button.dart';
import '../../../core/widgets/vault_branded_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  var _showOtp = false;
  var _submitting = false;
  String _otpCode = '';
  final _otpKey = GlobalKey<OtpCodeFieldState>();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_submitting) return;
    if (!_showOtp) {
      if (_phone.text.trim().length < 8) {
        showAppSnackBar(context, 'أدخل رقماً صحيحاً');
        return;
      }
      setState(() => _showOtp = true);
      return;
    }
    if (_otpCode.length < OtpCodeField.otpLength) {
      showAppSnackBar(context, 'أدخل الأرقام الستة لرمز التحقق');
      return;
    }
    setState(() => _submitting = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;
      await ref.read(appSessionProvider.notifier).onLoginSuccess();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VaultBrandedShell(
      headerSubtitle: _showOtp
          ? 'أدخل الرمز الستّي المرسل عبر الرسائل'
          : 'تسجيل دخول آمن',
      belowBrand: Center(
        child: _LoginStepIndicator(onOtpStep: _showOtp),
      ),
      sheet: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                24,
                AppSpacing.lg,
                12,
              ),
              child: Column(
                children: [
                  Material(
                    color: AppColors.backgroundSecondary,
                    borderRadius: AppRadius.rxl,
                    elevation: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.rxl,
                        border: Border.all(color: AppColors.outlineSoft),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.07),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_showOtp) ...[
                            Text(
                              'رقم الهاتف',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: const Color(0xFF12121F),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                hintText: 'مثال: 599123456',
                                prefixIcon: Icon(
                                  LucideIcons.smartphone,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    LucideIcons.smartphone,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _phone.text,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'أدخل رمز التحقق المُرسل عبر SMS',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OtpCodeField(
                              key: _otpKey,
                              onCodeChanged: (s) {
                                setState(() => _otpCode = s);
                              },
                            ),
                          ],
                          if (_showOtp) ...[
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: _submitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _showOtp = false;
                                        _otpCode = '';
                                      });
                                      _otpKey.currentState?.clear();
                                    },
                              child: const Text('تصحيح رقم الهاتف'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'بمتابعة الدخول تؤكد موافقتك على استخدام التطبيق لإدارة متجرك.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VaultTrustStrip(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: SafiButton(
              label: _showOtp
                  ? (_submitting ? 'جاري التحقق...' : 'تأكيد والدخول')
                  : 'إرسال رمز التحقق',
              icon: _showOtp ? LucideIcons.check : null,
              onPressed: _submitting ? null : _continue,
            ),
          ),
        ],
      ),
    );
  }
}

/// مؤشر خطوتين تحت شعار صافي (نفس أسلوب نقاط الأونبوردنغ).
class _LoginStepIndicator extends StatelessWidget {
  const _LoginStepIndicator({required this.onOtpStep});

  final bool onOtpStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepDot(active: !onOtpStep, done: onOtpStep),
        const SizedBox(width: 8),
        _stepDot(active: onOtpStep, done: false),
      ],
    );
  }

  Widget _stepDot({required bool active, required bool done}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      height: 6,
      width: active ? 28 : 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: active || done
            ? Colors.white
            : Colors.white.withValues(alpha: 0.28),
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }
}

/// خانات مرتبة لرمز التحقق (6 أرقام) — LTR للأرقام، تركيز تلقائي، دعم لصق
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({super.key, required this.onCodeChanged});

  static const int otpLength = 6;

  final ValueChanged<String> onCodeChanged;

  @override
  OtpCodeFieldState createState() => OtpCodeFieldState();
}

class OtpCodeFieldState extends State<OtpCodeField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  int? _focusedI;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      OtpCodeField.otpLength,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(OtpCodeField.otpLength, (i) => FocusNode());
    for (var i = 0; i < OtpCodeField.otpLength; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          setState(() => _focusedI = i);
        } else {
          if (_focusedI == i) setState(() => _focusedI = null);
        }
      });
    }
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  bool _onHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return false;
    }
    final i = _focusedI;
    if (i == null || i <= 0) {
      return false;
    }
    if (_controllers[i].text.isNotEmpty) {
      return false;
    }
    _focusNodes[i - 1].requestFocus();
    _controllers[i - 1].text = '';
    _emit();
    return true;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    for (final n in _focusNodes) {
      n.dispose();
    }
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final code = _controllers.map((c) => c.text).join();
    widget.onCodeChanged(code);
  }

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes.first.requestFocus();
    }
    _emit();
  }

  void _distribute(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return;
    for (var k = 0; k < OtpCodeField.otpLength; k++) {
      _controllers[k].text = k < d.length ? d[k] : '';
    }
    if (d.length >= OtpCodeField.otpLength) {
      _focusNodes[OtpCodeField.otpLength - 1].requestFocus();
      FocusScope.of(context).unfocus();
    } else {
      _focusNodes[d.length].requestFocus();
    }
    _emit();
  }

  void _onFieldChanged(int i, String value) {
    var v = value.replaceAll(RegExp(r'\D'), '');
    if (v.length > 1) {
      _distribute(v);
      return;
    }
    if (v.length == 1) {
      if (i < OtpCodeField.otpLength - 1) {
        _focusNodes[i + 1].requestFocus();
      } else {
        FocusScope.of(context).unfocus();
      }
    } else {
      if (i > 0) {
        _focusNodes[i - 1].requestFocus();
      }
    }
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: List.generate(OtpCodeField.otpLength, (i) {
          final isFocused = _focusedI == i;
          final hasValue = _controllers[i].text.isNotEmpty;
          return Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 48,
                decoration: BoxDecoration(
                  color: isFocused
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : hasValue
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : AppColors.backgroundSecondary,
                  borderRadius: AppRadius.rmd,
                  border: Border.all(
                    color: isFocused
                        ? AppColors.primary
                        : hasValue
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.textMuted.withValues(alpha: 0.25),
                    width: isFocused ? 1.8 : 1.2,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    onChanged: (s) => _onFieldChanged(i, s),
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    showCursor: false,
                    autofillHints: i == 0
                        ? const [AutofillHints.oneTimeCode]
                        : const [],
                    textInputAction: i == OtpCodeField.otpLength - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    style: AppTextStyles.numberLarge.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      color: AppColors.primary,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    decoration: const InputDecoration(
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
