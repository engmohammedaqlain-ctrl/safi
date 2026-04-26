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
      Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => w));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        24,
      ),
      children: [
        _MetricsStrip(
          totalLabel: my.totalDebtLabel,
          debtorCount: my.debtorCount,
          overdueCount: my.overdueCount,
        ),
        const SizedBox(height: 18),
        _PrimaryActions(
          onAddDebt: () => push(const AddDebtScreen()),
          onPayment: () => push(const RecordPaymentScreen()),
        ),
        const SizedBox(height: 22),
        Text(
          'قائمة العملاء',
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _q = v),
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'ابحث بالاسم أو رقم الجوال',
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 14,
            ),
            prefixIcon: const Icon(
              LucideIcons.search,
              color: AppColors.textMuted,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.rfull,
              borderSide: BorderSide(
                color: AppColors.textMuted.withValues(alpha: 0.15),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.rfull,
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.12),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.rfull,
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.45),
                width: 1.5,
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEEECEF),
              borderRadius: AppRadius.rlg,
            ),
            child: const Icon(
              LucideIcons.users,
              size: 36,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery ? 'لا يوجد عميل يطابق البحث' : 'لا يوجد عملاء بعد',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuery
                ? 'جرّب كلمات أوسع أو أعد المحاولة'
                : 'سجّل ديناً أو دفعة من الأعلى لبدء المتابعة',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// ثلاث بطاقات موازية — مثل واجهات دفاتر الديون الاحترافية
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
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCell(
            label: 'العملاء',
            value: '$debtorCount',
            icon: LucideIcons.users,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCell(
            label: 'متأخر',
            value: '$overdueCount',
            icon: LucideIcons.clock3,
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
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
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
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEBF0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
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
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({required this.onAddDebt, required this.onPayment});

  final VoidCallback onAddDebt;
  final VoidCallback onPayment;

  static const _tileRadius = 18.0;
  static const _tileH = 100.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CtaBlock(
            height: _tileH,
            radius: _tileRadius,
            background: AppColors.primary,
            onTap: onAddDebt,
            icon: LucideIcons.userPlus,
            label: 'تسجيل دين',
            subtitle: 'دين جديد',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CtaBlock(
            height: _tileH,
            radius: _tileRadius,
            background: AppColors.primaryDark,
            onTap: onPayment,
            icon: LucideIcons.banknote,
            label: 'تسجيل دفعة',
            subtitle: 'سداد أو تخفيض',
          ),
        ),
      ],
    );
  }
}

class _CtaBlock extends StatelessWidget {
  const _CtaBlock({
    required this.height,
    required this.radius,
    required this.background,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final double height;
  final double radius;
  final Color background;
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(radius),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: AppColors.onPrimary),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.9),
                    fontSize: 11,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
