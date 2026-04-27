import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../bootstrap/prefs_keys.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/animated_page_switcher.dart';
import 'nav_provider.dart';
import '../../features/more/screens/more_home_screen.dart';
import '../../features/more/screens/notifications_screen.dart';
import '../../features/sales/screens/sales_screen.dart';
import '../../features/debts/screens/debts_screen.dart';

class HideBalanceNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final hideBalanceProvider = NotifierProvider<HideBalanceNotifier, bool>(HideBalanceNotifier.new);

final userNameProvider = FutureProvider<String>((ref) async {
  final p = await SharedPreferences.getInstance();
  return p.getString(PrefsKeys.userName) ?? 'المستخدم الأول';
});

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
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final hidden = ref.watch(hideBalanceProvider);
                    return GestureDetector(
                      onTap: () => ref.read(hideBalanceProvider.notifier).toggle(),
                      child: _TopBarIcon(
                        icon: hidden ? LucideIcons.eyeOff : LucideIcons.eye,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final asyncName = ref.watch(userNameProvider);
                    return Text(
                      asyncName.value ?? '',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.bookOpen, color: AppColors.primary),
              ],
            ),
          ],
        ),
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
                icon: Icon(LucideIcons.bookOpen, size: 22),
                label: 'دفتر الديون',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.wallet, size: 22),
                label: 'دفتر النقدية',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.layoutGrid, size: 22),
                label: 'المزيد',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBarIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _TopBarIcon({required this.icon, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
