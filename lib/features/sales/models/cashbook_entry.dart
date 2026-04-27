/// حركة في دفتر النقدية (وارد / صادر)
class CashbookEntry {
  const CashbookEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
    this.note = '',
    this.accountId,
  });

  final String id;
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String note;
  final String? accountId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'isIncome': isIncome,
        'date': date.toIso8601String(),
        'note': note,
        'accountId': accountId,
      };

  factory CashbookEntry.fromJson(Map<String, dynamic> m) {
    return CashbookEntry(
      id: m['id'] as String,
      title: m['title'] as String? ?? '',
      amount: (m['amount'] as num).toDouble(),
      isIncome: m['isIncome'] as bool,
      date: DateTime.parse(m['date'] as String),
      note: m['note'] as String? ?? '',
      accountId: m['accountId'] as String?,
    );
  }
}
