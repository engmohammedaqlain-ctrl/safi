/// تحويل رقم المستخدم إلى [E.164](https://en.wikipedia.org/wiki/E.164).
/// يدمج افتراضيًا بادئة **المملكة العربية السعودية (+966)** عند الإدخال المحلي فقط (يبدأ بـ `5`).
String phoneDigitsToE164(String raw) {
  final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), '');
  var digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');

  if (trimmed.startsWith('+')) {
    final afterPlus = trimmed.substring(1).replaceAll(RegExp(r'\D'), '');
    if (afterPlus.length < 8) {
      throw const FormatException('too_short');
    }
    return '+$afterPlus';
  }

  if (digitsOnly.startsWith('966') && digitsOnly.length >= 11) {
    return '+$digitsOnly';
  }

  if (digitsOnly.length == 12 && digitsOnly.startsWith('966')) {
    return '+$digitsOnly';
  }

  if (digitsOnly.length == 10 && digitsOnly.startsWith('05')) {
    return '+966${digitsOnly.substring(1)}';
  }

  if (digitsOnly.length == 10 && digitsOnly.startsWith('5')) {
    return '+966$digitsOnly';
  }

  if (digitsOnly.length == 9 && digitsOnly.startsWith('5')) {
    return '+966$digitsOnly';
  }

  if (digitsOnly.length >= 10) {
    return '+$digitsOnly';
  }

  throw const FormatException('unsupported');
}
