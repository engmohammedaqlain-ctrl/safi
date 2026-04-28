import 'package:flutter/material.dart';
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
      showAppSnackBar(context, 'الرجاء إدخال اسمك');
      return;
    }
    ref.read(appSessionProvider.notifier).saveName(name);
  }

  @override
  Widget build(BuildContext context) {
    return VaultBrandedShell(
      headerSubtitle: 'سيتم عرض هذا الاسم في أعلى واجهة التطبيق',
      belowBrand: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Text(
            'إكمال الملف',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
      sheet: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    28,
                    AppSpacing.lg,
                    12,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight - 24),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            LucideIcons.userPlus,
                            size: 36,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'ما هو اسمك؟',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: const Color(0xFF12121F),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'يمكنك استخدام اسمك الشخصي أو اسم متجرك',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),
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
                                  color: AppColors.primary.withValues(
                                    alpha: 0.06,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: TextField(
                              controller: _name,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                hintText: 'أدخل اسمك أو اسم المتجر',
                                prefixIcon: Icon(
                                  LucideIcons.user,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
              label: 'متابعة',
              icon: LucideIcons.arrowLeft,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
