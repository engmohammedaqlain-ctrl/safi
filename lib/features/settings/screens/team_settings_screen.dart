import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vault_subpage_scaffold.dart';

class TeamSettingsScreen extends StatelessWidget {
  const TeamSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultSubpageScaffold(
      title: 'الفريق والصلاحيات',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'أعضاء الفريق',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTeamMember(
            name: 'أنت (المالك)',
            role: 'مالك المتجر - كافة الصلاحيات',
            icon: LucideIcons.userCheck,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildTeamMember(
            name: 'أحمد (كاشير)',
            role: 'تسجيل الديون والمبيعات فقط',
            icon: LucideIcons.user,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('قريباً: إضافة أعضاء للفريق')),
              );
            },
            icon: const Icon(LucideIcons.userPlus, size: 20),
            label: const Text('إضافة عضو جديد', style: TextStyle(fontSize: 16)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember({
    required String name,
    required String role,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronLeft, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}
