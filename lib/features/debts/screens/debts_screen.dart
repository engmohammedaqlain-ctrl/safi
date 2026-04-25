import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/debts_ui_provider.dart';
import '../widgets/debtor_card.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(debtorsUiProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        100,
      ),
      children: [
        GlassCard(
          background: AppColors.error.withValues(alpha: 0.08),
          child: Row(
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                color: AppColors.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ديون تحتاج متابعة — رتّب الأولوية حسب التأخير.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...list.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DebtorCard(debtor: d),
          ),
        ),
      ],
    );
  }
}
