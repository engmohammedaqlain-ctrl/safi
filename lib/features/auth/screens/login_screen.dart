import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/theme/app_colors.dart';
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
      // محاكاة التحقق — لاحقاً: Firebase Auth
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await ref.read(appSessionProvider.notifier).onLoginSuccess();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'نفس الرقم يربط الفريق — بعد التأكيد تنتقل لإتمام إعداد محلك يدويّاً.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'رقم الهاتف',
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            readOnly: _showOtp,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'مثال: 599123456',
              prefixIcon: Icon(LucideIcons.smartphone, color: AppColors.primary),
            ),
          ),
          if (_showOtp) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('رمز التحقق', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                counterText: '',
                hintText: '6 أرقام',
                prefixIcon: Icon(LucideIcons.shield, color: AppColors.primary),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SafiButton(
            label: _showOtp
                ? (_submitting ? 'جاري...' : 'تأكيد ودخول')
                : 'إرسال رمز SMS',
            onPressed: _submitting ? null : _continue,
          ),
        ],
      ),
    );
  }
}
