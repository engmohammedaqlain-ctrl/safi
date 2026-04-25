import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum SafiButtonVariant { primary, secondary, outline, ai }

class SafiButton extends StatelessWidget {
  const SafiButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = SafiButtonVariant.primary,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SafiButtonVariant variant;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final isAi = variant == SafiButtonVariant.ai;
    final gradient = isAi
        ? AppColors.aiGradient
        : (variant == SafiButtonVariant.primary
            ? AppColors.primaryGradient
            : null);

    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.rlg,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            color: variant == SafiButtonVariant.secondary
                ? AppColors.backgroundSecondary
                : (variant == SafiButtonVariant.outline
                    ? Colors.transparent
                    : null),
            borderRadius: AppRadius.rlg,
            border: variant == SafiButtonVariant.outline
                ? Border.all(
                    color: AppColors.glassBorder.withValues(alpha: 0.5),
                  )
                : null,
            boxShadow: isAi
                ? [
                    BoxShadow(
                      color: AppColors.aiPurple.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : (variant == SafiButtonVariant.primary
                    ? [
                        BoxShadow(
                          color: AppColors.electricBlue.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 10,
            ),
            child: Row(
              mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: isAi || variant == SafiButtonVariant.primary
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: (variant == SafiButtonVariant.primary ||
                              variant == SafiButtonVariant.ai)
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }
}

class SafiIconButton extends StatelessWidget {
  const SafiIconButton({
    super.key,
    required this.onPressed,
    this.icon = LucideIcons.scanLine,
  });

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.rmd,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: AppRadius.rmd,
            border: Border.all(
              color: AppColors.glassBorder.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(icon, color: AppColors.electricBlue, size: 22),
        ),
      ),
    );
  }
}
