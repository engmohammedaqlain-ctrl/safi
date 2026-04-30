/// حركة في الصافي (وارد / صادر)
class CashbookEntry {
  const CashbookEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
    this.note = '',
    this.accountId,
    this.category,
    this.imagePath,
    this.editedMs = 0,
    this.isDeleted = false,
    this.deletedMs = 0,
  });

  final String id;
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String note;
  final String? accountId;

  /// تصنيف اختياري (معاملات الصافي)
  final String? category;

  /// مسار محلي لصورة مرفقة
  final String? imagePath;

  /// أحدث وقت تعديل لتفضيل نسخة عند المزامنة
  final int editedMs;

  final bool isDeleted;
  final int deletedMs;

  CashbookEntry copyWith({
    String? id,
    String? title,
    double? amount,
    bool? isIncome,
    DateTime? date,
    String? note,
    String? accountId,
    String? category,
    String? imagePath,
    int? editedMs,
    bool? isDeleted,
    int? deletedMs,
  }) {
    return CashbookEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      isIncome: isIncome ?? this.isIncome,
      date: date ?? this.date,
      note: note ?? this.note,
      accountId: accountId ?? this.accountId,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      editedMs: editedMs ?? this.editedMs,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedMs: deletedMs ?? this.deletedMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'isIncome': isIncome,
        'date': date.toIso8601String(),
        'note': note,
        'accountId': accountId,
        'category': category,
        'imagePath': imagePath,
        'editedMs': editedMs,
        'isDeleted': isDeleted,
        'deletedMs': deletedMs,
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
      category: m['category'] as String?,
      imagePath: m['imagePath'] as String?,
      editedMs: (m['editedMs'] as num?)?.toInt() ?? 0,
      isDeleted: m['isDeleted'] as bool? ?? false,
      deletedMs: (m['deletedMs'] as num?)?.toInt() ?? 0,
    );
  }
}
