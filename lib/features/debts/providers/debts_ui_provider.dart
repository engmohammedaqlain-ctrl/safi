import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';

enum DebtUrgency { low, medium, high }

class DebtorUi {
  const DebtorUi({
    required this.name,
    required this.amount,
    required this.status,
    required this.urgency,
  });

  final String name;
  final String amount;
  final String status;
  final DebtUrgency urgency;
}

Color urgencyToColor(DebtUrgency u) {
  return switch (u) {
    DebtUrgency.low => AppColors.neonGreen,
    DebtUrgency.medium => AppColors.warningAmber,
    DebtUrgency.high => AppColors.electricRed,
  };
}

final debtorsUiProvider = Provider<List<DebtorUi>>((ref) {
  return const [
    DebtorUi(
      name: 'مؤيد السويطي',
      amount: '1,350',
      status: 'متأخر منذ 4 أيام',
      urgency: DebtUrgency.high,
    ),
    DebtorUi(
      name: 'رنا الشريف',
      amount: '820',
      status: 'يستحق غداً',
      urgency: DebtUrgency.medium,
    ),
    DebtorUi(
      name: 'أحمد سلمان',
      amount: '460',
      status: 'بعد 5 أيام',
      urgency: DebtUrgency.low,
    ),
  ];
});
