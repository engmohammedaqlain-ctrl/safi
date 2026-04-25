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
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          GlassCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.store,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('سوبرماركت صافي', style: AppTextStyles.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        '₪ شيكل · رام الله',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronLeft,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: LucideIcons.users,
            title: 'الفريق والصلاحيات',
            subtitle: 'المالك، كاشير، مشرف',
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: LucideIcons.cloud,
            title: 'المزامنة',
            subtitle: 'متصل — جاهز',
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: LucideIcons.sparkles,
            title: 'الميزات الذكية',
            subtitle: 'مفعّل',
          ),
          const SizedBox(height: 8),
          _SettingsTile(
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
        ],
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
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleSmall),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronLeft,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
