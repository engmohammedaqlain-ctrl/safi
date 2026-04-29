import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vault_subpage_scaffold.dart';

class SmartFeaturesScreen extends StatefulWidget {
  const SmartFeaturesScreen({super.key});

  @override
  State<SmartFeaturesScreen> createState() => _SmartFeaturesScreenState();
}

class _SmartFeaturesScreenState extends State<SmartFeaturesScreen> {
  bool _aiAssistant = true;
  bool _smartReminders = true;
  bool _autoBackup = true;

  @override
  Widget build(BuildContext context) {
    return VaultSubpageScaffold(
      title: 'الميزات الذكية',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.aiGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'صافي الذكي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'مساعدك المالي الشخصي يعمل على مدار الساعة.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSwitchTile(
            title: 'المساعد الذكي للديون',
            subtitle: 'توليد رسائل واتساب وتذكيرات ذكية',
            value: _aiAssistant,
            onChanged: (v) => setState(() => _aiAssistant = v),
          ),
          const Divider(height: 1),
          _buildSwitchTile(
            title: 'التذكيرات التلقائية',
            subtitle: 'إشعارك قبل موعد سداد الدين بيوم',
            value: _smartReminders,
            onChanged: (v) => setState(() => _smartReminders = v),
          ),
          const Divider(height: 1),
          _buildSwitchTile(
            title: 'النسخ الاحتياطي التلقائي',
            subtitle: 'مزامنة بياناتك مع السحابة بشكل دوري',
            value: _autoBackup,
            onChanged: (v) => setState(() => _autoBackup = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
      activeThumbColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    );
  }
}
