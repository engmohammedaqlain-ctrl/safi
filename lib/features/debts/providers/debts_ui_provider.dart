import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bootstrap/startup_ledger_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../cash_flow/data/financial_account_model.dart';
import '../utils/customer_name_limits.dart';

enum DebtUrgency { low, medium, high }

enum TransactionType { gave, received }

/// وسم عربي لوسيلة الدفع: يطابق [FinancialAccount.id] أو القيم القديمة cash/wallet/bank
String transactionPayMethodLabel(
  String? methodId, {
  List<FinancialAccount> accounts = const [],
}) {
  if (methodId == null || methodId.isEmpty) return 'غير مُعرَّف';
  for (final a in accounts) {
    if (a.id == methodId) return a.name;
  }
  return switch (methodId) {
    'cash' => 'كاش',
    'wallet' => 'محفظة',
    'bank' => 'بنك فلسطين',
    _ => methodId,
  };
}

/// معاملة مالية (دين أو سداد)
class TransactionUi {
  const TransactionUi({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    required this.note,
    required this.date,
    this.payMethodId,
    this.imagePath,
    this.editedMs = 0,
    this.isDeleted = false,
    this.deletedMs = 0,
  });

  final String id;
  final String customerId;
  final double amount; // دائمًا موجب
  final TransactionType type; // gave = دين جديد, received = سداد
  final String note;
  final DateTime date;

  /// [FinancialAccount.id] أو قيمة قديمة: cash, wallet, bank
  final String? payMethodId;

  /// مسار صورة اختيارية
  final String? imagePath;

  final int editedMs;
  final bool isDeleted;
  final int deletedMs;
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
    this.categoryIds = const [],
    this.isSupplier = false,
    this.editedMs = 0,
    this.doubleLedger = false,
    this.dueDate,
    this.note,
    this.isDeleted = false,
    this.deletedMs = 0,
  });

  final String id;
  final String name;
  final String phone;
  final String amount; // الرصيد الصافي: موجب = الزبون مدين لك
  final String status;
  final DebtUrgency urgency;
  final String? address;
  final List<String> categoryIds;

  /// إذا كان بائع الجملة (true) بدلاً من الزبون (false)
  final bool isSupplier;

  /// أحدث وقت تعديل لتفضيل نسخة عند المزامنة
  final int editedMs;

  /// احتياطياً للتوافق مع JSON القديم — دائماً false (الميزة أُلغيت).
  final bool doubleLedger;

  /// موعد استحقاق الدين
  final DateTime? dueDate;

  /// ملاحظة شخصية عن الزبون/بائع الجملة (تُعرض تحت الاسم)
  final String? note;

  final bool isDeleted;
  final int deletedMs;
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

int _touchMs() => DateTime.now().millisecondsSinceEpoch;

// ── Debtors Notifier ──

class DebtorsUiNotifier extends Notifier<List<DebtorUi>> {
  @override
  List<DebtorUi> build() {
    return List<DebtorUi>.from(StartupLedgerData.debtors);
  }

  void _persist() {
    scheduleMicrotask(() => StartupLedgerData.saveDebtors(state));
  }

