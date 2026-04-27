import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/status_pill.dart';
import '../providers/debts_ui_provider.dart';
import '../screens/customer_detail_screen.dart';
import 'package:safi/core/router/app_page_route.dart';

class DebtorCard extends StatelessWidget {
  const DebtorCard({super.key, required this.debtor});

  final DebtorUi debtor;

  @override
  Widget build(BuildContext context) {
    final urgencyColor = urgencyToColor(debtor.urgency);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push<void>(
            context,
            AppPageRoute<void>(
              builder: (_) => CustomerDetailScreen(debtor: debtor),
            ),
          );
        },
        borderRadius: AppRadius.rlg,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: AppRadius.rlg,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      debtor.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(label: debtor.status, color: urgencyColor),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'تفاصيل',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    LucideIcons.chevronLeft,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const Spacer(),
                  Text(
                    '₪ ${debtor.amount}',
                    style: AppTextStyles.numberMedium.copyWith(
                      color: const Color(0xFF1F1528),
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
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
