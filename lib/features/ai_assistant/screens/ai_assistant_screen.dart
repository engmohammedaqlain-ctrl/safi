import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/vault_subpage_scaffold.dart';
import '../providers/ai_assistant_provider.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    ref.read(aiAssistantProvider.notifier).sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantProvider);
    final history = state.history;

    // Scroll to bottom on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return VaultSubpageScaffold(
      title: 'المساعد الذكي',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.trash2, color: AppColors.textMuted),
          onPressed: () {
            ref.read(aiAssistantProvider.notifier).clearHistory();
          },
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: history.isEmpty ? 1 : history.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      _bubble(
                        isUser: false,
                        text:
                            'أهلاً بك! أنا المساعد الذكي لتطبيق صافي، جاهز للإجابة عن أسئلتك، كتابة خطابات للعملاء، أو تحليل ديونك.',
                      ),
                      if (history.isEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in const [
                              'مين أكثر شخص مدين لي؟',
                              'لخص لي حالتي المالية؟',
                              'اكتب رسالة طلب سداد ديون محترمة',
                            ])
                              ActionChip(
                                label: Text(
                                  t,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: AppColors.surfaceVariant,
                                side: const BorderSide(
                                  color: AppColors.outlineSoft,
                                ),
                                onPressed: () {
                                  _controller.text = t;
                                },
                              ),
                          ],
                        ),
                      ],
                    ],
                  );
                }

                final msg = history[index - 1];
                return _bubble(isUser: msg.isUser, text: msg.text);
              },
            ),
          ),
          if (state.isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'المساعد يكتب...',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.outlineSoft),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _controller,
                      textDirection: TextDirection.rtl,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'اكتب سؤالك هنا...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: state.isTyping ? null : _send,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: state.isTyping
                          ? AppColors.textMuted
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.send,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble({required bool isUser, required String text}) {
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: EdgeInsets.only(left: isUser ? 0 : 32, right: isUser ? 32 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 0 : 16),
            bottomRight: Radius.circular(isUser ? 16 : 0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser) ...[
              const Icon(
                LucideIcons.sparkles,
                color: AppColors.aiPurple,
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                text,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
