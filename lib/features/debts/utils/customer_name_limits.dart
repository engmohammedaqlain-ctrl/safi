/// أسماء جهات الاتصال قد تكون نصوصاً طويلة جداً (ملاحظات، حقول مكررة).
/// نحدّ الطول لتخفيف التخطيط، التخزين، والمزامنة.
const int kMaxCustomerNameLength = 120;

String sanitizeCustomerName(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  var s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (s.length > kMaxCustomerNameLength) {
    s = s.substring(0, kMaxCustomerNameLength).trimRight();
  }
  return s;
}
