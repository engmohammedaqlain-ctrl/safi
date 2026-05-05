import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../bootstrap/prefs_keys.dart';
import '../bootstrap/startup_ledger_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/safi_brand_mark.dart';
import '../widgets/vault_branded_shell.dart';
import 'nav_provider.dart';
import 'package:safi/core/router/app_page_route.dart';
import '../../features/debts/providers/debts_ui_provider.dart';
import '../../features/debts/screens/debt_collection_screen.dart';
import '../../features/debts/screens/debts_screen.dart';
import '../../features/more/screens/more_home_screen.dart';
import '../../features/reports/screens/unified_reports_screen.dart';
import '../../features/sales/screens/sales_screen.dart';

import '../../features/settings/providers/team_provider.dart';

class HideBalanceNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final hideBalanceProvider = NotifierProvider<HideBalanceNotifier, bool>(
  HideBalanceNotifier.new,
);

final userNameProvider = FutureProvider<String>((ref) async {
  final p = await SharedPreferences.getInstance();
  return p.getString(PrefsKeys.userName) ?? 'المستخدم الأول';
});

/// الاسم المعروض في الهيدر والمزيد — يُحدَّث فوراً عند [AppSessionNotifier.saveName] (لا يعتمد على إعادة جلب Future).
String _displayStoreTitleFromBootstrap() {
  final t = StartupLedgerData.bootstrapUserName?.trim() ?? '';
  return t.isEmpty ? 'المستخدم الأول' : t;
}

class DisplayStoreNameNotifier extends Notifier<String> {
  @override
  String build() => _displayStoreTitleFromBootstrap();

  void setFromSavedName(String raw) {
    final t = raw.trim();
    state = t.isEmpty ? 'المستخدم الأول' : t;
  }
}

final displayStoreNameProvider =
    NotifierProvider<DisplayStoreNameNotifier, String>(
      DisplayStoreNameNotifier.new,
    );

