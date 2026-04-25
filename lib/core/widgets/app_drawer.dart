import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../router/nav_provider.dart';
import '../theme/app_colors.dart';
import '../../features/ai_assistant/screens/ai_assistant_screen.dart';
import '../../features/cash_flow/screens/cash_entry_screen.dart';
import '../../features/cash_flow/screens/cash_flow_screen.dart';
import '../../features/debts/screens/add_debt_screen.dart';
import '../../features/debts/screens/record_payment_screen.dart';
import '../../features/inventory/screens/add_product_screen.dart';
import '../../features/inventory/screens/delete_products_screen.dart';
import '../../features/sales/screens/new_sale_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import 'drawer_section.dart';

/// درج التنقّل — ترتيب إنتاجي: أقسام → عمليات → أدوات → حساب
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const DrawerHeaderBrand(),
            const SizedBox(height: 4),
            const DrawerSectionHeader(
              'الأقسام',
              subtitle: 'ينطبق مع شريط التنقّل السفلي',
            ),
            DrawerGrouped(
              children: [
                DrawerSubtleTile(
                  icon: LucideIcons.layoutGrid,
                  label: 'الرئيسية',
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navIndexProvider.notifier).goTo(0);
                  },
                ),
                DrawerSubtleTile(
                  icon: LucideIcons.shoppingCart,
                  label: 'نقطة البيع',
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navIndexProvider.notifier).goTo(1);
                  },
                ),
                DrawerSubtleTile(
                  icon: LucideIcons.package,
                  label: 'المخزون',
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navIndexProvider.notifier).goTo(2);
                  },
                ),
                DrawerSubtleTile(
                  icon: LucideIcons.wallet,
                  label: 'الديون',
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navIndexProvider.notifier).goTo(3);
                  },
                ),
                DrawerSubtleTile(
                  icon: LucideIcons.barChart2,
                  label: 'التقارير',
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navIndexProvider.notifier).goTo(4);
                  },
                ),
              ],
            ),
            const DrawerSectionHeader('المبيعات والمخزون'),
            DrawerGrouped(
              children: [
                DrawerTile(
                  icon: LucideIcons.packagePlus,
                  label: 'إضافة منتج',
                  subtitle: 'اسم، باركود، سعر',
                  onTap: () => _push(context, const AddProductScreen()),
                ),
                DrawerTile(
                  icon: LucideIcons.trash2,
                  label: 'حذف أو أرشفة منتج',
                  subtitle: 'مع تأكيد',
                  onTap: () => _push(context, const DeleteProductsScreen()),
                  iconColor: AppColors.error,
                ),
                DrawerTile(
                  icon: LucideIcons.plusCircle,
                  label: 'بيع جديد',
                  subtitle: 'شاشة بيع كاملة',
                  onTap: () => _push(context, const NewSaleScreen()),
                ),
              ],
            ),
            const DrawerSectionHeader('الديون والمال'),
            DrawerGrouped(
              children: [
                DrawerTile(
                  icon: LucideIcons.userPlus,
                  label: 'تسجيل دين',
                  onTap: () => _push(context, const AddDebtScreen()),
                ),
                DrawerTile(
                  icon: LucideIcons.banknote,
                  label: 'تسجيل دفعة',
                  onTap: () => _push(context, const RecordPaymentScreen()),
                ),
                DrawerTile(
                  icon: LucideIcons.landmark,
                  label: 'قيد مالي (وارد / صادر)',
                  onTap: () =>
                      _push(context, const CashEntryScreen()),
                ),
              ],
            ),
            const DrawerSectionHeader('التشغيل والذكاء'),
            DrawerGrouped(
              children: [
                DrawerTile(
                  icon: LucideIcons.arrowLeftRight,
                  label: 'التدفق المالي',
                  onTap: () => _push(context, const CashFlowScreen()),
                ),
                DrawerTile(
                  icon: LucideIcons.sparkles,
                  label: 'المساعد الذكي',
                  onTap: () => _push(context, const AiAssistantScreen()),
                ),
              ],
            ),
            const DrawerSectionHeader('الحساب'),
            DrawerGrouped(
              children: [
                DrawerTile(
                  icon: LucideIcons.settings,
                  label: 'الإعدادات',
                  subtitle: 'المتجر، الفريق، تسجيل الخروج',
                  onTap: () => _push(context, const SettingsScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
