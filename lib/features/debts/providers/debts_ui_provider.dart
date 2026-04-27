import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';

enum DebtUrgency { low, medium, high }

enum TransactionType { gave, received }

/// معاملة مالية (دين أو دفعة)
class TransactionUi {
  const TransactionUi({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    required this.note,
    required this.date,
  });

  final String id;
  final String customerId;
  final double amount; // دائمًا موجب
  final TransactionType type; // gave = أعطيت, received = أخذت
  final String note;
  final DateTime date;
}

/// أرقام ملخصة لرأس شاشة الديون
class DebtMyNumbers {
  const DebtMyNumbers({
    required this.totalGaveLabel,
    required this.totalReceivedLabel,
    required this.debtorCount,
    required this.overdueCount,
  });

  final String totalGaveLabel;
  final String totalReceivedLabel;
  final int debtorCount;
  final int overdueCount;
}

class DebtorUi {
  const DebtorUi({
    required this.id,
    required this.name,
    required this.phone,
    required this.amount,
    required this.status,
    required this.urgency,
    this.address,
  });

  final String id;
  final String name;
  final String phone;
  final String amount; // الرصيد الصافي: موجب = العميل مدين لك
  final String status;
  final DebtUrgency urgency;
  final String? address;
}

Color urgencyToColor(DebtUrgency u) {
  return switch (u) {
    DebtUrgency.low => AppColors.flowIn,
    DebtUrgency.medium => AppColors.warning,
    DebtUrgency.high => AppColors.flowOut,
  };
}

DebtUrgency _urgencyFromAmount(double amount) {
  final abs = amount.abs();
  if (abs <= 0) return DebtUrgency.low;
  if (abs < 500) return DebtUrgency.medium;
  return DebtUrgency.high;
}

String _formatDateStatus(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays == 0) return 'اليوم';
  if (diff.inDays == 1) return 'أمس';
  return '${date.day}/${date.month}/${date.year}';
}

// ── Debtors Notifier ──

class DebtorsUiNotifier extends Notifier<List<DebtorUi>> {
  @override
  List<DebtorUi> build() => [];

  void addCustomer(DebtorUi customer) {
    state = [...state, customer];
  }

  void updateCustomerAddress(String customerId, String address) {
    state = [
      for (final d in state)
        if (d.id == customerId)
          DebtorUi(
            id: d.id,
            name: d.name,
            phone: d.phone,
            address: address,
            amount: d.amount,
            status: d.status,
            urgency: d.urgency,
          )
        else
          d,
    ];
  }

  /// تحديث رصيد العميل بمقدار delta
  /// delta موجب = أعطيت (الدين يزيد)، delta سالب = أخذت (الدين يقل)
  void updateCustomerBalance(String customerId, double delta) {
    state = [
      for (final d in state)
        if (d.id == customerId)
          DebtorUi(
            id: d.id,
            name: d.name,
            phone: d.phone,
            address: d.address,
            amount: _computeNewAmount(d.amount, delta),
            status: _formatDateStatus(DateTime.now()),
            urgency: _urgencyFromAmount(
              (double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0) +
                  delta,
            ),
          )
        else
          d,
    ];
  }

  String _computeNewAmount(String currentAmount, double delta) {
    final current =
        double.tryParse(currentAmount.replaceAll('₪', '').trim()) ?? 0;
    final newAmount = current + delta;
    return newAmount.toStringAsFixed(1);
  }
}

final debtorsUiProvider =
    NotifierProvider<DebtorsUiNotifier, List<DebtorUi>>(DebtorsUiNotifier.new);

// ── Transactions Notifier ──

class TransactionsNotifier extends Notifier<List<TransactionUi>> {
  @override
  List<TransactionUi> build() => [];

  void addTransaction(TransactionUi tx) {
    state = [...state, tx];
  }
}

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<TransactionUi>>(
  TransactionsNotifier.new,
);

/// معاملات عميل محدد — مرتبة من الأحدث للأقدم
final customerTransactionsProvider =
    Provider.family<List<TransactionUi>, String>((ref, customerId) {
  final all = ref.watch(transactionsProvider);
  final filtered = all.where((t) => t.customerId == customerId).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return filtered;
});

/// بيانات عميل حسب المعرّف — يتحدث تلقائيًا عند تغيّر الرصيد
final debtorByIdProvider = Provider.family<DebtorUi?, String>((ref, id) {
  final all = ref.watch(debtorsUiProvider);
  final matches = all.where((d) => d.id == id);
  return matches.isEmpty ? null : matches.first;
});

/// أرقام ملخصة — محسوبة من البيانات الفعلية
final debtMyNumbersProvider = Provider<DebtMyNumbers>((ref) {
  final debtors = ref.watch(debtorsUiProvider);

  double totalGave = 0;
  double totalReceived = 0;
  int overdueCount = 0;

  for (final d in debtors) {
    final amount =
        double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
    if (amount > 0) {
      totalGave += amount;
    } else if (amount < 0) {
      totalReceived += amount.abs();
    }
    if (d.urgency == DebtUrgency.high) {
      overdueCount++;
    }
  }

  return DebtMyNumbers(
    totalGaveLabel: '₪ ${totalGave.toStringAsFixed(1)}',
    totalReceivedLabel: '₪ ${totalReceived.toStringAsFixed(1)}',
    debtorCount: debtors.length,
    overdueCount: overdueCount,
  );
});
