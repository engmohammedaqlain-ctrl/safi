import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';

final pnlSpotsProvider = Provider<List<FlSpot>>(
  (ref) => const [
    FlSpot(0, 3),
    FlSpot(1, 4.2),
    FlSpot(2, 3.8),
    FlSpot(3, 5.1),
    FlSpot(4, 4.9),
    FlSpot(5, 6.2),
  ],
);

final salesBarsProvider = Provider<List<BarChartGroupData>>((ref) {
  const values = <double>[6, 7.2, 6.5, 8, 8.4, 9.1];
  return List.generate(
    6,
    (i) => BarChartGroupData(
      x: i,
      barRods: [
        BarChartRodData(
          toY: values[i],
          width: 16,
          color: AppColors.electricBlue.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    ),
  );
});
