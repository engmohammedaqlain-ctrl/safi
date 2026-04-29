import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';

/// شارة هوية صافي — محفظة على تدرج (واضحة بأي حجم، بخلاف حرف عربي صغير).
class SafiBrandMark extends StatelessWidget {
  const SafiBrandMark({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = (size * 0.25).clamp(4.0, 10.0);
    final iconSize = size * 0.52;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        LucideIcons.wallet,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}
