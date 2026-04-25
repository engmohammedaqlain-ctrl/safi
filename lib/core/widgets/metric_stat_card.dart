import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'glass_card.dart';

class MetricStatData {
  const MetricStatData({
    required this.title,
    required this.value,
    required this.delta,
    required this.deltaColor,
    required this.icon,
  });

  final String title;
  final String value;
  final String delta;
  final Color deltaColor;
  final IconData icon;
}

class MetricStatCard extends StatelessWidget {
  const MetricStatCard({
    super.key,
    required this.data,
  });

  final MetricStatData data;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(data.icon, color: AppColors.electricBlue, size: 20),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: data.deltaColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: data.deltaColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    data.delta,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: data.deltaColor,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              data.title,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              data.value,
              style: AppTextStyles.numberLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر عريض لمسح الباركود
class BarcodeCtaButton extends StatelessWidget {
  const BarcodeCtaButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.electricBlue.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.scanLine,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'مسح الباركود',
                  style: AppTextStyles.titleSmall.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
