import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/bootstrap/prefs_keys.dart';
import '../../../core/router/app_page_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../ai_assistant/screens/ai_assistant_screen.dart';
import '../../debts/screens/all_customers_screen.dart';
import '../../reports/screens/unified_reports_screen.dart';
import '../../reports/screens/statistics_screen.dart';
import '../../settings/screens/settings_screen.dart';
import 'notifications_screen.dart';

/// مركز الوصول — تصميم سلس ومُبسَّط بلا تكرار
/// كل ما هنا غير موجود في تبويبات التطبيق الأخرى.
class MoreHomeScreen extends ConsumerWidget {
  const MoreHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void push(Widget page) {
      Navigator.push<void>(
        context,
        AppPageRoute<void>(builder: (_) => page),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            // ── بطاقة المستخدم ──
            const _UserHeaderCard(),
            const SizedBox(height: 22),

            // ── 5 أزرار رئيسية ──
            _SoftMenu(
              items: [
                _MenuItem(
                  icon: LucideIcons.users,
                  title: 'عملائي',
                  subtitle: 'كل العملاء والموردين',
                  onTap: () => push(const AllCustomersScreen()),
                ),
                _MenuItem(
                  icon: LucideIcons.bell,
                  title: 'الإشعارات',
                  subtitle: 'التذكيرات والتنبيهات',
                  onTap: () => push(const NotificationsScreen()),
                ),
                _MenuItem(
                  icon: LucideIcons.pieChart,
                  title: 'الإحصائيات',
                  subtitle: 'تحليل ذكي ورسوم بيانية',
                  onTap: () => push(const StatisticsScreen()),
                ),
                _MenuItem(
                  icon: LucideIcons.barChart2,
                  title: 'التقارير',
                  subtitle: 'تحليل الديون والمعاملات',
                  onTap: () => push(
                    const UnifiedReportsScreen(),
                  ),
                ),
                _MenuItem(
                  icon: LucideIcons.sparkles,
                  title: 'المساعد الذكي',
                  subtitle: 'إجابات سريعة عن أعمالك',
                  onTap: () => push(const AiAssistantScreen()),
                ),
                _MenuItem(
                  icon: LucideIcons.settings,
                  title: 'الإعدادات',
                  subtitle: 'الحساب، المزامنة، الجلسة',
                  onTap: () => push(const SettingsScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  بطاقة المستخدم — بنفس روح بطاقة الرصيد في صفحة الديون
// ════════════════════════════════════════════════════════════════
class _UserHeaderCard extends ConsumerWidget {
  const _UserHeaderCard();

  Future<String> _loadName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(PrefsKeys.userName) ?? 'المستخدم';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: _loadName(),
      builder: (context, snap) {
        final name = snap.data ?? '...';
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  LucideIcons.user,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مرحباً بك في صافي',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  قائمة ناعمة — بطاقة بيضاء واحدة بصفوف مفصولة بخطوط رفيعة
//  مطابقة لروح بطاقات صفحة الديون
// ════════════════════════════════════════════════════════════════
class _SoftMenu extends StatelessWidget {
  const _SoftMenu({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF3F0F7),
                ),
              ),
            items[i],
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                LucideIcons.chevronLeft,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
