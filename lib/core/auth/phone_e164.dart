/// تحويل رقم المستخدم إلى [E.164](https://en.wikipedia.org/wiki/E.164).
/// يدعم أرقام فلسطين (+970) والداخل (+972).
String phoneDigitsToE164(String raw) {
  final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), '');
  var digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');

  // إذا بدأ بـ + نعتبره رقم دولي جاهز
  if (trimmed.startsWith('+')) {
    final afterPlus = trimmed.substring(1).replaceAll(RegExp(r'\D'), '');
    if (afterPlus.length < 8) {
      throw const FormatException('too_short');
    }
    return '+$afterPlus';
  }

  // إذا بدأ بـ 05 (طول 10 أرقام)
  if (digitsOnly.length == 10 && digitsOnly.startsWith('05')) {
    final prefix = digitsOnly.substring(0, 3); // 05x
    if (prefix == '059' || prefix == '056') {
      return '+970${digitsOnly.substring(1)}';
    } else {
      return '+972${digitsOnly.substring(1)}';
    }
  }

  // إذا بدأ بـ 5 بدون 0 (طول 9 أرقام)
  if (digitsOnly.length == 9 && digitsOnly.startsWith('5')) {
    final firstTwo = digitsOnly.substring(0, 2); // 5x
    if (firstTwo == '59' || firstTwo == '56') {
      return '+970$digitsOnly';
    } else {
      return '+972$digitsOnly';
    }
  }

  // إذا بدأ بالمقدمة الدولية مباشرة بدون +
  if (digitsOnly.startsWith('970') && digitsOnly.length >= 12) {
    return '+$digitsOnly';
  }
  if (digitsOnly.startsWith('972') && digitsOnly.length >= 12) {
    return '+$digitsOnly';
  }

  // دعم أرقام أخرى كاحتياط
  if (digitsOnly.length >= 9) {
    return '+$digitsOnly';
  }

  throw const FormatException('unsupported');
}

