import 'package:flutter/material.dart';

/// تصنيف لجهات الاتصال/الديون (مثل تطبيق كناش)
class DebtCategory {
  const DebtCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    this.editedMs = 0,
    this.isDeleted = false,
    this.deletedMs = 0,
  });

  final String id;
  final String name;
  /// لون ARGB32 (مثل [Color.toARGB32])
  final int colorValue;

  final int editedMs;
  final bool isDeleted;
  final int deletedMs;

  Color get color => Color(colorValue);

  DebtCategory copyWith({
    String? name,
    int? colorValue,
    int? editedMs,
    bool? isDeleted,
    int? deletedMs,
  }) {
    return DebtCategory(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      editedMs: editedMs ?? this.editedMs,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedMs: deletedMs ?? this.deletedMs,
    );
  }
}
