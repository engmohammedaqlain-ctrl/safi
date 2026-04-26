import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/animated_page_switcher.dart';
import '../widgets/glass_card.dart';
import 'nav_provider.dart';
import '../../features/more/screens/more_home_screen.dart';
import '../../features/more/screens/notifications_screen.dart';
import '../../features/sales/screens/sales_screen.dart';
import '../../features/debts/screens/debts_screen.dart';

const _shellTitles = <String>[
  'الديون',
  'كاشير وباركود',
  'المزيد',
];

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
          style: AppTextStyles.titleLarge,
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: Badge(
              backgroundColor: AppColors.error,
              smallSize: 7,
              largeSize: 20,
              label: const Text('2', style: TextStyle(fontSize: 10, height: 1)),
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
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            top: false,
            child: AnimatedPageSwitcher(
              pageKey: index,
              child: pages[index],
            ),
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
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              background: AppColors.backgroundSecondary,
              child: NavigationBar(
                height: 56,
                backgroundColor: Colors.transparent,
                selectedIndex: index,
                indicatorColor: AppColors.primary.withValues(alpha: 0.12),
                onDestinationSelected: (i) {
                  ref.read(navIndexProvider.notifier).goTo(i);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(LucideIcons.wallet),
                    label: 'ديون',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.scanLine),
                    label: 'كاشير',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.menu),
                    label: 'المزيد',
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
