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
  });

  final String headline;
  final String body;
  final IconData icon;
}

/// أونبوردينغ بهيكل يقترب من تطبيقات المال الرسمية: ترحيب ثابت، تقدّم واضح، لوحة مركّزة، ثقة خفيفة في النهاية.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _i = 0;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      headline: 'المحافظ والتدفّق النقدي',
      body:
          'سجّل واردك وصادرك عبر المحافظ لتعرف وضعك المالي في لحظة.',
      icon: LucideIcons.wallet,
    ),
    _OnboardingSlide(
      headline: 'الديون والمستحقات',
      body:
          'دوّن ما لك وما عليك، وتابع الأرصدة دون فقدان أي مبلغ.',
      icon: LucideIcons.barChart2,
    ),
    _OnboardingSlide(
      headline: 'عملاؤك وسجلّهم',
      body:
          'اربط المعاملات بالعملاء وراقب مديونية كل واحد على حدة.',
      icon: LucideIcons.users,
    ),
    _OnboardingSlide(
      headline: 'تذكيرات وتحصيل',
      body:
          'استخدم التذكيرات لتبقى التزامات السداد أمامك دائماً.',
      icon: LucideIcons.bell,
    ),
  ];

  static const double _footnoteSlotHeight = 44;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await ref.read(appSessionProvider.notifier).onOnboardingComplete();
  }

  Future<void> _next() async {
    if (_i < _slides.length - 1) {
      await _page.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lavender,
              AppColors.background,
            ],
            stops: [0.0, 0.38],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'صافي',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _complete,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textMuted,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 8,
                            ),
                            minimumSize: const Size(64, 40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'تخطي',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'مرحباً بك',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'محافظك، ديونك، وعملاؤك — من تنظيم واحد واضح',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: _SegmentedProgressBar(
                  currentIndex: _i,
                  segmentCount: _slides.length,
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  onPageChanged: (v) => setState(() => _i = v),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            4,
                            AppSpacing.lg,
                            AppSpacing.sm,
                          ),
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _OnboardingContentCard(
                                  stepIndex: index,
                                  stepCount: _slides.length,
                                  slide: slide,
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
              SizedBox(
                height: _footnoteSlotHeight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _i == _slides.length - 1
                      ? Padding(
                          key: const ValueKey('trust'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: const Center(
                            child: _TrustFootnote(),
                          ),
                        )
                      : const SizedBox(
                          key: ValueKey('empty'),
                          width: double.infinity,
                        ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg + bottomInset,
                ),
                child: SafiButton(
                  label: _i < _slides.length - 1
                      ? 'التالي'
                      : 'بدء استخدام صافي',
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شريط تقدّم مقسّم — خلفية مسار خفيفة لقراءة أوضح.
class _SegmentedProgressBar extends StatelessWidget {
  const _SegmentedProgressBar({
    required this.currentIndex,
    required this.segmentCount,
  });

  final int currentIndex;
  final int segmentCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'الخطوة ${currentIndex + 1} من $segmentCount',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.outlineSoft.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          children: [
            for (int j = 0; j < segmentCount; j++) ...[
              if (j > 0) const SizedBox(width: 5),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: j <= currentIndex
                        ? AppColors.primary
                        : Colors.transparent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnboardingContentCard extends StatelessWidget {
  const _OnboardingContentCard({
    required this.stepIndex,
    required this.stepCount,
    required this.slide,
  });

  final int stepIndex;
  final int stepCount;
  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rxxl,
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'الخطوة ${stepIndex + 1} من $stepCount',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SlideIcon(icon: slide.icon),
          const SizedBox(height: AppSpacing.xl),
          Text(
            slide.headline,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.62,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideIcon extends StatelessWidget {
  const _SlideIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lavender,
            AppColors.surfaceVariant,
          ],
        ),
        border: Border.all(
          color: AppColors.outlineSoft,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 40,
        color: AppColors.primary,
      ),
    );
  }
}

/// لمسة ثقة خفيفة — بلا وعود بنكية؛ تتماشى مع دور التطبيق كمساعد تنظيم.
class _TrustFootnote extends StatelessWidget {
  const _TrustFootnote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            LucideIcons.shieldCheck,
            size: 16,
            color: AppColors.primary.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'تنظيم مالي موثوق — بياناتك تبقى تحت سيطرتك',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
