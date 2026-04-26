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
    totalDebtLabel: '₪ 7,910',
    debtorCount: 3,
    overdueCount: 1,
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
    DebtUrgency.low => AppColors.neonGreen,
    DebtUrgency.medium => AppColors.warningAmber,
    DebtUrgency.high => AppColors.electricRed,
  };
}

final debtorsUiProvider = Provider<List<DebtorUi>>((ref) {
  return const [
    DebtorUi(
      id: 'd1',
      name: 'مؤيد السويطي',
      phone: '059 912 3456',
      amount: '1,350',
      status: 'متأخر منذ 4 أيام',
      urgency: DebtUrgency.high,
    ),
    DebtorUi(
      id: 'd2',
      name: 'رنا الشريف',
      phone: '052 000 1111',
      amount: '820',
      status: 'يستحق غداً',
      urgency: DebtUrgency.medium,
    ),
    DebtorUi(
      id: 'd3',
      name: 'أحمد سلمان',
      phone: '054 333 2222',
      amount: '460',
      status: 'بعد 5 أيام',
      urgency: DebtUrgency.low,
    ),
  ];
});
