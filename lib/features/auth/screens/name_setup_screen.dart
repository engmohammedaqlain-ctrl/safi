import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/safi_button.dart';

class NameSetupScreen extends ConsumerStatefulWidget {
  const NameSetupScreen({super.key});

  @override
  ConsumerState<NameSetupScreen> createState() => _NameSetupScreenState();
}

class _NameSetupScreenState extends ConsumerState<NameSetupScreen> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسمك')),
      );
      return;
    }
    ref.read(appSessionProvider.notifier).saveName(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خطوة إضافية'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                LucideIcons.userPlus,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'ما هو اسمك؟',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'سيتم عرض هذا الاسم في أعلى واجهة التطبيق',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  hintText: 'أدخل اسمك أو اسم المتجر',
                  prefixIcon: Icon(LucideIcons.user, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 32),
              SafiButton(
                label: 'متابعة',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
