import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/drawer_section.dart';
import '../../../core/widgets/glass_card.dart';
import '../../ai_assistant/screens/ai_assistant_screen.dart';
import '../../cash_flow/screens/cash_entry_screen.dart';
import '../../cash_flow/screens/cash_flow_screen.dart';
import '../../debts/screens/add_debt_screen.dart';
import '../../debts/screens/all_customers_screen.dart';
import '../../debts/screens/record_payment_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../inventory/screens/add_product_screen.dart';
import '../../inventory/screens/delete_products_screen.dart';
import '../../inventory/screens/inventory_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../sales/screens/new_sale_screen.dart';
import '../../settings/screens/settings_screen.dart';
import 'notifications_screen.dart';

/// مركز وصول لبقية أقسام التطبيق (عند اختيار تبويب «المزيد»)
class MoreHomeScreen extends StatelessWidget {
  const MoreHomeScreen({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        100,
      ),
      children: [
        const DrawerHeaderBrand(),
        const SizedBox(height: 8),
        Text('كل الأقسام', style: AppTextStyles.titleMedium),
        const SizedBox(height: 4),
        Text(
          'نفس تفاصيل القائمة الجانبية — من مكان واحد بلا عناصر بعيدة في الأعلى',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: _MoreNavTile(
            icon: LucideIcons.bell,
            title: 'الإشعارات',
            subtitle: 'نفس الصفحة من أيقونة الجرس أعلاه',
            onTap: () => _push(context, const NotificationsScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const DrawerSectionHeader('الوصول السريع'),
        GlassCard(
          child: Column(
            children: [
              _MoreNavTile(
                icon: LucideIcons.users,
                title: 'عملائي',
                subtitle: 'كل العملاء، بحث وملف كل زبون',
                onTap: () => _push(context, const AllCustomersScreen()),
              ),
              const Divider(height: 1),
              _MoreNavTile(
                icon: LucideIcons.layoutGrid,
                title: 'لوحة التحكم',
                subtitle: 'ملخص مبيعات وديون وتدفق',
                onTap: () => _push(
                  context,
                  const HomeScreen(bottomContentPadding: 32),
                ),
              ),
              const Divider(height: 1),
              _MoreNavTile(
                icon: LucideIcons.package,
                title: 'المخزون',
                subtitle: 'منتجات ورصيد وتنبيهات',
                onTap: () => _push(
                  context,
                  const InventoryScreen(bottomContentPadding: 32),
                ),
              ),
              const Divider(height: 1),
              _MoreNavTile(
                icon: LucideIcons.barChart2,
                title: 'التقارير',
                subtitle: 'مبيعات وربحية',
                onTap: () => _push(
                  context,
                  const ReportsScreen(bottomContentPadding: 32),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const DrawerSectionHeader('العمليات'),
        GlassCard(
          child: Column(
            children: [
              _MoreNavTile(
                icon: LucideIcons.packagePlus,
                title: 'إضافة منتج',
                onTap: () => _push(context, const AddProductScreen()),
              ),
              const Divider(height: 1),
              _MoreNavTile(
                icon: LucideIcons.trash2,
                title: 'حذف أو أرشفة منتج',
                iconColor: AppColors.error,
                onTap: () => _push(context, const DeleteProductsScreen()),
              ),
              const Divider(height: 1),
              _MoreNavTile(
                icon: LucideIcons.plusCircle,
                title: 'بيع جديد',
                onTap: () => _push(context, const NewSaleScreen()),
              ),
              const Divider(height: 1),
              _MoreNavTile(
                icon: LucideIcons.userPlus,
                title: 'تسجيل دين',
                onTap: () => _push(context, const AddDebtScreen()),
              ),
              const Divider(height: 1),
              _MoreNavTile(
                icon: LucideIcons.banknote,
                title: 'تسجيل دفعة',
                onTap: () => _push(context, const RecordPaymentScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const DrawerSectionHeader('المال والأدوات'),
        GlassCard(
          child: Column(
            children: [
              _MoreNavTile(
                icon: LucideIcons.arrowLeftRight,
                title: 'التدفق المالي',
                onTap: () => _push(context, const CashFlowScreen()),
              ),
              const Divider(height: 1),
              _MoreNavTile(
                icon: LucideIcons.landmark,
                title: 'قيد مالي (وارد / صادر)',
                onTap: () => _push(context, const CashEntryScreen()),
              ),
              const Divider(height: 1),
              _MoreNavTile(
                icon: LucideIcons.sparkles,
                title: 'المساعد الذكي',
                onTap: () => _push(context, const AiAssistantScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const DrawerSectionHeader('الحساب'),
        GlassCard(
          child: _MoreNavTile(
            icon: LucideIcons.settings,
            title: 'الإعدادات',
            subtitle: 'المتجر، تسجيل الخروج',
            onTap: () => _push(context, const SettingsScreen()),
          ),
        ),
      ],
    );
  }
}

class _MoreNavTile extends StatelessWidget {
  const _MoreNavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
      title: Text(title, style: AppTextStyles.titleSmall),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.bodySmall,
            )
          : null,
      trailing: const Icon(
        LucideIcons.chevronLeft,
        size: 20,
        color: AppColors.textMuted,
      ),
    );
  }
}
