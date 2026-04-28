import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/safi_button.dart';
import '../../../core/widgets/vault_branded_shell.dart';

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
    return VaultBrandedShell(
      belowBrand: Center(
        child: _PageDots(
          count: _slides.length,
          index: _i,
        ),
      ),
      sheet: Column(
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
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textMuted,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              slide.headline,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headlineSmall.copyWith(
                                height: 1.3,
                                color: const Color(0xFF12121F),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              slide.body,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
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
          const VaultTrustStrip(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
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
    );
  }
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