  void addCustomer(DebtorUi customer) {
    final c = customer.editedMs == 0
        ? DebtorUi(
            id: customer.id,
            name: customer.name,
            phone: customer.phone,
            address: customer.address,
            amount: customer.amount,
            status: customer.status,
            urgency: customer.urgency,
            categoryIds: customer.categoryIds,
            isSupplier: customer.isSupplier,
            editedMs: _touchMs(),
            doubleLedger: customer.doubleLedger,
            dueDate: customer.dueDate,
            note: customer.note,
          )
        : customer;
    state = [...state, c];
    _persist();
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
            categoryIds: d.categoryIds,
            isSupplier: d.isSupplier,
            editedMs: _touchMs(),
            doubleLedger: d.doubleLedger,
            dueDate: d.dueDate,
            note: d.note,
          )
        else
          d,
    ];
    _persist();
  }

  /// تحديث الاسم والجوال والعنوان معاً (محلي فقط — المزامنة عبر [StartupLedgerData.saveDebtors]).
  /// يعيد `null` عند النجاح، أو رسالة خطأ للمستخدم.
  String? updateCustomerCoreDetails({
    required String customerId,
    required String name,
    required String phoneRaw,
    required String addressRaw,
  }) {
    final phoneDigits = phoneRaw.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.isEmpty) {
      return 'الرجاء إدخال رقم الجوال';
    }
    if (phoneDigits.length < 7) {
      return 'رقم الجوال قصير جداً (على الأقل 7 أرقام)';
    }
    final formattedPhone = '+$phoneDigits';

    for (final other in state) {
      if (other.id == customerId || other.isDeleted) continue;
      final stored = other.phone.replaceAll(RegExp(r'\D'), '');
      if (other.phone == formattedPhone ||
          stored == phoneDigits ||
          other.phone.replaceAll('+', '') == phoneDigits) {
        return 'رقم الجوال مسجل لجهة أخرى';
      }
    }

    final nameTrimmed = sanitizeCustomerName(name);
    if (nameTrimmed.isEmpty) {
      return 'الرجاء إدخال الاسم';
    }

    final addrTrim = addressRaw.trim();
    final storedAddr = addrTrim.isEmpty ? null : addrTrim;

    state = [
      for (final d in state)
        if (d.id == customerId)
          DebtorUi(
            id: d.id,
            name: nameTrimmed,
            phone: formattedPhone,
            address: storedAddr,
            amount: d.amount,
            status: d.status,
            urgency: d.urgency,
            categoryIds: d.categoryIds,
            isSupplier: d.isSupplier,
            editedMs: _touchMs(),
            doubleLedger: d.doubleLedger,
            dueDate: d.dueDate,
            note: d.note,
          )
        else
          d,
    ];
    _persist();
    return null;
  }

  /// تحديث رصيد الزبون بمقدار delta
  /// delta موجب = دين جديد (الدين يزيد)، delta سالب = سداد (الدين يقل)
  /// إزالة مُعرّف تصنيف من كل الزبائن (عند حذف التصنيف)
  void stripCategoryFromAll(String categoryId) {
    state = [
      for (final d in state)
        DebtorUi(
          id: d.id,
          name: d.name,
          phone: d.phone,
          address: d.address,
          amount: d.amount,
          status: d.status,
          urgency: d.urgency,
          categoryIds: [
            for (final c in d.categoryIds)
              if (c != categoryId) c,
          ],
          isSupplier: d.isSupplier,
          editedMs: _touchMs(),
          doubleLedger: d.doubleLedger,
          dueDate: d.dueDate,
          note: d.note,
        ),
    ];
    _persist();
  }

  void updateCustomerDueDate(String customerId, DateTime? dueDate) {
    state = [
      for (final d in state)
        if (d.id == customerId)
          DebtorUi(
            id: d.id,
            name: d.name,
            phone: d.phone,
            address: d.address,
            amount: d.amount,
            status: d.status,
            urgency: d.urgency,
            categoryIds: d.categoryIds,
            isSupplier: d.isSupplier,
            editedMs: _touchMs(),
            doubleLedger: d.doubleLedger,
            dueDate: dueDate,
            note: d.note,
          )
        else
          d,
    ];
    _persist();
  }

  void updateCustomerNote(String customerId, String noteText) {
    final trimmed = noteText.trim();
    final stored = trimmed.isEmpty ? null : trimmed;
    state = [
      for (final d in state)
        if (d.id == customerId)
          DebtorUi(
            id: d.id,
            name: d.name,
            phone: d.phone,
            address: d.address,
            amount: d.amount,
            status: d.status,
            urgency: d.urgency,
            categoryIds: d.categoryIds,
            isSupplier: d.isSupplier,
            editedMs: _touchMs(),
            doubleLedger: d.doubleLedger,
            dueDate: d.dueDate,
            note: stored,
          )
        else
          d,
    ];
    _persist();
  }

  void removeCustomer(String id) {
    state = [
      for (final d in state)
        if (d.id == id)
          DebtorUi(
            id: d.id,
            name: d.name,
            phone: d.phone,
            address: d.address,
            amount: d.amount,
            status: d.status,
            urgency: d.urgency,
            categoryIds: d.categoryIds,
            isSupplier: d.isSupplier,
            editedMs: _touchMs(),
            doubleLedger: d.doubleLedger,
            dueDate: d.dueDate,
            note: d.note,
            isDeleted: true,
            deletedMs: _touchMs(),
          )
        else
          d,
    ];
    _persist();
  }

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
            categoryIds: d.categoryIds,
            isSupplier: d.isSupplier,
            editedMs: _touchMs(),
            doubleLedger: d.doubleLedger,
            dueDate: d.dueDate,
            note: d.note,
          )
        else
          d,
    ];
    _persist();
  }

  String _computeNewAmount(String currentAmount, double delta) {
    final current =
        double.tryParse(currentAmount.replaceAll('₪', '').trim()) ?? 0;
    final newAmount = current + delta;
    return newAmount.toStringAsFixed(1);
  }
}

