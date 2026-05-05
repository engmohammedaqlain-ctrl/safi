import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bootstrap/startup_ledger_data.dart';
import '../models/debt_category_model.dart';
import 'debts_ui_provider.dart';

/// تصنيفات الديون — محفوظة محليًا ومُزامَنة مع Firebase.
class DebtCategoriesNotifier extends Notifier<List<DebtCategory>> {
  @override
  List<DebtCategory> build() {
    return List<DebtCategory>.from(StartupLedgerData.debtCategories);
  }

  void _persist() {
    scheduleMicrotask(() => StartupLedgerData.saveDebtCategories(state));
  }

  void add(DebtCategory c) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final withTs = c.editedMs > 0 ? c : c.copyWith(editedMs: now);
    state = [...state, withTs];
    _persist();
  }

  void update(DebtCategory c) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final u = c.copyWith(editedMs: now);
    state = [
      for (final x in state)
        if (x.id == c.id) u else x,
    ];
    _persist();
  }

  void removeById(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    state = [
      for (final x in state)
        if (x.id == id)
          x.copyWith(
            isDeleted: true,
            deletedMs: now,
            editedMs: now,
          )
        else
          x,
    ];
    _persist();
  }
}

final debtCategoriesProvider =
    NotifierProvider<DebtCategoriesNotifier, List<DebtCategory>>(
  DebtCategoriesNotifier.new,
);

/// تصنيفات غير محذوفة للعرض والاختيار.
final activeDebtCategoriesProvider = Provider<List<DebtCategory>>((ref) {
  return [
    for (final c in ref.watch(debtCategoriesProvider)) if (!c.isDeleted) c,
  ];
});

/// عدد الزبائن المرتبطين بتصنيف (للعناوين الفرعية في إدارة التصنيفات)
final categoryCustomerCountProvider = Provider.family<int, String>((
  ref,
  categoryId,
) {
  final debtors = ref.watch(debtorsUiProvider);
  return debtors
      .where((d) => d.categoryIds.contains(categoryId))
      .length;
});
