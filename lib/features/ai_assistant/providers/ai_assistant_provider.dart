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
import '../../sales/models/cashbook_entry.dart';
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
  static const _prefsKey = 'safi_ai_chat_history';

  /// مفتاح DeepSeek API (مضمّن في التطبيق — لا يُقرأ من .env).
  static const String _deepseekApiKey =
      'sk-6e98977c40bc44b58e9cc425f01d845f';

  @override
  AiAssistantState build() {
    _loadHistory();
    return AiAssistantState();
  }

  Future<void> _loadHistory() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_prefsKey);
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
        _prefsKey,
        jsonEncode(history.map((e) => e.toMap()).toList()),
      );

      // Sync to Firebase if online/logged in (offline resilience is via SharedPreferences)
      final ownerUid =
          p.getString(PrefsKeys.ledgerOwnerUid) ?? FirebaseAuth.instance.currentUser?.uid;
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

  Future<String> generateWhatsAppMessage(DebtorUi debtor, String customPrompt) async {
    try {
      final userName = StartupLedgerData.bootstrapUserName ?? 'صاحب المتجر';
      final systemPrompt = '''
أنت خبير مالي معتمد؛ صِغْ نصاً واحداً جاهزاً للإرسال عبر واتساب بلغة عربية فصحى مرتبة، رسمية، وهادئة، مع أسلوب مهني كما يجري في المراسلات المالية في فلسطين.
سياق التطبيق: «الصافي». المستخدم ($userName). المقصود: العميل (${debtor.name})؛ قيمة المطلوب تذكيره بها: (${debtor.amount} شيكل).
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
            {'role': 'user', 'content': 'اكتب الرسالة الآن.'}
          ],
          'temperature': 0.45,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final raw = data['choices'][0]['message']['content']?.trim() ?? 'عذراً، حدث خطأ.';
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

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(PrefsKeys.userRole) ?? 'owner';
    final perms = prefs.getStringList(PrefsKeys.userPermissions) ?? [];
    final isOwner = role == 'owner';

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

      final systemPrompt = '''
$contextStr

أنت خبير مالي معتمد تتحدث بالعربية الفصحى الموجزة بأسلوب رسمي ومهني دائماً، مع فهم عملي للتجارة والتزامات الديون كما يمارَس في فلسطين.
قدّم إجابة واضحة ومنظّمة (فقرات قصيرة أو نقاط مرقّمة عند الحاجة). تجنّب العامية والتهريج والعبارات الترويجية أو الخفيفة.
لا تخترع أرقاماً أو أسماء عملاء غير واردة في السياق أعلاه. إن كان المستخدم كاشيراً أو مشاهدًا فقط، التزم بنطاق الصلاحيات الظاهر من بيانات الدفتر.
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

      final tools = [
        {
          "type": "function",
          "function": {
            "name": "add_customer",
            "description": "إضافة عميل أو مورد جديد إلى دفتر الديون.",
            "parameters": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string",
                  "description": "اسم العميل أو المورد"
                },
                "phone": {
                  "type": "string",
                  "description": "رقم الهاتف"
                },
                "amount": {
                  "type": "number",
                  "description": "الرصيد الابتدائي (موجب إذا كان العميل مديناً لك، سالب إذا كنت مديناً له)"
                },
                "isSupplier": {
                  "type": "boolean",
                  "description": "هل هذا مورد؟ (true للمورد، false للعميل)"
                }
              },
              "required": ["name", "amount", "isSupplier"]
            }
          }
        },
        {
          "type": "function",
          "function": {
            "name": "add_cashbook_entry",
            "description": "إضافة حركة مالية جديدة إلى الصندوق (محفظة الكاش).",
            "parameters": {
              "type": "object",
              "properties": {
                "title": {
                  "type": "string",
                  "description": "وصف الحركة المالية (مثال: مبيعات، راتب، إيجار)"
                },
                "amount": {
                  "type": "number",
                  "description": "قيمة الحركة المالية"
                },
                "isIncome": {
                  "type": "boolean",
                  "description": "هل هذه الحركة دخل (true) أم مصروف (false)؟"
                }
              },
              "required": ["title", "amount", "isIncome"]
            }
          }
        },
        {
          "type": "function",
          "function": {
            "name": "delete_customer",
            "description": "حذف عميل أو مورد من دفتر الديون باستخدام اسمه.",
            "parameters": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string",
                  "description": "اسم العميل أو المورد المراد حذفه"
                }
              },
              "required": ["name"]
            }
          }
        },
        {
          "type": "function",
          "function": {
            "name": "record_transaction",
            "description": "تسجيل سداد أو دين جديد لعميل أو مورد موجود مسبقاً.",
            "parameters": {
              "type": "object",
              "properties": {
                "customerName": {
                  "type": "string",
                  "description": "اسم العميل أو المورد"
                },
                "amount": {
                  "type": "number",
                  "description": "قيمة السداد أو الدين"
                },
                "type": {
                  "type": "string",
                  "enum": ["gave", "received"],
                  "description": "نوع المعاملة: gave (دين جديد على حساب العميل/المورد)، received (سداد من العميل/المورد)"
                },
                "note": {
                  "type": "string",
                  "description": "ملاحظة أو وصف للمعاملة"
                }
              },
              "required": ["customerName", "amount", "type"]
            }
          }
        },
        {
          "type": "function",
          "function": {
            "name": "update_due_date",
            "description": "تحديد أو تحديث موعد سداد الدين لعميل أو مورد.",
            "parameters": {
              "type": "object",
              "properties": {
                "customerName": {
                  "type": "string",
                  "description": "اسم العميل أو المورد"
                },
                "daysFromNow": {
                  "type": "number",
                  "description": "عدد الأيام من اليوم حتى موعد السداد (مثال: 7 يعني بعد أسبوع)"
                }
              },
              "required": ["customerName", "daysFromNow"]
            }
          }
        }
      ];

      var res = await http.post(
        Uri.parse('https://api.deepseek.com/chat/completions'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_deepseekApiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': messages,
          'tools': tools,
          'temperature': 0.45,
        }),
      );

      String reply = 'عذراً، تعذّر تقديم إجابة في الوقت الحالي.';
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final message = data['choices'][0]['message'];
        
        if (message['tool_calls'] != null) {
          // Handle tool calls
          final toolCalls = message['tool_calls'] as List<dynamic>;
          for (final toolCall in toolCalls) {
            final functionName = toolCall['function']['name'];
            final args = jsonDecode(toolCall['function']['arguments'] as String);
            
            if (functionName == 'add_customer') {
              if (!isOwner && !perms.contains('add_debt')) {
                reply = 'ليس لديك صلاحية إضافة عملاء.';
                continue;
              }
              final name = args['name'] as String;
              final phone = args['phone'] as String? ?? '';
              final amount = (args['amount'] as num).toDouble();
              final isSupplier = args['isSupplier'] as bool;
              
              ref.read(debtorsUiProvider.notifier).addCustomer(
                DebtorUi(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  editedMs: DateTime.now().millisecondsSinceEpoch,
                  name: name,
                  phone: phone,
                  amount: amount.toStringAsFixed(1),
                  status: 'تمت الإضافة بواسطة المساعد',
                  urgency: DebtUrgency.low,
                  isSupplier: isSupplier,
                ),
              );
              reply = 'تم إضافة ${isSupplier ? 'المورد' : 'العميل'} "$name" بنجاح برصيد $amount شيكل.';
            } else if (functionName == 'add_cashbook_entry') {
              if (!isOwner && !perms.contains('record_payment')) {
                reply = 'ليس لديك صلاحية إضافة حركات مالية.';
                continue;
              }
              final title = args['title'] as String;
              final amount = (args['amount'] as num).toDouble();
              final isIncome = args['isIncome'] as bool;
              
              ref.read(cashbookEntriesProvider.notifier).add(
                CashbookEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  amount: amount,
                  isIncome: isIncome,
                  date: DateTime.now(),
                ),
              );
              reply = 'تم إضافة الحركة "$title" بقيمة $amount شيكل كـ ${isIncome ? 'دخل' : 'مصروف'} في الصندوق بنجاح.';
            } else if (functionName == 'delete_customer') {
              if (!isOwner && !perms.contains('delete_records')) {
                reply = 'ليس لديك صلاحية الحذف.';
                continue;
              }
              final name = args['name'] as String;
              final debtors = ref.read(debtorsUiProvider);
              final matches = debtors.where((d) => d.name.toLowerCase() == name.toLowerCase()).toList();
              if (matches.isNotEmpty) {
                reply = 'وجدت العميل "$name"، لكن للحفاظ على أمان بياناتك، يرجى حذفه يدوياً من صفحة تفاصيل العميل.';
              } else {
                reply = 'لم أتمكن من العثور على عميل باسم "$name".';
              }
            } else if (functionName == 'record_transaction') {
              if (!isOwner && !perms.contains('record_payment')) {
                reply = 'ليس لديك صلاحية تسجيل معاملات.';
                continue;
              }
              final customerName = args['customerName'] as String;
              final amount = (args['amount'] as num).toDouble();
              final typeStr = args['type'] as String;
              final note = args['note'] as String? ?? '';
              
              final debtors = ref.read(debtorsUiProvider);
              final matches = debtors.where((d) => d.name.toLowerCase().contains(customerName.toLowerCase())).toList();
              
              if (matches.isNotEmpty) {
                final customer = matches.first;
                final isGave = typeStr == 'gave';
                final delta = isGave ? amount : -amount;
                
                ref.read(transactionsProvider.notifier).addTransaction(
                  TransactionUi(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    customerId: customer.id,
                    amount: amount,
                    type: isGave ? TransactionType.gave : TransactionType.received,
                    note: note,
                    date: DateTime.now(),
                  ),
                );
                
                ref.read(debtorsUiProvider.notifier).updateCustomerBalance(customer.id, delta);
                
                reply = 'تم تسجيل المعاملة بنجاح: ${isGave ? 'دين جديد' : 'سداد'} $amount شيكل ${isGave ? 'لـ' : 'من'} "${customer.name}".';
              } else {
                reply = 'لم أتمكن من العثور على عميل باسم "$customerName".';
              }
            } else if (functionName == 'update_due_date') {
              final customerName = args['customerName'] as String;
              final daysFromNow = (args['daysFromNow'] as num).toInt();
              
              final debtors = ref.read(debtorsUiProvider);
              final matches = debtors.where((d) => d.name.toLowerCase().contains(customerName.toLowerCase())).toList();
              
              if (matches.isNotEmpty) {
                final customer = matches.first;
                final dueDate = DateTime.now().add(Duration(days: daysFromNow));
                
                ref.read(debtorsUiProvider.notifier).updateCustomerDueDate(customer.id, dueDate);
                
                reply = 'تم تحديث موعد السداد للعميل "${customer.name}" ليكون بعد $daysFromNow أيام (${dueDate.year}/${dueDate.month}/${dueDate.day}).';
              } else {
                reply = 'لم أتمكن من العثور على عميل باسم "$customerName".';
              }
            }
          }
        } else {
          reply = message['content'] ?? reply;
        }
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

  String _buildContext() {
    final userName = StartupLedgerData.bootstrapUserName ?? 'صاحب المتجر';
    final debtors = ref.read(debtorsUiProvider);

    int debtorCount = debtors.length;
    double totalDebts = 0;
    double totalReceivables = 0;

    for (final d in debtors) {
      final amt = double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
      if (amt > 0) {
        totalReceivables += amt;
      } else if (amt < 0) {
        totalDebts += amt.abs();
      }
    }

    return '''
### سياق دفتر «الصافي» (للمحادثة فقط؛ لا تُضِف أرقاماً خارجها):
- اسم صاحب الجلسة المعروض في التطبيق: $userName
- عدد سجلات العملاء/الموردين: $debtorCount
- إجمالي المستحق للمستخدم (موجب الرصيد لدى الغير): $totalReceivables شيكل
- إجمالي مطلوبات المستخدم (سالب الرصيد): $totalDebts شيكل
''';
  }
}

final aiAssistantProvider =
    NotifierProvider<AiAssistantNotifier, AiAssistantState>(
      () => AiAssistantNotifier(),
    );
