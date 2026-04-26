import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/safi_button.dart';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('أدخل رقماً صحيحاً')));
        return;
      }
      setState(() => _showOtp = true);
      return;
    }
    if (_otpCode.length < OtpCodeField.otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل الأرقام الستة لرمز التحقق')),
      );
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFFFFFFF), Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                bottomInset + AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    // ── شعار مضغوط ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.30,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.store,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'صافي',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تسجيل دخول آمن',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── البطاقة الرئيسية ──
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
                              // ── مرحلة الهاتف ──
                              Text(
                                'رقم الهاتف',
                                style: AppTextStyles.titleSmall,
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
                              // ── مرحلة رمز التحقق — مضغوطة ──
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
                            const SizedBox(height: AppSpacing.md),
                            SafiButton(
                              label: _showOtp
                                  ? (_submitting
                                        ? 'جاري التحقق...'
                                        : 'تأكيد والدخول')
                                  : 'إرسال رمز التحقق',
                              onPressed: _submitting ? null : _continue,
                            ),
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
          ),
        ),
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
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  onChanged: (s) => _onFieldChanged(i, s),
                  textAlign: TextAlign.center,
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
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
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
