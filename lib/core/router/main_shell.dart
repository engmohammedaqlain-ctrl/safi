import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/animated_page_switcher.dart';
import '../widgets/app_drawer.dart';
import '../widgets/glass_card.dart';
import 'nav_provider.dart';
import '../../features/debts/screens/add_debt_screen.dart';
import '../../features/debts/screens/record_payment_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/inventory/screens/add_product_screen.dart';
import '../../features/inventory/screens/delete_products_screen.dart';
import '../../features/sales/screens/new_sale_screen.dart';
import '../../features/sales/screens/sales_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/debts/screens/debts_screen.dart';
import '../../features/reports/screens/reports_screen.dart';

const _shellTitles = <String>[
  'الرئيسية',
  'نقطة البيع',
  'المخزون',
  'الديون',
  'التقارير',
];

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navIndexProvider);

    const pages = <Widget>[
      HomeScreen(),
      SalesScreen(),
      InventoryScreen(),
      DebtsScreen(),
      ReportsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          _shellTitles[index],
          style: AppTextStyles.titleLarge,
        ),
        actions: _appBarActions(context, index),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          top: false,
          child: AnimatedPageSwitcher(
            pageKey: index,
            child: pages[index],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundSecondary,
          border: Border(
            top: BorderSide(color: AppColors.outlineSoft),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              background: AppColors.backgroundSecondary,
              child: NavigationBar(
                height: 60,
                backgroundColor: Colors.transparent,
                selectedIndex: index,
                indicatorColor: AppColors.primary.withValues(alpha: 0.12),
                onDestinationSelected: (i) {
                  ref.read(navIndexProvider.notifier).goTo(i);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(LucideIcons.layoutGrid),
                    label: 'الرئيسية',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.shoppingCart),
                    label: 'مبيعات',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.package),
                    label: 'مخزون',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.wallet),
                    label: 'ديون',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.barChart2),
                    label: 'تقارير',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// إجراءات سياقية حسب التبويب — وصول سريع لعمليات الإضافة/الحذف
List<Widget> _appBarActions(BuildContext context, int index) {
  void push(Widget page) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  final bell = IconButton(
    onPressed: () {},
    icon: const Icon(LucideIcons.bell, size: 22),
    color: AppColors.textSecondary,
    tooltip: 'إشعارات',
  );

  switch (index) {
    case 1:
      return [
        IconButton(
          tooltip: 'بيع جديد',
          onPressed: () => push(const NewSaleScreen()),
          icon: const Icon(LucideIcons.plusCircle, size: 22),
          color: AppColors.primary,
        ),
        bell,
      ];
    case 2:
      return [
        IconButton(
          tooltip: 'إضافة منتج',
          onPressed: () => push(const AddProductScreen()),
          icon: const Icon(LucideIcons.packagePlus, size: 22),
          color: AppColors.primary,
        ),
        IconButton(
          tooltip: 'حذف أو أرشفة',
          onPressed: () => push(const DeleteProductsScreen()),
          icon: const Icon(LucideIcons.trash2, size: 22),
          color: AppColors.error,
        ),
        bell,
      ];
    case 3:
      return [
        IconButton(
          tooltip: 'تسجيل دين',
          onPressed: () => push(const AddDebtScreen()),
          icon: const Icon(LucideIcons.userPlus, size: 22),
          color: AppColors.primary,
        ),
        IconButton(
          tooltip: 'تسجيل دفعة',
          onPressed: () => push(const RecordPaymentScreen()),
          icon: const Icon(LucideIcons.banknote, size: 22),
          color: AppColors.success,
        ),
        bell,
      ];
    case 4:
      return [
        IconButton(
          tooltip: 'تصدير التقرير',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('التصدير متاح في الإصدار القادم')),
            );
          },
          icon: const Icon(LucideIcons.share, size: 22),
          color: AppColors.primary,
        ),
        bell,
      ];
    default:
      return [bell];
  }
}