final debtorsUiProvider = NotifierProvider<DebtorsUiNotifier, List<DebtorUi>>(
  DebtorsUiNotifier.new,
);

/// زبائن فقط (isSupplier = false)
final customersOnlyProvider = Provider<List<DebtorUi>>((ref) {
  return ref.watch(debtorsUiProvider).where((d) => !d.isSupplier && !d.isDeleted).toList();
});

/// بائعو جملة فقط (isSupplier = true)
final suppliersOnlyProvider = Provider<List<DebtorUi>>((ref) {
  return ref.watch(debtorsUiProvider).where((d) => d.isSupplier && !d.isDeleted).toList();
});

DebtMyNumbers _computeNumbers(List<DebtorUi> list) {
  double totalGave = 0;
  double totalReceived = 0;
  int overdueCount = 0;
  for (final d in list) {
    final amount = double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
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
    debtorCount: list.length,
    overdueCount: overdueCount,
  );
}

/// أرقام ملخصة للزبائن فقط
final customersNumbersProvider = Provider<DebtMyNumbers>((ref) {
  return _computeNumbers(ref.watch(customersOnlyProvider));
});

/// أرقام ملخصة لبائعي الجملة فقط
final suppliersNumbersProvider = Provider<DebtMyNumbers>((ref) {
  return _computeNumbers(ref.watch(suppliersOnlyProvider));
});

// ── Transactions Notifier ──

class TransactionsNotifier extends Notifier<List<TransactionUi>> {
  @override
  List<TransactionUi> build() {
    return List<TransactionUi>.from(StartupLedgerData.transactions);
  }

  void _persist() {
    scheduleMicrotask(() => StartupLedgerData.saveTransactions(state));
  }

  void addTransaction(TransactionUi tx) {
    final bumped = TransactionUi(
      id: tx.id,
      customerId: tx.customerId,
      amount: tx.amount,
      type: tx.type,
      note: tx.note,
      date: tx.date,
      payMethodId: tx.payMethodId,
      imagePath: tx.imagePath,
      editedMs: DateTime.now().millisecondsSinceEpoch,
    );
    state = [...state, bumped];
    _persist();
  }

  void removeTransactionById(String id) {
    state = [
      for (final t in state)
        if (t.id == id)
          TransactionUi(
            id: t.id,
            customerId: t.customerId,
            amount: t.amount,
            type: t.type,
            note: t.note,
            date: t.date,
            payMethodId: t.payMethodId,
            imagePath: t.imagePath,
            editedMs: DateTime.now().millisecondsSinceEpoch,
            isDeleted: true,
            deletedMs: DateTime.now().millisecondsSinceEpoch,
          )
        else
          t
    ];
    _persist();
  }
}

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<TransactionUi>>(
      TransactionsNotifier.new,
    );

/// معاملات زبون محدد — مرتبة من الأحدث للأقدم
final customerTransactionsProvider =
    Provider.family<List<TransactionUi>, String>((ref, customerId) {
      final all = ref.watch(transactionsProvider);
      final filtered = all.where((t) => t.customerId == customerId && !t.isDeleted).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return filtered;
    });

/// بيانات زبون حسب المعرّف — يتحدث تلقائيًا عند تغيّر الرصيد
final debtorByIdProvider = Provider.family<DebtorUi?, String>((ref, id) {
  final all = ref.watch(debtorsUiProvider);
  final matches = all.where((d) => d.id == id);
  return matches.isEmpty ? null : matches.first;
});

/// أرقام ملخصة عامة — كل الزبائن + بائعي الجملة معًا
final debtMyNumbersProvider = Provider<DebtMyNumbers>((ref) {
  return _computeNumbers(ref.watch(debtorsUiProvider));
});

/// تبويب شاشة دفتر الديون: 0 = الزبائن، 1 = بائعي الجملة (لإجراءات الشريط العلوي المشتركة).
class DebtsLedgerTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    if (index != state) state = index;
  }
}

final debtsLedgerTabProvider =
    NotifierProvider<DebtsLedgerTabNotifier, int>(DebtsLedgerTabNotifier.new);
