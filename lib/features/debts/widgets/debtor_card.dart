import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safi_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../providers/debts_ui_provider.dart';

class DebtorCard extends StatelessWidget {
  const DebtorCard({super.key, required this.debtor});

  final DebtorUi debtor;

  @override
  Widget build(BuildContext context) {
    final c = urgencyToColor(debtor.urgency);
    return GlassCard(
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
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '₪ ${debtor.amount}',
                style: AppTextStyles.numberLarge.copyWith(color: c),
              ),
              const Spacer(),
              SafiButton(
                label: 'رسالة AI',
                icon: LucideIcons.sparkles,
                variant: SafiButtonVariant.ai,
                isExpanded: false,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
