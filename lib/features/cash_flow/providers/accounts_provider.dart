import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/financial_account_model.dart';

/// يدير قائمة الحسابات المالية (كاش، بنوك، محافظ)
class AccountsNotifier extends Notifier<List<FinancialAccount>> {
  @override
  List<FinancialAccount> build() {
    // بيانات افتراضية لأول مرة يدخل فيها المستخدم
    return const [
      FinancialAccount(
        id: '1',
        name: 'الدرج الرئيسي',
        type: AccountType.cash,
        balance: 1200,
      ),
      FinancialAccount(
        id: '2',
        name: 'حساب بنك فلسطين',
        type: AccountType.bank,
        balance: 4500,
        accountNumber: '12345678',
        accountOwner: 'المالك',
      ),
      FinancialAccount(
        id: '3',
        name: 'جوال بي',
        type: AccountType.wallet,
        balance: 300,
        accountNumber: '0599123456',
      ),
    ];
  }

  void addAccount(FinancialAccount acc) {
    state = [...state, acc];
  }

  void updateAccount(FinancialAccount acc) {
    state = [
      for (final a in state)
        if (a.id == acc.id) acc else a,
    ];
  }

  void deleteAccount(String id) {
    state = state.where((a) => a.id != id).toList();
  }
}

final accountsProvider =
    NotifierProvider<AccountsNotifier, List<FinancialAccount>>(
      AccountsNotifier.new,
    );
