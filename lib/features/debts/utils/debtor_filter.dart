import '../providers/debts_ui_provider.dart';

/// بحث بسيط بالاسم أو أرقام الهاتف (للعرض المحلي)
List<DebtorUi> filterDebtors(List<DebtorUi> all, String query) {
  final t = query.trim().toLowerCase();
  if (t.isEmpty) return all;
  final digits = t.replaceAll(RegExp(r'\D'), '');
  return all.where((d) {
    final nameMatch = d.name.toLowerCase().contains(t);
    final phoneFlat = d.phone.replaceAll(RegExp(r'\D'), '');
    final phoneMatch = digits.isNotEmpty && phoneFlat.contains(digits);
    return nameMatch || phoneMatch;
  }).toList();
}
