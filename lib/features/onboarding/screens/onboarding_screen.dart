import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/safi_button.dart';
import '../../../core/widgets/safi_brand_mark.dart';
import '../../../core/widgets/vault_branded_shell.dart';

/// تمثيل بصري مصغّر داخل بطاقة الأونبوردينغ للفكرة المعروضة.
enum _OnboardingMiniKind {
  /// محافظ + أرقام شبيهة بالتطبيق
  wallets,

  /// مستحقات / ديون بتلوين شبيه بالسجلات
  debts,

  /// صفوف عملاء + أرصدة
  customers,

  /// تذكير ورسالة شبيهة بإشعارات التطبيق
  reminders,
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.headline,
    required this.body,
    required this.icon,
    required this.gradientColors,
    required this.cardTag,
    required this.miniKind,
    this.cornerSafiBrand = false,
  });

  final String headline;
  final String body;
  final IconData icon;
  final List<Color> gradientColors;

  /// سطر مختصر على شكل «بطاقة بنكية»
  final String cardTag;

  final _OnboardingMiniKind miniKind;

  /// بدل أيقونة زاوية البطاقة — شارة «ص» كالهيدر الرئيسي.
  final bool cornerSafiBrand;
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _page.addListener(() => setState(() {}));
  }

  static final _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      headline: 'محافظك وأرصدتك في مكان واحد',
      body:
          'نظّم محافظك النقدية والبنكية، وتابع الوارد والصادر لصورة مالية موحّدة.',
      icon: LucideIcons.wallet,
      gradientColors: const [
        Color(0xFF9C27B0),
        Color(0xFF6A1B9A),
        Color(0xFF4A148C),
      ],
      cardTag: 'ملخص الأرصدة',
      miniKind: _OnboardingMiniKind.wallets,
      cornerSafiBrand: true,
    ),
    _OnboardingSlide(
      headline: 'الديون والمستحقات تحت السيطرة',
      body: 'سجّل ما لك وما عليك، وراقب المبالغ والمواعيد لتبقى صاف حسابك.',
      icon: LucideIcons.barChart2,
      gradientColors: const [
        Color(0xFF66BB6A),
        Color(0xFF388E3C),
        Color(0xFF1B5E20),
      ],
      cardTag: 'المستحقات',
      miniKind: _OnboardingMiniKind.debts,
    ),
    _OnboardingSlide(
      headline: 'زبائنك ومديونيتهم',
      body: 'أضف من تتعامل معهم، وتابع رصيد كل زبون وحركات السداد بتفاصيلها.',
      icon: LucideIcons.users,
      gradientColors: const [
        Color(0xFFB39DDB),
        Color(0xFF7E57C2),
        Color(0xFF4527A0),
      ],
      cardTag: 'سجل الزبائن',
      miniKind: _OnboardingMiniKind.customers,
    ),
    _OnboardingSlide(
      headline: 'تذكيرات ذكية للتجميع',
      body: 'فعّل رسائل التذكير لتقليل التأخير، وتسريع استرداد حقوقك المالية.',
      icon: LucideIcons.sparkles,
      gradientColors: const [
        Color(0xFFCE93D8),
        Color(0xFF8E24AA),
        Color(0xFF4A148C),
      ],
      cardTag: 'التجميع الذكي',
      miniKind: _OnboardingMiniKind.reminders,
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
      await ref.read(appSessionProvider.notifier).onWelcomeOnboardingComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewportPage = _page.hasClients
        ? _page.page ?? _i.toDouble()
        : _i.toDouble();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return VaultBrandedShell(
      belowBrand: Center(
        child: _PageDots(count: _slides.length, index: _i),
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
                            _OnboardingAnimatedCard(
                              slide: slide,
                              pagerDelta: viewportPage - index,
                              reduceMotion: reduceMotion,
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
              label: _i < _slides.length - 1 ? 'التالي' : 'ابدأ استخدام الصافي',
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
  const _PageDots({required this.count, required this.index});

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

/// طفو هادئ + ميل perspective مرتبط بسحب [PageView]؛ يُعطّل الطفو عند تقليل الحركة.
class _OnboardingAnimatedCard extends StatefulWidget {
  const _OnboardingAnimatedCard({
    required this.slide,
    required this.pagerDelta,
    required this.reduceMotion,
  });

  final _OnboardingSlide slide;
  final double pagerDelta;
  final bool reduceMotion;

  @override
  State<_OnboardingAnimatedCard> createState() =>
      _OnboardingAnimatedCardState();
}

class _OnboardingAnimatedCardState extends State<_OnboardingAnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (!widget.reduceMotion) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _OnboardingAnimatedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion != widget.reduceMotion) {
      if (widget.reduceMotion) {
        _float.stop();
      } else {
        _float.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.pagerDelta.clamp(-1.2, 1.2);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, _) {
          final bob = widget.reduceMotion
              ? 0.0
              : 5.5 * math.sin(_float.value * math.pi * 2);
          return Transform.translate(
            offset: Offset(0, bob),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.00115)
                ..rotateY(-d * 0.1),
              child: _BankPlasticCard(slide: widget.slide, layerShift: d * 16),
            ),
          );
        },
      ),
    );
  }
}

