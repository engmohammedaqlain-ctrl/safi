import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/safi_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _i = 0;

  static const _steps = [
    'أضف أول منتج (باركود أو يدوي)',
    'سجّل أول بيعة',
    'أضف زبون مدين',
    'جرّب رسالة تحصيل ذكية',
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_i < 3) {
      await _page.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      await ref.read(appSessionProvider.notifier).onOnboardingComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعداد الأولي'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (j) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: j == _i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: j <= _i ? AppColors.primary : AppColors.outline,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _page,
              onPageChanged: (v) => setState(() => _i = v),
              itemCount: 4,
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        Icon(
                          LucideIcons.rocket,
                          size: 64,
                          color: AppColors.primary.withValues(alpha: 0.85),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'خطوة ${index + 1} من 4',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _steps[index],
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SafiButton(
              label: _i < 3 ? 'التالي' : 'بدء استخدام صافي',
              onPressed: _next,
            ),
          ),
        ],
      ),
    );
  }
}
