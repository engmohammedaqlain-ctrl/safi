import 'dart:convert';

/// دمج JSON قوائم الحافظة بدون فقدان عناصر جُدِدت على جهازين:
/// الاتحاد حسب [id]، وعند التعارض تُفضَّل النسخة ذات [editedMs] الأكبر.
class LedgerJsonMerge {
  LedgerJsonMerge._();

  static String mergeDebtors(String remote, String local) =>
      _mergeArrayJson(remote, local, 'id');

  static String mergeTransactions(String remote, String local) =>
      _mergeArrayJson(remote, local, 'id');

  static String mergeCashbook(String remote, String local) =>
      _mergeArrayJson(remote, local, 'id');

  /// حسابات مالية وحسّابات جانباً — بنفس آلية الدمج.
  static String mergeAccounts(String remote, String local) =>
      _mergeArrayJson(remote, local, 'id');

  /// تصنيفات الديون
  static String mergeDebtCategories(String remote, String local) =>
      _mergeArrayJson(remote, local, 'id');

  /// اتحاد حسب المعرف؛ العنصر الأحدث بحسب [editedMs] يبقى. الحذف عبر طرف واحد لا يُزامن لجهاز آخر دون عمود حذف منفصل.
  static String _mergeArrayJson(
    String remote,
    String local,
    String idKey,
  ) {
    final rList = _decodeList(remote);
    final lList = _decodeList(local);
    final byId = <String, Map<String, dynamic>>{};

    void putAll(List<dynamic> list) {
      for (final e in list) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final id = m[idKey]?.toString();
        if (id == null || id.isEmpty) continue;
        final prev = byId[id];
        if (prev == null) {
          byId[id] = m;
        } else {
          byId[id] = _pickNewerMap(prev, m);
        }
      }
    }

    putAll(rList);
    putAll(lList);
    return jsonEncode(byId.values.toList());
  }

  static List<dynamic> _decodeList(String raw) {
    if (raw.isEmpty) return [];
    try {
      final x = jsonDecode(raw);
      if (x is List<dynamic>) return x;
    } catch (_) {}
    return [];
  }

  static Map<String, dynamic> _pickNewerMap(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final ae = (a['editedMs'] as num?)?.toInt() ?? 0;
    final be = (b['editedMs'] as num?)?.toInt() ?? 0;
    if (ae == be) return b;
    return ae > be ? a : b;
  }
}