/// معاينة UI مصغّرة داخل البطاقة البنكية حسب موضوع الشريحة.
class _OnboardingMiniPreview extends StatelessWidget {
  const _OnboardingMiniPreview({required this.kind});

  final _OnboardingMiniKind kind;

  static final _caption = AppTextStyles.labelSmall.copyWith(
    color: Colors.white.withValues(alpha: 0.82),
    fontSize: 10,
    height: 1.2,
  );

  static final _value = AppTextStyles.labelSmall.copyWith(
    color: Colors.white,
    fontWeight: FontWeight.w700,
    fontSize: 11,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: switch (kind) {
          _OnboardingMiniKind.wallets => _wallets(),
          _OnboardingMiniKind.debts => _debts(),
          _OnboardingMiniKind.customers => _customers(),
          _OnboardingMiniKind.reminders => _reminders(),
        },
      ),
    );
  }

  Widget _wallets() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniPill(
                icon: LucideIcons.banknote,
                label: 'كاش',
                value: '١٫٢ ألف',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MiniPill(
                icon: LucideIcons.landmark,
                label: 'بنك',
                value: '٨٫٥ ألف',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MiniPill(
                icon: LucideIcons.smartphone,
                label: 'محفظة',
                value: '٢٫٠ ألف',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('الرصيد الموحّد', style: _caption),
            Text(' ١١٫٧ ألف ر.س', style: _value),
          ],
        ),
      ],
    );
  }

  Widget _debts() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MiniLedgerRow(
          dotColor: const Color(0xFFC8E6C9),
          label: 'لك',
          amount: '+ ٣٬٠٠٠',
          positive: true,
        ),
        const SizedBox(height: 5),
        _MiniLedgerRow(
          dotColor: const Color(0xFFFFCDD2),
          label: 'عليك',
          amount: '− ١٬٢٠٠',
          positive: false,
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: Container(
                  height: 4,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  height: 4,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _customers() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MiniCustomerRow(name: 'أحمد — محل الأقمشة', amount: '٨٥٠'),
        const SizedBox(height: 5),
        _MiniCustomerRow(name: 'بقالة النور', amount: '٢٫١ ألف'),
        const SizedBox(height: 4),
        Text(
          '+ ٣ زبائن في القائمة',
          textAlign: TextAlign.center,
          style: _caption.copyWith(fontSize: 9),
        ),
      ],
    );
  }

  Widget _reminders() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            LucideIcons.bellRing,
            color: Colors.white.withValues(alpha: 0.95),
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اليوم • ١٦:٠٠',
                style: _caption.copyWith(letterSpacing: 0.2),
              ),
              const SizedBox(height: 2),
              Text('استحقاق: أحمد م.', style: _value.copyWith(fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                'تذكير تلقائي قبل الموعد بساعة',
                style: _caption.copyWith(fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.88)),
          const SizedBox(height: 2),
          Text(
            label,
            style: _OnboardingMiniPreview._caption.copyWith(fontSize: 8.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: _OnboardingMiniPreview._value.copyWith(fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

class _MiniLedgerRow extends StatelessWidget {
  const _MiniLedgerRow({
    required this.dotColor,
    required this.label,
    required this.amount,
    required this.positive,
  });

  final Color dotColor;
  final String label;
  final String amount;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: _OnboardingMiniPreview._caption.copyWith(fontSize: 10.5),
          ),
        ),
        Text(
          amount,
          style: _OnboardingMiniPreview._value.copyWith(
            fontSize: 10.5,
            color: positive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          ),
        ),
      ],
    );
  }
}

class _MiniCustomerRow extends StatelessWidget {
  const _MiniCustomerRow({required this.name, required this.amount});

  final String name;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: Text(
            name.isNotEmpty ? String.fromCharCode(name.runes.first) : '؟',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _OnboardingMiniPreview._caption.copyWith(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ),
        Text(
          '$amount ر.س',
          style: _OnboardingMiniPreview._value.copyWith(fontSize: 10.5),
        ),
      ],
    );
  }
}

/// بطاقة بلاستيكية بتفاصيل تشبه بطاقة بنك (شريحة + شعار + تدرج)
class _BankPlasticCard extends StatelessWidget {
  const _BankPlasticCard({required this.slide, this.layerShift = 0});

  final _OnboardingSlide slide;

  /// إزاحة أفقية خفيفة للزخارف (parallax داخلي عند السحب).
  final double layerShift;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      height: 254,
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
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20 - layerShift * 0.35,
            top: -20,
            child: Icon(
              LucideIcons.circle,
              size: 140,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(layerShift * 0.55, 0),
              child: Column(
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
                          'الصافي',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _OnboardingMiniPreview(kind: slide.miniKind)),
                  const SizedBox(height: 8),
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
                            const SizedBox(height: 4),
                            Text(
                              '••••  ••••  ••••  8821',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: Colors.white,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(-layerShift * 0.2, 0),
                        child: slide.cornerSafiBrand
                            ? Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: const SafiBrandMark(size: 28),
                              )
                            : Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  slide.icon,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
