import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/vault_subpage_scaffold.dart';
import '../../../core/widgets/safi_button.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VaultSubpageScaffold(
      title: 'المساعد الذكي',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _bubble(
                  isUser: false,
                  text:
                      'صباح الخير! اسألني عن مبيعاتك، ديونك، أو أطلب رسالة تحصيل.',
                ),
                const SizedBox(height: 10),
                _bubble(
                  isUser: true,
                  text: 'ليش انخفضت مبيعات الأسبوع؟',
                ),
                const SizedBox(height: 10),
                _bubble(
                  isUser: false,
                  text:
                      'توقّعات أسبوعك أقل 12٪ بسبب نقص 4 منتجات وديون متأخرة. راجع المخزون.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in const [
                      'أكثر منتج مبيعاً؟',
                      'مجموع الديون؟',
                      'اكتب رسالة لـ مؤيد',
                    ])
                      ActionChip(
                        label: Text(t),
                        onPressed: () {
                          setState(() => _controller.text = t);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            decoration: const BoxDecoration(
              color: AppColors.backgroundSecondary,
              border: Border(
                top: BorderSide(color: AppColors.outlineSoft),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'اكتب سؤالك...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SafiButton(
                  label: 'إرسال',
                  isExpanded: false,
                  onPressed: () {},
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
      child: GlassCard(
        background: isUser
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.aiPurple.withValues(alpha: 0.08),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const Icon(LucideIcons.sparkles, color: AppColors.aiPurple, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
