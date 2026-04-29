import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// خلفية جسم الصفحة كما في [UnifiedReportsScreen] (فاتحة تحت الرأس الداكن).
class ReportsStyleSurfaces {
  ReportsStyleSurfaces._();

  static const Color bodyBackdrop = Color(0xFFF2F4F8);

  /// بطاقة بيضاء بنفس ظل/حدود التقارير.
  static BoxDecoration whiteCardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

/// رأس متدرّج كشاشة «التقارير والتصدير».
class ReportsStyleHeaderBand extends StatelessWidget {
  const ReportsStyleHeaderBand({
    super.key,
    required this.topPadding,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.trailing,
    this.filterBadgeLabel,
  });

  final double topPadding;
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget? trailing;
  final String? filterBadgeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF1A0A24),
            AppColors.primaryDark,
            AppColors.primary.withValues(alpha: 0.92),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          topPadding + 6,
          AppSpacing.lg,
          22,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                BackButton(color: Colors.white, onPressed: onBack),
                const Spacer(),
                if (trailing case final Widget t) t,
              ],
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 23,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            if ((filterBadgeLabel ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.shield,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      filterBadgeLabel ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// صفحة كاملة: رأس تقارير + جسم بلون الخلفية الفاتحة (للمسارات من «المزيد»).
class ReportsStylePage extends StatelessWidget {
  const ReportsStylePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.headerTrailing,
    this.filterBadgeLabel,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? headerTrailing;
  final String? filterBadgeLabel;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: ReportsStyleSurfaces.bodyBackdrop,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReportsStyleHeaderBand(
                topPadding: topPad,
                title: title,
                subtitle: subtitle,
                onBack: onBack ?? () => Navigator.maybePop(context),
                trailing: headerTrailing,
                filterBadgeLabel: filterBadgeLabel,
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
