/// أرقام عربية (هندية) ٠–٩ داخل واجهة عربية RTL
const _western = '0123456789';
const _eastern = '٠١٢٣٤٥٦٧٨٩';

String easternArabicDigits(String input) {
  final b = StringBuffer();
  for (final r in input.runes) {
    final ch = String.fromCharCode(r);
    final i = _western.indexOf(ch);
    b.write(i >= 0 ? _eastern[i] : ch);
  }
  return b.toString();
}

/// تنسيق مبلغ بخانة عشرية واحدة (أو أكثر) بأرقام عربية والفاصلة ٫
String formatArabicDecimalAmount(double value, int fractionDigits) {
  final s = value.abs().toStringAsFixed(fractionDigits);
  final parts = s.split('.');
  final intPart = easternArabicDigits(parts[0]);
  if (parts.length < 2) return intPart;
  final frac = easternArabicDigits(parts[1]);
  return '$intPart٫$frac';
}
