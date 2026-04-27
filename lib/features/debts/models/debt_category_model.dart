import 'package:flutter/material.dart';

/// تصنيف لجهات الاتصال/الديون (مثل تطبيق كناش)
class DebtCategory {
  const DebtCategory({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  final String id;
  final String name;
  /// لون ARGB32 (مثل [Color.toARGB32])
  final int colorValue;

  Color get color => Color(colorValue);
}
