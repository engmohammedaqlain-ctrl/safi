import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/debt_category_model.dart';
import 'debts_ui_provider.dart';

class DebtCategoriesNotifier extends Notifier<List<DebtCategory>> {
  @override
  List<DebtCategory> build() => [];

  void add(DebtCategory c) {
    state = [...state, c];
  }

  void update(DebtCategory c) {
    state = [
      for (final x in state)
        if (x.id == c.id) c else x,
    ];
  }

  void removeById(String id) {
    state = [for (final x in state) if (x.id != id) x];
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
