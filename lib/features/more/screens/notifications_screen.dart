import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/vault_subpage_scaffold.dart';

/// صفحة الإشعارات (قابلة للربط لاحقاً بخدمة فعلية)
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultSubpageScaffold(
      title: 'الإشعارات',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Text(
            'اليوم',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          const _NotifTile(
            icon: LucideIcons.bell,
            color: AppColors.error,
            title: '3 عملاء لديهم ديون متأخرة',
            time: 'منذ 10 د',
            unread: true,
          ),
          const SizedBox(height: 8),
          const _NotifTile(
            icon: LucideIcons.package,
            color: AppColors.warning,
            title: 'منتجان قاربا على النفاذ',
            time: 'منذ ساعة',
            unread: true,
          ),
          const SizedBox(height: 20),
          Text(
            'سابقاً',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          const _NotifTile(
            icon: LucideIcons.check,
            color: AppColors.success,
            title: 'تم حفظ نسخة احتياطية للإعدادات',
            time: 'أمس',
            unread: false,
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
    required this.unread,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String time;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.rmd,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
