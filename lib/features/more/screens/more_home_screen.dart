import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
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

/// مركز وصول لبقية أقسام التطبيق
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
        // ── وصول سريع ──
        _SectionLabel('الوصول السريع'),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _NavTile(
                icon: LucideIcons.bell,
                title: 'الإشعارات',
                onTap: () => _push(context, const NotificationsScreen()),
              ),
              const Divider(height: 1, indent: 52),
              _NavTile(
                icon: LucideIcons.layoutGrid,
                title: 'لوحة التحكم',
                onTap: () =>
                    _push(context, const HomeScreen(bottomContentPadding: 32)),
              ),
              const Divider(height: 1, indent: 52),
              _NavTile(
                icon: LucideIcons.users,
                title: 'عملائي',
                onTap: () => _push(context, const AllCustomersScreen()),
              ),
              const Divider(height: 1, indent: 52),
              _NavTile(
                icon: LucideIcons.package,
                title: 'المخزون',
                onTap: () => _push(
                  context,
                  const InventoryScreen(bottomContentPadding: 32),
                ),
              ),
              const Divider(height: 1, indent: 52),
              _NavTile(
                icon: LucideIcons.barChart2,
                title: 'التقارير',
                onTap: () => _push(
                  context,
                  const ReportsScreen(bottomContentPadding: 32),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── عمليات ──
        _SectionLabel('العمليات'),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _NavTile(
                icon: LucideIcons.userPlus,
                title: 'تسجيل دين',
                onTap: () => _push(context, const AddDebtScreen()),
              ),
              const Divider(height: 1, indent: 52),
              _NavTile(
                icon: LucideIcons.banknote,
                title: 'تسجيل دفعة',
                onTap: () => _push(context, const RecordPaymentScreen()),
              ),
              const Divider(height: 1, indent: 52),
              _NavTile(
                icon: LucideIcons.plusCircle,
                title: 'بيع جديد',
                onTap: () => _push(context, const NewSaleScreen()),
              ),
              const Divider(height: 1, indent: 52),
              _NavTile(
                icon: LucideIcons.arrowLeftRight,
                title: 'قيد مالي (وارد / صادر)',
                onTap: () => _push(context, const CashEntryScreen()),
              ),
              const Divider(height: 1, indent: 52),
              _NavTile(
                icon: LucideIcons.archive,
                title: 'أرشيف المعاملات',
                onTap: () => _push(context, const CashFlowScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── المخزون ──
        _SectionLabel('المخزون'),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _NavTile(
                icon: LucideIcons.packagePlus,
                title: 'إضافة منتج',
                onTap: () => _push(context, const AddProductScreen()),
              ),
              const Divider(height: 1, indent: 52),
              _NavTile(
                icon: LucideIcons.trash2,
                title: 'حذف أو أرشفة منتج',
                iconColor: AppColors.error,
                onTap: () => _push(context, const DeleteProductsScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── الحساب ──
        _SectionLabel('الحساب'),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _NavTile(
                icon: LucideIcons.sparkles,
                title: 'المساعد الذكي',
                onTap: () => _push(context, const AiAssistantScreen()),
              ),
              const Divider(height: 1, indent: 52),
              _NavTile(
                icon: LucideIcons.settings,
                title: 'الإعدادات',
                onTap: () => _push(context, const SettingsScreen()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── عنوان القسم ──
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

// ── صف تنقل ──
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
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
      trailing: const Icon(
        LucideIcons.chevronLeft,
        size: 18,
        color: AppColors.textMuted,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      dense: true,
      minVerticalPadding: 8,
    );
  }
}
