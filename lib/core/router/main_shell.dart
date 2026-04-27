import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../bootstrap/prefs_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'nav_provider.dart';
import '../../features/more/screens/more_home_screen.dart';
import '../../features/sales/screens/sales_screen.dart';
import '../../features/debts/screens/debts_screen.dart';

class HideBalanceNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final hideBalanceProvider =
    NotifierProvider<HideBalanceNotifier, bool>(HideBalanceNotifier.new);

final userNameProvider = FutureProvider<String>((ref) async {
  final p = await SharedPreferences.getInstance();
  return p.getString(PrefsKeys.userName) ?? 'المستخدم الأول';
});

// ──────────────────────────────────────────────────────────────
// Shell رئيسية مع PageView قابل للسحب ← تلاشٍ خفيف بين الصفحات
// ──────────────────────────────────────────────────────────────
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late final PageController _pageController;

  /// عدد الصفحات
  static const int _pageCount = 3;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(navIndexProvider);
    _pageController = PageController(initialPage: initial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// يُستدعى عند الضغط على أيقونة الشريط السفلي → انتقال بانزلاق+تلاشٍ
  void _onNavTap(int index) {
    ref.read(navIndexProvider.notifier).goTo(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  /// يُستدعى عند السحب اليدوي → تحديث الـ provider بالصفحة الجديدة
  void _onPageChanged(int index) {
    ref.read(navIndexProvider.notifier).goTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(navIndexProvider);

    // إذا طلب الـ provider صفحةً مختلفة (مثلاً deep link أو إعادة تحميل)
    // نتأكد أن PageView يتبعه دون أنيميشن مكرّر
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        final current = _pageController.page?.round() ?? 0;
        if (current != index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.rtl,
          children: [
            // RTL: start=يمين → أول مُعرَف: العين
            Consumer(
              builder: (context, ref, _) {
                final hidden = ref.watch(hideBalanceProvider);
                return GestureDetector(
                  onTap: () =>
                      ref.read(hideBalanceProvider.notifier).toggle(),
                  child: _TopBarIcon(
                    icon: hidden ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: AppColors.primary,
                    bgColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                );
              },
            ),
            // ثانياً: الاسم + الدفتر (جهة يسار الشاشة)
            Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                const Icon(LucideIcons.bookOpen, color: AppColors.primary),
                const SizedBox(width: 8),
                Consumer(
                  builder: (context, ref, _) {
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
              ],
            ),
          ],
        ),
      ),
      body: Material(
        color: AppColors.background,
        child: SafeArea(
          top: false,
          // ────────────────────────────────────────────────
          // PageView مع تأثير تلاشٍ تدريجي أثناء التمرير
          // ────────────────────────────────────────────────
          child: _FadingPageView(
            controller: _pageController,
            pageCount: _pageCount,
            onPageChanged: _onPageChanged,
            pages: const [
              RepaintBoundary(child: DebtsScreen()),
              RepaintBoundary(child: SalesScreen()),
              RepaintBoundary(child: MoreHomeScreen()),
            ],
          ),
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
            onDestinationSelected: _onNavTap,
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

// ══════════════════════════════════════════════════════════════
//  PageView مع تلاشٍ خفيف بين الصفحات
// ══════════════════════════════════════════════════════════════
class _FadingPageView extends StatefulWidget {
  const _FadingPageView({
    required this.controller,
    required this.pages,
    required this.pageCount,
    required this.onPageChanged,
  });

  final PageController controller;
  final List<Widget> pages;
  final int pageCount;
  final ValueChanged<int> onPageChanged;

  @override
  State<_FadingPageView> createState() => _FadingPageViewState();
}

class _FadingPageViewState extends State<_FadingPageView> {
  /// الصفحة الحالية كعدد عشري (مثلاً 0.6 أثناء التمرير بين 0 و 1)
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _page = widget.controller.initialPage.toDouble();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    setState(() => _page = widget.controller.page ?? _page);
  }

  /// حساب شفافية كل صفحة بناءً على بُعدها عن الصفحة الحالية
  double _opacityFor(int pageIndex) {
    // كلما اقتربنا من الصفحة كانت الـ opacity = 1
    // نحدّ القيمة بين 0.0 و 1.0
    final dist = (_page - pageIndex).abs();
    // نبدأ التلاشي حين يكون البُعد > 0.3 من الصفحة
    return (1.0 - (dist * 1.4).clamp(0.0, 1.0)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.controller,
      // Flutter يعكس اتجاه PageView تلقائياً مع Directionality(RTL)
      physics: const _SmoothPagePhysics(),
      onPageChanged: widget.onPageChanged,
      itemCount: widget.pageCount,
      itemBuilder: (context, index) {
        return Opacity(
          opacity: _opacityFor(index),
          child: widget.pages[index],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Physics خفيفة: تقلّل من الـ over-scroll وتمنح لمسة بنكية
// ══════════════════════════════════════════════════════════════
class _SmoothPagePhysics extends PageScrollPhysics {
  const _SmoothPagePhysics() : super(parent: const ClampingScrollPhysics());

  @override
  _SmoothPagePhysics applyTo(ScrollPhysics? ancestor) =>
      const _SmoothPagePhysics();

  // زيادة friction → يبدو أثقل وأكثر دقة (مثل تطبيق بنكي)
  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}

// ══════════════════════════════════════════════════════════════
//  أيقونة شريط العنوان
// ══════════════════════════════════════════════════════════════
class _TopBarIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _TopBarIcon(
      {required this.icon, required this.color, required this.bgColor});

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
