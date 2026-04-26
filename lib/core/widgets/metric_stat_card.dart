import 'package:flutter/material.dart';

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
                Icon(data.icon, color: AppColors.primary, size: 20),
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