/// عنوان وبطّاقة المتجر من التخزين — يُفعَّل تجديد الواجهة بعد «إعدادات المتجر».
final storeCardDisplayProvider =
    FutureProvider.autoDispose<({String title, String subtitle})>((ref) async {
      final p = await SharedPreferences.getInstance();
      final rawName = (p.getString(PrefsKeys.userName) ?? '').trim();
      final title = rawName.isEmpty ? 'المستخدم الأول' : rawName;

      final curRaw = (p.getString(PrefsKeys.storeCurrencyLabel) ?? 'شيكل (₪)')
          .trim();
      final addrRaw = (p.getString(PrefsKeys.storeAddress) ?? '').trim();
      final currency = curRaw.isEmpty ? 'شيكل (₪)' : curRaw;
      final subtitle = [currency, if (addrRaw.isNotEmpty) addrRaw].join(' · ');

      return (title: title, subtitle: subtitle);
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

  bool _isProgrammaticNav = false;

  /// يُستدعى عند الضغط على أيقونة الشريط السفلي → انتقال بانزلاق+تلاشٍ
  void _onNavTap(int index) {
    _isProgrammaticNav = true;
    ref.read(navIndexProvider.notifier).goTo(index);
    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOutCubic,
        )
        .then((_) => _isProgrammaticNav = false);
  }

  /// يُستدعى عند السحب اليدوي → تحديث الـ provider بالصفحة الجديدة
  void _onPageChanged(int index) {
    if (!_isProgrammaticNav) {
      ref.read(navIndexProvider.notifier).goTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(navIndexProvider);
    final debtsLedgerTab = ref.watch(debtsLedgerTabProvider);
    final storeDisplayTitle = ref.watch(displayStoreNameProvider);
    final isDebtsShell = index == 0;
    final isSuppliersInDebts = debtsLedgerTab == 1;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A24),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const VaultBackgroundDecor(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              textDirection: TextDirection.rtl,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                  ),
                                  child: const SafiBrandMark(size: 26),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    storeDisplayTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.headlineSmall.copyWith(
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الصافي: ديونك وكل محافظك معاً',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (isDebtsShell) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _VaultHeaderIconButton(
                              icon: LucideIcons.coins,
                              tooltip: 'تجميع الديون',
                              onTap: () => Navigator.of(context).push<void>(
                                AppPageRoute<void>(
                                  builder: (_) => DebtCollectionScreen(
                                    suppliersOnly: isSuppliersInDebts,
                                  ),
                                ),
                              ),
                            ),
                            Consumer(
                              builder: (context, ref, _) {
                                final permsAsync = ref.watch(
                                  userPermissionsProvider,
                                );
                                final roleAsync = ref.watch(userRoleProvider);
                                final canViewStats =
                                    permsAsync.value?.contains(
                                      'view_statistics',
                                    ) ??
                                    false;
                                final isOwner = roleAsync.when(
                                  data: (r) => r == 'owner',
                                  loading: () => true,
                                  error: (_, __) => true,
                                );

                                if (!isOwner && !canViewStats)
                                  return const SizedBox.shrink();

                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: _VaultHeaderIconButton(
                                    icon: LucideIcons.fileSpreadsheet,
                                    tooltip: 'التقارير',
                                    onTap: () =>
                                        Navigator.of(context).push<void>(
                                          AppPageRoute<void>(
                                            builder: (_) =>
                                                UnifiedReportsScreen(
                                                  initialFilter:
                                                      isSuppliersInDebts
                                                      ? AppReportDebtFilter
                                                            .suppliersOnly
                                                      : AppReportDebtFilter
                                                            .customersOnly,
                                                  lockDebtScope: true,
                                                ),
                                          ),
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                      ],
                      Consumer(
                        builder: (context, ref, _) {
                          final hidden = ref.watch(hideBalanceProvider);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => ref
                                  .read(hideBalanceProvider.notifier)
                                  .toggle(),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Icon(
                                  hidden ? LucideIcons.eyeOff : LucideIcons.eye,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 30,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Material(
                            color: AppColors.background,
                            child: SafeArea(
                              top: false,
                              bottom: false,
                              child: _FadingPageView(
                                controller: _pageController,
                                pageCount: _pageCount,
                                onPageChanged: _onPageChanged,
                                pages: [
                                  const RepaintBoundary(child: DebtsScreen()),
                                  RepaintBoundary(child: SalesScreen()),
                                  const RepaintBoundary(
                                    child: MoreHomeScreen(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            border: Border(
                              top: BorderSide(
                                color: AppColors.outlineSoft,
                                width: 1,
                              ),
                            ),
                          ),
                          child: _SafiCompactBottomNav(
                            index: index,
                            onTap: _onNavTap,
                            bottomInset: MediaQuery.paddingOf(context).bottom,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VaultHeaderIconButton extends StatelessWidget {
  const _VaultHeaderIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}

// ══════════════════════════════════════════════════════════════
//  شريط سفلي ثلاثي — صف واحد بحيث يمتد كل تبويب بعرض المتاح (بدون فراغ أفقي كبير)
// ══════════════════════════════════════════════════════════════
class _SafiCompactBottomNav extends StatelessWidget {
  const _SafiCompactBottomNav({
    required this.index,
    required this.onTap,
    required this.bottomInset,
  });

  final int index;
  final ValueChanged<int> onTap;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    Widget item(int i, String label, Widget Function(bool sel) leading) {
      final sel = index == i;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(i),
            splashColor: AppColors.primary.withValues(alpha: 0.09),
            highlightColor: AppColors.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: leading(sel),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                        color: sel ? AppColors.primary : AppColors.textMuted,
                        height: 1.06,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppColors.backgroundSecondary,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: 62,
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              item(
                0,
                'دفتر الديون',
                (sel) => Icon(
                  LucideIcons.bookMarked,
                  size: sel ? 26 : 24,
                  color: sel ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              item(
                1,
                'الصافي',
                (sel) => Text(
                  'ص',
                  style: TextStyle(
                    fontSize: sel ? 22 : 20,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    color: sel ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ),
              item(
                2,
                'المزيد',
                (sel) => Icon(
                  LucideIcons.layoutGrid,
                  size: sel ? 26 : 24,
                  color: sel ? AppColors.primary : AppColors.textMuted,
                ),
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
        return Opacity(opacity: _opacityFor(index), child: widget.pages[index]);
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
