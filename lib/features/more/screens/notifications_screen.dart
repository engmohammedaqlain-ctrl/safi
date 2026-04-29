import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/reports_style_shell.dart';
import '../../debts/providers/debts_ui_provider.dart';
import '../../../core/router/app_page_route.dart';
import '../../debts/screens/customer_detail_screen.dart';

/// صفحة الإشعارات المربوطة بالديون
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtors = ref.watch(debtorsUiProvider);
    
    final now = DateTime.now();
    final overdueDebts = debtors.where((d) {
      if (d.dueDate == null) return false;
      final amt = double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
      return amt > 0 && d.dueDate!.isBefore(now);
    }).toList();

    final upcomingDebts = debtors.where((d) {
      if (d.dueDate == null) return false;
      final amt = double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
      return amt > 0 && d.dueDate!.isAfter(now) && d.dueDate!.difference(now).inDays <= 3;
    }).toList();

    return ReportsStylePage(
      title: 'الإشعارات',
      subtitle: 'تذكيرات الديون ومواعيد السداد',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          if (overdueDebts.isEmpty && upcomingDebts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'لا توجد إشعارات حالياً',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
            
          if (overdueDebts.isNotEmpty) ...[
            Text(
              'ديون متأخرة',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            for (final d in overdueDebts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      AppPageRoute(builder: (_) => CustomerDetailScreen(debtor: d)),
                    );
                  },
                  child: _NotifTile(
                    icon: LucideIcons.alertCircle,
                    color: AppColors.error,
                    title: 'دين متأخر على ${d.name}',
                    subtitle: 'القيمة: ${d.amount} شيكل',
                    time: now.difference(d.dueDate!).inDays == 0 ? 'اليوم' : 'تأخر منذ ${now.difference(d.dueDate!).inDays} يوم',
                    unread: true,
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],

          if (upcomingDebts.isNotEmpty) ...[
            Text(
              'ديون قادمة قريباً',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            for (final d in upcomingDebts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      AppPageRoute(builder: (_) => CustomerDetailScreen(debtor: d)),
                    );
                  },
                  child: _NotifTile(
                    icon: LucideIcons.calendarClock,
                    color: AppColors.warning,
                    title: 'موعد سداد قريب لـ ${d.name}',
                    subtitle: 'القيمة: ${d.amount} شيكل',
                    time: d.dueDate!.difference(now).inDays == 0 ? 'اليوم' : 'متبقي ${d.dueDate!.difference(now).inDays} يوم',
                    unread: true,
                  ),
                ),
              ),
          ],
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
    this.subtitle,
    required this.time,
    required this.unread,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
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
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
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
