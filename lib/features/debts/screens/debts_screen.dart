import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/debts_ui_provider.dart';
import '../utils/debtor_filter.dart';
import '../widgets/debtor_card.dart';
import 'add_debt_screen.dart';
import 'record_payment_screen.dart';

/// تبويب الديون — تخطيط نظيف (مستوى منتجات احترافية) بدون صناديق تحذير تستهلك الارتفاع
class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
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
    final my = ref.watch(debtMyNumbersProvider);
    final list = filterDebtors(all, _q);

    void push(Widget w) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => w),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        20,
      ),
      children: [
        Text(
          'ملخص',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        _MetricsStrip(
          totalLabel: my.totalDebtLabel,
          debtorCount: my.debtorCount,
          overdueCount: my.overdueCount,
        ),
        const SizedBox(height: 16),
        _PrimaryActions(
          onAddDebt: () => push(const AddDebtScreen()),
          onPayment: () => push(const RecordPaymentScreen()),
        ),
        const SizedBox(height: 20),
        Text(
          'قائمة العملاء',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _q = v),
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'ابحث بالاسم أو رقم الجوال',
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            prefixIcon: const Icon(
              LucideIcons.search,
              color: AppColors.textMuted,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.rlg,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.rlg,
              borderSide: BorderSide(color: AppColors.outlineSoft, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.rlg,
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
            ),
          ),
        ),
        if (_q.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${list.length} نتيجة',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (list.isEmpty)
          _EmptyState(hasQuery: _q.isNotEmpty)
        else
          ...List.generate(
            list.length,
            (i) => Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
              child: DebtorCard(debtor: list[i]),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          hasQuery ? 'لا يوجد عميل يطابق البحث' : 'لا بيانات لعرضها',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// شريط مؤشرات — بدون جِلاء ثقيل، ظلال خفيفة وتسلسل بصري واضح
class _MetricsStrip extends StatelessWidget {
  const _MetricsStrip({
    required this.totalLabel,
    required this.debtorCount,
    required this.overdueCount,
  });

  final String totalLabel;
  final int debtorCount;
  final int overdueCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCell(
            label: 'إجمالي الديون',
            value: totalLabel,
            icon: LucideIcons.coins,
            accent: AppColors.error,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCell(
            label: 'العملاء',
            value: '$debtorCount',
            icon: LucideIcons.users,
            accent: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCell(
            label: 'متأخر',
            value: '$overdueCount',
            icon: LucideIcons.clock3,
            accent: AppColors.warningAmber,
          ),
        ),
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: AppRadius.rlg,
        border: Border.all(color: AppColors.outlineSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({
    required this.onAddDebt,
    required this.onPayment,
  });

  final VoidCallback onAddDebt;
  final VoidCallback onPayment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onAddDebt,
            icon: const Icon(LucideIcons.userPlus, size: 18),
            label: const Text('تسجيل دين'),
            style: FilledButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.rmd,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: onPayment,
            icon: const Icon(LucideIcons.banknote, size: 18),
            label: const Text('تسجيل دفعة'),
            style: FilledButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.rmd,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
