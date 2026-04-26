import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/animated_page_switcher.dart';
import 'nav_provider.dart';
import '../../features/more/screens/more_home_screen.dart';
import '../../features/more/screens/notifications_screen.dart';
import '../../features/sales/screens/sales_screen.dart';
import '../../features/debts/screens/debts_screen.dart';

const _shellTitles = <String>['دفتر الديون', 'دفتر النقدية', 'المزيد'];

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navIndexProvider);

    const pages = <Widget>[
      RepaintBoundary(child: DebtsScreen()),
      RepaintBoundary(child: SalesScreen()),
      RepaintBoundary(child: MoreHomeScreen()),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _shellTitles[index],
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 20, // Smaller header font as requested
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.outlineSoft, width: 1),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: Badge(
              backgroundColor: AppColors.primary,
              alignment: const AlignmentDirectional(
                20,
                -18,
              ), // Better positioning
              label: const Text(
                '2',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              child: IconButton(
                tooltip: 'الإشعارات',
                onPressed: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.bell, size: 22),
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      // TextField (بحث وغيره) يتطلّب سلف Material — الشفاف يحافظ على مظهر التدرج
      body: Material(
        color: AppColors.background,
        child: SafeArea(
          top: false,
          child: AnimatedPageSwitcher(pageKey: index, child: pages[index]),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundSecondary,
          border: Border(
            top: BorderSide(color: AppColors.outlineSoft, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 65,
            backgroundColor: AppColors.backgroundSecondary,
            elevation: 0,
            selectedIndex: index,
            indicatorColor: AppColors.primary.withValues(alpha: 0.1),
            onDestinationSelected: (i) {
              ref.read(navIndexProvider.notifier).goTo(i);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(LucideIcons.wallet, size: 22),
                label: 'ديون',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.wallet2, size: 22),
                label: 'نقدية',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.menu, size: 22),
                label: 'المزيد',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
