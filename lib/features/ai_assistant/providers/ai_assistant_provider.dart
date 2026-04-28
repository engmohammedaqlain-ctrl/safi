import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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
  static const _apiKey = 'AIzaSyABXnXdc0M9JYI0DoPPF0h2REGLn0WbTb4';

  late final GenerativeModel _model;

  @override
  AiAssistantState build() {
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
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

      final chat = _model.startChat(
        history: updatedHistory
            .skip(
              updatedHistory.length > 20 ? updatedHistory.length - 20 : 0,
            ) // keep context window reasonable
            .where((m) => m.id != userMsg.id)
            .map(
              (m) => Content(m.isUser ? 'user' : 'model', [TextPart(m.text)]),
            )
            .toList(),
      );

      final prompt =
          '$contextStr\n\nأجب بناءً على السياق السابق، بلغتنا العربية المبسطة وموجهة للمستخدم بلطف. سؤال المستخدم هو: ${userMsg.text}';

      final response = await chat.sendMessage(Content.text(prompt));

      final aiMsg = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: response.text ?? 'عذراً لا أستطيع الإجابة حالياً.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      final finalHistory = [...updatedHistory, aiMsg];
      state = state.copyWith(history: finalHistory, isTyping: false);
      _saveAndSyncHistory(finalHistory);
    } catch (e) {
      final errorMsg = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: 'عفواً حدث خطأ في الاتصال بالمساعد الذكي.',
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

    for (final d in debtors) {
      final amt = double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
      if (amt > 0)
        totalReceivables += amt;
      else if (amt < 0)
        totalDebts += amt.abs();
    }

    return '''
### سياق بيانات تطبيق (صافي - Safi) الخاص بالمستخدم:
- اسم المستخدم: $userName
- عدد العملاء/الموردين المسجلين: $debtorCount
- المبالغ التي للمستخدم (حسابات العملاء - يطالبهم بها): $totalReceivables شيكل.
- المبالغ التي على المستخدم (ديون للموردين): $totalDebts شيكل.
أنت بصفتك "المساعد الذكي لتطبيق صافي"، مهمتك مساعدة المستخدم في فهم تقاريره المالية، كتابة رسائل ديون، الرد على الاستفسارات. 
تحدث باختصار واحترافية وبلهجة عربية مفهومة (شامية/فصحى مبسطة).
''';
  }
}

final aiAssistantProvider =
    NotifierProvider<AiAssistantNotifier, AiAssistantState>(
      () => AiAssistantNotifier(),
    );
