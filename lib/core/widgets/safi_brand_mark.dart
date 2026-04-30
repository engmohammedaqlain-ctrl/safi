import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// شارة هوية صافي — حرف «ص» على تدرج.
class SafiBrandMark extends StatelessWidget {
  const SafiBrandMark({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = (size * 0.25).clamp(4.0, 10.0);
    final fontSize = size * 0.56;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        'ص',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.family,
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
    );
  }
}
