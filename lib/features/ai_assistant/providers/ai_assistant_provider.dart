import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../debts/providers/debts_ui_provider.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../../sales/models/cashbook_entry.dart';
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
  static const _apiKey = 'sk-6e98977c40bc44b58e9cc425f01d845f';

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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
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
أنت مساعد ذكي لتطبيق مالي اسمه "الصافي".
المستخدم ($userName) يريد إرسال رسالة واتساب إلى العميل (${debtor.name}) لتذكيره بسداد دين قيمته (${debtor.amount} شيكل).
موعد السداد: ${debtor.dueDate != null ? '${debtor.dueDate!.year}/${debtor.dueDate!.month}/${debtor.dueDate!.day}' : 'غير محدد'}.
المطلوب: اكتب رسالة واتساب قصيرة، مهذبة، وواضحة بناءً على طلب المستخدم التالي:
"$customPrompt"
لا تضف أي مقدمات أو خاتمات من عندك، فقط نص الرسالة الجاهز للإرسال.
''';

      final res = await http.post(
        Uri.parse('https://api.deepseek.com/chat/completions'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': 'اكتب الرسالة الآن.'}
          ],
          'temperature': 0.7,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return data['choices'][0]['message']['content']?.trim() ?? 'عذراً، حدث خطأ.';
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
          '$contextStr\n\nأجب بناءً على السياق السابق، كن مبدعاً جداً في نقاشك، تحدث بلكنة ذكية، وقدم نصائح إبداعية وغير تقليدية عند حاجة المستخدم كخبير مالي متطور وصديق.';

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
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': messages,
          'tools': tools,
          'temperature': 0.7,
        }),
      );

      String reply = 'عذراً لا أستطيع الإجابة حالياً.';
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
              final name = args['name'] as String;
              final phone = args['phone'] as String? ?? '';
              final amount = (args['amount'] as num).toDouble();
              final isSupplier = args['isSupplier'] as bool;
              
              ref.read(debtorsUiProvider.notifier).addCustomer(
                DebtorUi(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
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
              final name = args['name'] as String;
              final debtors = ref.read(debtorsUiProvider);
              final matches = debtors.where((d) => d.name.toLowerCase() == name.toLowerCase()).toList();
              if (matches.isNotEmpty) {
                reply = 'وجدت العميل "$name"، لكن للحفاظ على أمان بياناتك، يرجى حذفه يدوياً من صفحة تفاصيل العميل.';
              } else {
                reply = 'لم أتمكن من العثور على عميل باسم "$name".';
              }
            } else if (functionName == 'record_transaction') {
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
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      );

      final finalHistory = [...updatedHistory, aiMsg];
      state = state.copyWith(history: finalHistory, isTyping: false);
      _saveAndSyncHistory(finalHistory);
    } catch (e, st) {
      print('AI API Error: $e\n$st');
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

  String _buildContext() {
    final userName = StartupLedgerData.bootstrapUserName ?? 'صاحب المتجر';
    final debtors = ref.read(debtorsUiProvider);

    int debtorCount = debtors.length;
    double totalDebts = 0;
    double totalReceivables = 0;

    final detailsBuffer = StringBuffer();

    for (final d in debtors) {
      final amt = double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
      if (amt > 0) {
        totalReceivables += amt;
      } else if (amt < 0) {
        totalDebts += amt.abs();
      }
      detailsBuffer.writeln('- ${d.name}: ${d.amount}');
    }

    return '''
### سياق بيانات تطبيق (الصافي) الخاص بالمستخدم:
- اسم المستخدم: $userName
- عدد العملاء/الموردين المسجلين: $debtorCount
- المبالغ الإجمالية التي للمستخدم: $totalReceivables شيكل.
- المبالغ الإجمالية التي على المستخدم الدفع: $totalDebts شيكل.

**أرشيف حسابات جميع العملاء / الموردين:**
${detailsBuffer.toString()}

أنت بصفتك "المساعد الذكي لتطبيق الصافي"، مهمتك مساعدة المستخدم في فهم تقاريره المالية، وتحديد أكبر مدين، وكتابة رسائل ديون، والرد على الاستفسارات. 
تحدث باختصار واحترافية وبلهجة عربية مبسطة.
''';
  }
}

final aiAssistantProvider =
    NotifierProvider<AiAssistantNotifier, AiAssistantState>(
      () => AiAssistantNotifier(),
    );
