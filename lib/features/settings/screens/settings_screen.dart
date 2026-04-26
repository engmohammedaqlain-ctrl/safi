import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── بطاقة المتجر ──
          GlassCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.store,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('سوبرماركت صافي', style: AppTextStyles.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        '₪ شيكل · رام الله',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronLeft,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── إعدادات الحساب ──
          _SectionLabel('إعدادات الحساب'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: LucideIcons.users,
                  title: 'الفريق والصلاحيات',
                  subtitle: 'المالك، كاشير، مشرف',
                ),
                const Divider(height: 1, indent: 52),
                _SettingsTile(
                  icon: LucideIcons.cloud,
                  title: 'المزامنة',
                  subtitle: 'متصل — جاهز',
                ),
                const Divider(height: 1, indent: 52),
                _SettingsTile(
                  icon: LucideIcons.sparkles,
                  title: 'الميزات الذكية',
                  subtitle: 'مفعّل',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── تسجيل الخروج ──
          _SectionLabel('الجلسة'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: LucideIcons.logOut,
              title: 'تسجيل الخروج',
              subtitle: 'العودة لشاشة تسجيل الدخول',
              iconColor: AppColors.error,
              onTap: () async {
                final go = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('تسجيل الخروج؟'),
                    content: const Text('ستحتاج لإدخال رقم الهاتف مرة أخرى.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('تسجيل خروج'),
                      ),
                    ],
                  ),
                );
                if (go == true) {
                  await ref.read(appSessionProvider.notifier).logout();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = iconColor ?? AppColors.primary;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 20),
      ),
      title: Text(title, style: AppTextStyles.titleSmall),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      ),
      trailing: onTap != null
          ? Icon(
              LucideIcons.chevronLeft,
              color: iconColor != null
                  ? iconColor!.withValues(alpha: 0.6)
                  : AppColors.textMuted,
              size: 18,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      dense: true,
      minVerticalPadding: 8,
    );
  }
}
