import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/widgets.dart';

enum AccountType { cash, bank, wallet }

extension AccountTypeX on AccountType {
  IconData get icon {
    switch (this) {
      case AccountType.cash:
        return LucideIcons.banknote;
      case AccountType.bank:
        return LucideIcons.landmark;
      case AccountType.wallet:
        return LucideIcons.smartphone;
    }
  }

  String get label {
    switch (this) {
      case AccountType.cash:
        return 'كاش';
      case AccountType.bank:
        return 'بنك';
      case AccountType.wallet:
        return 'محفظة إلكترونية';
    }
  }
}

class FinancialAccount {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final String? accountNumber;
  final String? accountOwner;
  final int editedMs;
  final bool isDeleted;
  final int deletedMs;

  const FinancialAccount({
    required this.id,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.accountNumber,
    this.accountOwner,
    this.editedMs = 0,
    this.isDeleted = false,
    this.deletedMs = 0,
  });

  FinancialAccount copyWith({
    String? name,
    AccountType? type,
    double? balance,
    String? accountNumber,
    String? accountOwner,
    int? editedMs,
    bool? isDeleted,
    int? deletedMs,
  }) {
    return FinancialAccount(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      accountNumber: accountNumber ?? this.accountNumber,
      accountOwner: accountOwner ?? this.accountOwner,
      editedMs: editedMs ?? this.editedMs,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedMs: deletedMs ?? this.deletedMs,
    );
  }
}
