import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../debts/providers/debts_ui_provider.dart';
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

      final res = await http.post(
        Uri.parse('https://api.deepseek.com/chat/completions'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': messages,
          'temperature': 0.7,
        }),
      );

      String reply = 'عذراً لا أستطيع الإجابة حالياً.';
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        reply = data['choices'][0]['message']['content'] ?? reply;
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
### سياق بيانات تطبيق (صافي - Safi) الخاص بالمستخدم:
- اسم المستخدم: $userName
- عدد العملاء/الموردين المسجلين: $debtorCount
- المبالغ الإجمالية التي للمستخدم: $totalReceivables شيكل.
- المبالغ الإجمالية التي على المستخدم الدفع: $totalDebts شيكل.

**أرشيف حسابات جميع العملاء / الموردين:**
${detailsBuffer.toString()}

أنت بصفتك "المساعد الذكي لتطبيق صافي"، مهمتك مساعدة المستخدم في فهم تقاريره المالية، وتحديد أكبر مدين، وكتابة رسائل ديون، والرد على الاستفسارات. 
تحدث باختصار واحترافية وبلهجة عربية مبسطة.
''';
  }
}

final aiAssistantProvider =
    NotifierProvider<AiAssistantNotifier, AiAssistantState>(
      () => AiAssistantNotifier(),
    );
