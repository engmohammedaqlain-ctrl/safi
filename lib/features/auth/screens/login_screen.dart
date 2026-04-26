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
  final _otp = TextEditingController();
  var _showOtp = false;
  var _submitting = false;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_submitting) return;
    if (!_showOtp) {
      if (_phone.text.trim().length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل رقماً صحيحاً')),
        );
        return;
      }
      setState(() => _showOtp = true);
      return;
    }
    if (_otp.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل رمز التحقق')),
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
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF0EEFF),
              Color(0xFFF8F8FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                bottomInset + AppSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.store,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'صافي',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'تسجيل دخول آمن',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'نفس الرقم يربط فريقك. بعد التأكيد تكمل إعداد محلك.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _showOtp ? 'رمز التحقق' : 'رقم الهاتف',
                              style: AppTextStyles.titleSmall,
                            ),
                            const SizedBox(height: 10),
                            if (!_showOtp)
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
                              )
                            else ...[
                              TextField(
                                controller: _phone,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    LucideIcons.smartphone,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextField(
                                controller: _otp,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.numberLarge.copyWith(
                                  letterSpacing: 6,
                                ),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  hintText: '— — — — — —',
                                  prefixIcon: Icon(
                                    LucideIcons.shield,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            SafiButton(
                              label: _showOtp
                                  ? (_submitting
                                      ? 'جاري التحقق...'
                                      : 'تأكيد والدخول')
                                  : 'إرسال رمز via SMS',
                              onPressed: _submitting ? null : _continue,
                            ),
                            if (_showOtp) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _submitting
                                    ? null
                                    : () {
                                        setState(() {
                                          _showOtp = false;
                                          _otp.clear();
                                        });
                                      },
                                child: const Text('تصحيح رقم الهاتف'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
