import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/safi_button.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.headline,
    required this.body,
    required this.icon,
    required this.gradientColors,
    required this.cardTag,
  });

  final String headline;
  final String body;
  final IconData icon;
  final List<Color> gradientColors;

  /// سطر مختصر على شكل «بطاقة بنكية»
  final String cardTag;
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _i = 0;

  static final _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      headline: 'محافظك وأرصدتك في مكان واحد',
      body:
          'نظّم محافظك النقدية والبنكية، وتابع الوارد والصادر لصورة مالية موحّدة.',
      icon: LucideIcons.wallet,
      gradientColors: const [Color(0xFF9C27B0), Color(0xFF6A1B9A), Color(0xFF4A148C)],
      cardTag: 'ملخص الأرصدة',
    ),
    _OnboardingSlide(
      headline: 'الديون والمستحقات تحت السيطرة',
      body:
          'سجّل ما لك وما عليك، وراقب المبالغ والمواعيد لتبقى صاف حسابك.',
      icon: LucideIcons.barChart2,
      gradientColors: const [Color(0xFF66BB6A), Color(0xFF388E3C), Color(0xFF1B5E20)],
      cardTag: 'المستحقات',
    ),
    _OnboardingSlide(
      headline: 'عملاؤك ومديونيتهم',
      body:
          'أضف من تتعامل معهم، وتابع رصيد كل عميل وحركات السداد بتفاصيلها.',
      icon: LucideIcons.users,
      gradientColors: const [Color(0xFFB39DDB), Color(0xFF7E57C2), Color(0xFF4527A0)],
      cardTag: 'سجل العملاء',
    ),
    _OnboardingSlide(
      headline: 'تذكيرات ذكية للتحصيل',
      body:
          'فعّل رسائل التذكير لتقليل التأخير، وتسريع استرداد حقوقك المالية.',
      icon: LucideIcons.sparkles,
      gradientColors: const [Color(0xFFCE93D8), Color(0xFF8E24AA), Color(0xFF4A148C)],
      cardTag: 'التحصيل الذكي',
    ),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_i < _slides.length - 1) {
      await _page.nextPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    } else {
      await ref.read(appSessionProvider.notifier).onOnboardingComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A24),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _VaultBackgroundDecor(),
          Column(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.landmark,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'صافي',
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'خبرة بنكية مبسّطة لإدارة ديونك ومحافظك',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: _PageDots(
                          count: _slides.length,
                          index: _i,
                        ),
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
                    color: const Color(0xFFF2F4F8),
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
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _page,
                            onPageChanged: (v) => setState(() => _i = v),
                            itemCount: _slides.length,
                            itemBuilder: (context, index) {
                              final slide = _slides[index];
                              return LayoutBuilder(
                                builder: (context, c) {
                                  return SingleChildScrollView(
                                    padding: EdgeInsets.fromLTRB(
                                      AppSpacing.lg,
                                      28,
                                      AppSpacing.lg,
                                      12,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: c.maxHeight - 12,
                                      ),
                                      child: Column(
                                        children: [
                                          _BankPlasticCard(
                                            slide: slide,
                                          ),
                                          const SizedBox(height: 28),
                                          Text(
                                            'الخطوة ${index + 1} من ${_slides.length}',
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                              color: AppColors.textMuted,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            slide.headline,
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.headlineSmall
                                                .copyWith(
                                              height: 1.3,
                                              color: const Color(0xFF12121F),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            slide.body,
                                            textAlign: TextAlign.center,
                                            style:
                                                AppTextStyles.bodyMedium.copyWith(
                                              height: 1.65,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            border: Border(
                              top: BorderSide(
                                color: AppColors.outlineSoft,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.shieldCheck,
                                size: 18,
                                color: AppColors.primary.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'بياناتك محمية وفق معايير آمنة للتعاملات المالية',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            AppSpacing.lg + bottomInset,
                          ),
                          child: SafiButton(
                            label: _i < _slides.length - 1
                                ? 'التالي'
                                : 'ابدأ استخدام صافي',
                            icon: _i < _slides.length - 1
                                ? LucideIcons.arrowLeft
                                : LucideIcons.check,
                            onPressed: _next,
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

/// خلفية داكنة مع وهج خفيف تشبه واجهات البنوك الرقمية
class _VaultBackgroundDecor extends StatelessWidget {
  const _VaultBackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A0A24),
                AppColors.primaryDark,
                const Color(0xFF4A148C).withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -60,
          left: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned(
          top: 120,
          right: -50,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          bottom: 180,
          left: 40,
          child: IgnorePointer(
            child: CustomPaint(
              size: const Size(120, 120),
              painter: _GridDotsPainter(
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GridDotsPainter extends CustomPainter {
  _GridDotsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 14.0;
    final paint = Paint()..color = color;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.index,
  });

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (j) {
        final active = j == index;
        final done = j < index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: active ? 28 : 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: active || done
                ? Colors.white
                : Colors.white.withValues(alpha: 0.28),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

/// بطاقة بلاستيكية بتفاصيل تشبه بطاقة بنك (شريحة + شعار + تدرج)
class _BankPlasticCard extends StatelessWidget {
  const _BankPlasticCard({
    required this.slide,
  });

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      height: 196,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide.gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: slide.gradientColors.last.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              LucideIcons.circle,
              size: 140,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF0E6D2),
                          Color(0xFFC9A66B),
                          Color(0xFF9A7847),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: AppRadius.rfull,
                    ),
                    child: Text(
                      'صافي',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slide.cardTag,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '••••  ••••  ••••  8821',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      slide.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
