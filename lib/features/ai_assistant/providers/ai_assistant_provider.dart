import 'dart:convert';
import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../debts/providers/debts_ui_provider.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../../cash_flow/data/financial_account_model.dart';
import '../../cash_flow/providers/accounts_provider.dart';
import '../../cash_flow/providers/include_debts_in_wallet_balance_provider.dart';
import '../../cash_flow/utils/wallet_balance_math.dart';
import '../../../core/bootstrap/prefs_keys.dart';
import '../../../core/bootstrap/startup_ledger_data.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      text: map['text'] as String,
      isUser: map['isUser'] as bool,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}

class AiAssistantState {
  final List<ChatMessage> history;
  final bool isTyping;

  AiAssistantState({this.history = const [], this.isTyping = false});

  AiAssistantState copyWith({List<ChatMessage>? history, bool? isTyping}) {
    return AiAssistantState(
      history: history ?? this.history,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class AiAssistantNotifier extends Notifier<AiAssistantState> {
  /// مفتاح DeepSeek API (مضمّن في التطبيق — لا يُقرأ من .env).
  static const String _deepseekApiKey = 'sk-6e98977c40bc44b58e9cc425f01d845f';

  @override
  AiAssistantState build() {
    _loadHistory();
    return AiAssistantState();
  }

  Future<void> _loadHistory() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(PrefsKeys.aiChatHistory);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        final history = list
            .map((e) => ChatMessage.fromMap(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(history: history);
      }
    } catch (_) {}
  }

  Future<void> _saveAndSyncHistory(List<ChatMessage> history) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        PrefsKeys.aiChatHistory,
        jsonEncode(history.map((e) => e.toMap()).toList()),
      );

      // Sync to Firebase if online/logged in (offline resilience is via SharedPreferences)
      final ownerUid =
          p.getString(PrefsKeys.ledgerOwnerUid) ??
          FirebaseAuth.instance.currentUser?.uid;
      if (ownerUid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerUid)
            .collection('ai_history')
            .doc('main_chat')
            .set({
              'messages': history.map((e) => e.toMap()).toList(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  void clearHistory() {
    state = state.copyWith(history: []);
    _saveAndSyncHistory([]);
  }

  Future<String> generateWhatsAppMessage(
    DebtorUi debtor,
    String customPrompt,
  ) async {
    try {
      final userName = StartupLedgerData.bootstrapUserName ?? 'صاحب المتجر';
      final systemPrompt =
          '''
أنت خبير مالي معتمد؛ صِغْ نصاً واحداً جاهزاً للإرسال عبر واتساب بلغة عربية فصحى مرتبة، رسمية، وهادئة، مع أسلوب مهني كما يجري في المراسلات المالية في فلسطين.
سياق التطبيق: «الصافي». المستخدم ($userName). المقصود: الزبون (${debtor.name})؛ قيمة المطلوب تذكيره بها: (${debtor.amount} شيكل).
موعد السداد: ${debtor.dueDate != null ? '${debtor.dueDate!.year}/${debtor.dueDate!.month}/${debtor.dueDate!.day}' : 'غير محدد'}.
التعليمات الإضافية من المستخدم: "$customPrompt"
المخرجات: فقرة أو فقرتان قصيرتان فقط؛ دون عنوان أو توقيع افتراضي منك؛ دون مبالغة أو عامية؛ بلهجة مهنية ومهذبة.
الالتزامات الإلزامية: لا تستخدم أي إيموجي أو رموزاً تعبيرية (Emoji) ولا رموزاً زخرفية؛ النص حروف عربية وعلامات ترقيم عادية فقط.
''';

      final res = await http.post(
        Uri.parse('https://api.deepseek.com/chat/completions'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_deepseekApiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': 'اكتب الرسالة الآن.'},
          ],
          'temperature': 0.45,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final raw =
            data['choices'][0]['message']['content']?.trim() ??
            'عذراً، حدث خطأ.';
        return _stripEmojiAndDecorativeSymbols(raw);
      } else {
        return 'عذراً، حدث خطأ في الاتصال.';
      }
    } catch (e) {
      return 'عذراً، حدث خطأ: $e';
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedHistory = [...state.history, userMsg];
    state = state.copyWith(history: updatedHistory, isTyping: true);

    try {
      final contextStr = _buildContext();

      final systemPrompt =
          '''
$contextStr

أنت خبير مالي معتمد تتحدث بالعربية الفصحى الموجزة بأسلوب رسمي ومهني دائماً، مع فهم عملي للتجارة والتزامات الديون كما يمارَس في فلسطين.
وضعك «محادثة وتحليل فقط»: لا تستطيع تنفيذ أي إجراء داخل التطبيق (لا إضافة ولا تعديل ولا حذف). إن طُلب منك ذلك فاشرح بلطف أن الدور يقتصر على الإرشاد وفق البيانات أعلاه، ووجّه المستخدم لإدخال البيانات من شاشات التطبيق.
لا تخلط بين «اسم صاحب المتجر» أعلاه وبين أسماء الزبائن/بائعي الجملة؛ الصفوف في قسم «تفصيل كل زبون وبائع جملة» هي وحدها سجلات الدفتر.
انسخ أسماء الزبائن وبائعي الجملة **حرفياً** كما في السياق؛ إن وُجد نص «بدون اسم» أو معرّف فأظهره كما هو ولا تستبدله بعناوين عامة مثل «عميل 1».
قسم «المحافظ المالية» يضم الأرصدة الابتدائية والرصيد الفعلي لكل محفظة — استخدمه للإجابة عن الصندوق والصافي.
عند الطلب استند بالكامل إلى التفاصيل المذكورة في السياق (أسماء، أرصدة، معاملات، صندوق، محافظ) ولا تكتفي بملخص رقمي عام إن كان المستخدم يطلب التفصيل.
قدّم إجابة واضحة ومنظّمة (فقرات قصيرة أو نقاط مرقّمة عند الحاجة). تجنّب العامية والتهريج والعبارات الترويجية أو الخفيفة.
لا تخترع أرقاماً أو أسماء غير واردة في السياق أعلاه.
إلزامي: لا تستخدم أي إيموجي أو رموزاً تعبيرية (Emoji أو رموز يونيكود الزخرفية) ولا رموزاً بديلة مثل ":)" أو "؛)"؛ اكتفِ بالحروف العربية وعلامات الترقيم المعتادة.
''';

      final recentHistory = updatedHistory
          .skip(updatedHistory.length > 20 ? updatedHistory.length - 20 : 0)
          .toList();

      final messages = [
        {'role': 'system', 'content': systemPrompt},
        ...recentHistory.map(
          (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
        ),
      ];

      final res = await http.post(
        Uri.parse('https://api.deepseek.com/chat/completions'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_deepseekApiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': messages,
          'temperature': 0.45,
        }),
      );

      String reply = 'عذراً، تعذّر تقديم إجابة في الوقت الحالي.';
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final message = data['choices'][0]['message'];
        final raw = message['content'];
        reply = (raw is String ? raw : raw?.toString()) ?? reply;
      } else {
        throw Exception('DeepSeek Error: ${res.body}');
      }

      final aiMsg = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: _stripEmojiAndDecorativeSymbols(reply),
        isUser: false,
        timestamp: DateTime.now(),
      );

      final finalHistory = [...updatedHistory, aiMsg];
      state = state.copyWith(history: finalHistory, isTyping: false);
      _saveAndSyncHistory(finalHistory);
    } catch (e, st) {
      debugPrint('AI API Error: $e\n$st');
      final errorMsg = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: 'راجع مفتاح API أو الاتصال. خطأ: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      final finalHistory = [...updatedHistory, errorMsg];
      state = state.copyWith(history: finalHistory, isTyping: false);
    }
  }

  /// إزالة الإيموجي والرموز التعبيرية من مخرجات النموذج عند الحاجة.
  String _stripEmojiAndDecorativeSymbols(String input) {
    final out = StringBuffer();
    for (final g in input.characters) {
      if (_graphemeIsEmojiLike(g)) continue;
      out.write(g);
    }
    return out.toString().replaceAll(RegExp(r' {2,}'), ' ').trim();
  }

  bool _graphemeIsEmojiLike(String g) {
    for (final r in g.runes) {
      if (r >= 0x1F300 && r <= 0x1FAFF) return true;
      if (r >= 0x2600 && r <= 0x26FF) return true;
      if (r >= 0x2700 && r <= 0x27BF) return true;
      if (r >= 0xFE00 && r <= 0xFE0F) return true;
      if (r >= 0x1F600 && r <= 0x1F64F) return true;
      if (r >= 0x1F680 && r <= 0x1F6FF) return true;
      if (r >= 0x1F1E6 && r <= 0x1F1FF) return true;
    }
    return false;
  }

  String _ymd(DateTime d) => '${d.year}/${d.month}/${d.day}';

  String _buildContext() {
    final userName = (StartupLedgerData.bootstrapUserName ?? '').trim().isEmpty
        ? '(غير محدد في الإعدادات)'
        : StartupLedgerData.bootstrapUserName!.trim();

    final debtors = ref
        .read(debtorsUiProvider)
        .where((d) => !d.isDeleted)
        .toList();

    String debtorLabel(DebtorUi d) {
      final n = d.name.trim();
      if (n.isEmpty) return 'بدون اسم (معرّف ${d.id})';
      return n;
    }

    final idToName = {for (final d in debtors) d.id: debtorLabel(d)};

    final txs =
        ref.read(transactionsProvider).where((t) => !t.isDeleted).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final cash = List.of(ref.read(activeCashbookEntriesProvider))
      ..sort((a, b) => b.date.compareTo(a.date));

    final cbSum = ref.read(cashbookSummaryProvider);

    final accounts = ref.read(activeAccountsProvider);
    final allEntries = ref.read(cashbookEntriesProvider);
    final allTx = ref.read(transactionsProvider);
    final includeDebts = ref.read(includeDebtsInWalletBalanceProvider);

    final accLines = StringBuffer();
    if (accounts.isEmpty) {
      accLines.writeln('(لا توجد محافظ نشطة.)');
    } else {
      for (final a in accounts) {
        if (a.isDeleted) continue;
        final eff = effectiveWalletBalance(
          acc: a,
          entries: allEntries,
          txs: allTx,
          accounts: accounts,
          includeDebtEffect: includeDebts,
        );
        accLines.writeln(
          '- ${a.name} (${a.type.label}) | معرّف ${a.id} | رصيد ابتدائي مخزَّن: ${a.balance} شيكل | رصيد فعّال في التطبيق (مع الحركات): $eff شيكل',
        );
      }
    }

    final totalWalletsEffective = ref.read(walletsEffectiveTotalProvider);

    int debtorCount = debtors.length;
    double totalLiabilities = 0;
    double totalReceivables = 0;

    final debtorLines = StringBuffer();
    for (final d in debtors) {
      final amt = double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
      if (amt > 0) {
        totalReceivables += amt;
      } else if (amt < 0) {
        totalLiabilities += amt.abs();
      }

      final role = d.isSupplier ? 'بائع جملة' : 'زبون';
      final due = d.dueDate != null ? _ymd(d.dueDate!) : 'غير محدد';
      final phone = d.phone.trim().isEmpty ? '—' : d.phone;
      final addr = (d.address == null || d.address!.trim().isEmpty)
          ? ''
          : ' | عنوان: ${d.address}';
      final note = (d.note == null || d.note!.trim().isEmpty)
          ? ''
          : ' | ملاحظة: ${d.note}';
      final displayName = debtorLabel(d);
      debtorLines.writeln(
        '- [$role] الاسم في الدفتر: $displayName | معرّف السجل: ${d.id} | هاتف: $phone$addr | الرصيد الحالي: ${d.amount} شيكل (موجب=عليهم لك دين مستحق، سالب=أنت مدين لهم) | موعد الاستحقاق: $due | بيان الحالة في التطبيق: ${d.status}$note',
      );
    }

    final txLines = StringBuffer();
    if (txs.isEmpty) {
      txLines.writeln('(لا توجد معاملات دين/سداد مسجلة في السياق الحالي.)');
    } else {
      for (final t in txs) {
        final name =
            idToName[t.customerId] ?? 'غير معروف (معرّف ${t.customerId})';
        final kind = t.type == TransactionType.gave
            ? 'إضافة دين (بيع آجل/تدوين لهم)'
            : 'سداد أو تجميع';
        final method = transactionPayMethodLabel(t.payMethodId);
        final note = t.note.trim().isEmpty ? '—' : t.note.trim();
        txLines.writeln(
          '- ${_ymd(t.date)} | $name | $kind | ${t.amount} شيكل | وسيلة الدفع: $method | ملاحظة: $note',
        );
      }
    }

    final cashLines = StringBuffer();
    if (cash.isEmpty) {
      cashLines.writeln('(لا توجد حركات صندوق مسجلة.)');
    } else {
      for (final e in cash) {
        final kind = e.isIncome ? 'وارد (دخل)' : 'صادر (مصروف)';
        final note = e.note.trim().isEmpty ? '' : ' | ملاحظة: ${e.note}';
        final cat = (e.category == null || e.category!.trim().isEmpty)
            ? ''
            : ' | تصنيف: ${e.category}';
        cashLines.writeln(
          '- ${_ymd(e.date)} | ${e.title} | $kind | ${e.amount} شيكل$cat$note',
        );
      }
    }

    final debtBlock = debtorCount == 0
        ? '(لا يوجد زبائن أو بائعو جملة غير محذوفين في الدفتر.)'
        : debtorLines.toString().trim();

    return '''
### سياق دفتر «الصافي» — بيانات فعلية من التطبيق (للقراءة فقط؛ لا تُخترع أرقاماً خارجها):
- اسم صاحب المتجر من الإعدادات فقط (**ليس** أحد سجلات الزبائن أو بائعي الجملة في الدفتر): $userName
- عدد سجلات الزبائن/بائعي الجملة (غير محذوفة): $debtorCount
- إجمالي المبالغ المستحقة للمستخدم (رصيد موجب لدى الغير): $totalReceivables شيكل
- إجمالي مطلوبات المستخدم تجاه الغير (رصيد سالب مجمّع كقيمة مطلقة): $totalLiabilities شيكل
- **مجموع أرصدة المحافظ الفعلية** (الرصيد المبدئي لكل محفظة + حركات الصندوق المعنونة لها + تأثير الديون حسب إعداد التطبيق): $totalWalletsEffective شيكل
- ملخص حركات الصندوق فقط (غير المحذوفة): رصيد من الحركات ${cbSum.balance} شيكل؛ إجمالي وارد ${cbSum.income}؛ إجمالي صادر ${cbSum.expense}؛ عدد الحركات ${cbSum.transactionCount}

#### المحافظ المالية (كل محفظة نشطة):
${accLines.toString().trim()}

#### تفصيل كل زبون / بائع جملة (أسماء من الدفتر فقط):
$debtBlock

#### سجل معاملات الدين والسداد (من الأحدث للأقدم):
${txLines.toString().trim()}

#### حركات الصندوق / الكاش (من الأحدث للأقدم):
${cashLines.toString().trim()}
''';
  }
}

final aiAssistantProvider =
    NotifierProvider<AiAssistantNotifier, AiAssistantState>(
      () => AiAssistantNotifier(),
    );
