import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../../features/cash_flow/data/financial_account_model.dart';
import '../../features/cash_flow/providers/accounts_provider.dart';

/// محدد حساب ذكي يستمد الحسابات بشكل ديناميكي (كاش، محفظتك، بنكك)
class AccountSelector extends ConsumerWidget {
  const AccountSelector({
    super.key,
    required this.selectedAccountId,
    required this.onChanged,
  });

  final String? selectedAccountId;
  final ValueChanged<FinancialAccount> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);

    if (accounts.isEmpty) {
      return Text(
        'لا يوجد حسابات مسجلة.',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: accounts.map((acc) {
        final isSelected = acc.id == selectedAccountId;

        return GestureDetector(
          onTap: () => onChanged(acc),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.backgroundSecondary,
              borderRadius: AppRadius.rmd,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.outlineSoft,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  acc.type.icon,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  acc.name,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
