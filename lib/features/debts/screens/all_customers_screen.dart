import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/debts_ui_provider.dart';
import '../utils/debtor_filter.dart';
import 'add_debt_screen.dart';
import 'customer_detail_screen.dart';
import 'package:safi/core/router/app_page_route.dart';

/// كل العملاء — من «المزيد» أو للمراجعة السريعة
class AllCustomersScreen extends ConsumerStatefulWidget {
  const AllCustomersScreen({super.key});

  @override
  ConsumerState<AllCustomersScreen> createState() =>
      _AllCustomersScreenState();
}

class _AllCustomersScreenState extends ConsumerState<AllCustomersScreen> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(debtorsUiProvider);
    final list = filterDebtors(all, _q);

    return Scaffold(
      appBar: AppBar(
        title: const Text('عملائي'),
        actions: [
          IconButton(
            tooltip: 'تسجيل دين لعميل',
            onPressed: () {
              Navigator.push<void>(
                context,
                AppPageRoute<void>(
                  builder: (_) => const AddDebtScreen(),
                ),
              );
            },
            icon: const Icon(LucideIcons.userPlus),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _q = v),
            style: AppTextStyles.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'ابحث بالاسم أو رقم الجوال...',
              prefixIcon: Icon(LucideIcons.search, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${list.length} عميل',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text(
                  'لا نتائج. جرّب كلمات أخرى أو أضف عميلاً من تسجيل دين.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _CustomerRow(
                debtor: list[i],
                onTap: () {
                  Navigator.push<void>(
                    context,
                    AppPageRoute<void>(
                      builder: (_) => CustomerDetailScreen(debtor: list[i]),
                    ),
                  );
                },
              ),
            ],
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.debtor, required this.onTap});

  final DebtorUi debtor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = urgencyToColor(debtor.urgency);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: GlassCard(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(LucideIcons.user, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debtor.name, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      debtor.phone,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₪ ${debtor.amount}',
                style: AppTextStyles.numberMedium.copyWith(color: c),
              ),
              const Icon(
                LucideIcons.chevronLeft,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
