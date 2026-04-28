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
    state = [...state, c];
    _persist();
  }

  void update(DebtCategory c) {
    state = [
      for (final x in state)
        if (x.id == c.id) c else x,
    ];
    _persist();
  }

  void removeById(String id) {
    state = [for (final x in state) if (x.id != id) x];
    _persist();
  }
}

final debtCategoriesProvider =
    NotifierProvider<DebtCategoriesNotifier, List<DebtCategory>>(
  DebtCategoriesNotifier.new,
);

/// عدد العملاء المرتبطين بتصنيف (للعناوين الفرعية في إدارة التصنيفات)
final categoryCustomerCountProvider = Provider.family<int, String>((
  ref,
  categoryId,
) {
  final debtors = ref.watch(debtorsUiProvider);
  return debtors
      .where((d) => d.categoryIds.contains(categoryId))
      .length;
});
