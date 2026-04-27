import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';

enum DebtUrgency { low, medium, high }

/// أرقام ملخصة لرأس شاشة الديون (أرقامي)
class DebtMyNumbers {
  const DebtMyNumbers({
    required this.totalDebtLabel,
    required this.debtorCount,
    required this.overdueCount,
  });

  final String totalDebtLabel;
  final int debtorCount;
  final int overdueCount;
}

final debtMyNumbersProvider = Provider<DebtMyNumbers>(
  (ref) => const DebtMyNumbers(
    totalDebtLabel: '₪ 0',
    debtorCount: 0,
    overdueCount: 0,
  ),
);

class DebtorUi {
  const DebtorUi({
    required this.id,
    required this.name,
    required this.phone,
    required this.amount,
    required this.status,
    required this.urgency,
  });

  final String id;
  final String name;
  final String phone;
  final String amount;
  final String status;
  final DebtUrgency urgency;
}

Color urgencyToColor(DebtUrgency u) {
  return switch (u) {
    DebtUrgency.low => AppColors.flowIn,
    DebtUrgency.medium => AppColors.warning,
    DebtUrgency.high => AppColors.flowOut,
  };
}

final debtorsUiProvider = Provider<List<DebtorUi>>((ref) {
  return const [];
});
