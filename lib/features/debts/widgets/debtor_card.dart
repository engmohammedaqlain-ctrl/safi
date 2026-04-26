import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../providers/debts_ui_provider.dart';
import '../screens/customer_detail_screen.dart';

class DebtorCard extends StatelessWidget {
  const DebtorCard({super.key, required this.debtor});

  final DebtorUi debtor;

  @override
  Widget build(BuildContext context) {
    final c = urgencyToColor(debtor.urgency);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => CustomerDetailScreen(debtor: debtor),
            ),
          );
        },
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(debtor.name, style: AppTextStyles.titleSmall),
                  ),
                  StatusPill(label: debtor.status, color: c),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    LucideIcons.chevronLeft,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'تفاصيل',
                    style: AppTextStyles.labelSmall,
                  ),
                  const Spacer(),
                  Text(
                    '₪ ${debtor.amount}',
                    style: AppTextStyles.numberLarge.copyWith(color: c),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
