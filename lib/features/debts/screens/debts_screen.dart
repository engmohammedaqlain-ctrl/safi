import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/debts_ui_provider.dart';
import '../utils/debtor_filter.dart';
import '../../../core/router/main_shell.dart' show hideBalanceProvider;
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';
import 'package:safi/core/router/app_page_route.dart';
import '../../settings/providers/team_provider.dart';

/// أدنى عرض لعمود المبالغ في القائمة (يتوسّع مع العرض حتى حد أقصى).
const double _kDebtMoneyColumnMin = 120;
const double _kDebtMoneyColumnMax = 220;

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

enum DebtFilter { all, oweMe, iOwe }

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  final _search = TextEditingController();
  String _q = '';
  int _selectedTab = 0;
  DebtFilter _filterType = DebtFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تصفية حسب الرصيد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('الكل'),
                  trailing: _filterType == DebtFilter.all
                      ? const Icon(LucideIcons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _filterType = DebtFilter.all);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('ديونهم لك'),
                  trailing: _filterType == DebtFilter.oweMe
                      ? const Icon(LucideIcons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _filterType = DebtFilter.oweMe);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('ديونك لهم'),
                  trailing: _filterType == DebtFilter.iOwe
                      ? const Icon(LucideIcons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _filterType = DebtFilter.iOwe);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuppliersTab = _selectedTab == 1;
    final source = isSuppliersTab
        ? ref.watch(suppliersOnlyProvider)
        : ref.watch(customersOnlyProvider);
    final my = isSuppliersTab
        ? ref.watch(suppliersNumbersProvider)
        : ref.watch(customersNumbersProvider);
    var list = filterDebtors(source, _q);
    if (_filterType == DebtFilter.oweMe) {
      list = list.where((d) {
        final amt = double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
        return amt > 0;
      }).toList();
    } else if (_filterType == DebtFilter.iOwe) {
      list = list.where((d) {
        final amt = double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
        return amt < 0;
      }).toList();
    }
    final hidden = ref.watch(hideBalanceProvider);
    final permsAsync = ref.watch(userPermissionsProvider);
    final roleAsync = ref.watch(userRoleProvider);
    final canAddDebt = permsAsync.value?.contains('add_debt') ?? false;
    final isOwner = roleAsync.when(
      data: (r) => r == 'owner',
      loading: () => true,
      error: (_, __) => true,
    );

    final entityLabel = isSuppliersTab ? 'الموردين' : 'العملاء';
    final emptyLabel = isSuppliersTab ? 'لا يوجد موردون' : 'لا يوجد عملاء';
    final fabLabel = isSuppliersTab ? 'إضافة مورد' : 'إضافة عميل';
    final summaryCountLabel = '$entityLabel: ${hidden ? '**' : my.debtorCount}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    title: 'العملاء',
                    icon: LucideIcons.user,
                    isSelected: _selectedTab == 0,
                    onTap: () {
                      ref.read(debtsLedgerTabProvider.notifier).setTab(0);
                      setState(() => _selectedTab = 0);
                    },
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    title: 'الموردين',
                    icon: LucideIcons.truck,
                    isSelected: _selectedTab == 1,
                    onTap: () {
                      ref.read(debtsLedgerTabProvider.notifier).setTab(1);
                      setState(() => _selectedTab = 1);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DebtSummaryAmountsTable(
                  hidden: hidden,
                  totalReceivedLabel: my.totalReceivedLabel,
                  totalGaveLabel: my.totalGaveLabel,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'متأخر: ${hidden ? '**' : my.overdueCount}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      summaryCountLabel,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                '$entityLabel (${list.length})',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // RTL: أول طفل = يمين الشاشة → حقل البحث
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _q = v),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'البحث',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      prefixIcon: Icon(
                        LucideIcons.search,
                        color: Colors.grey.shade500,
                        size: 19,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _FilterIconButton(
                icon: LucideIcons.slidersHorizontal,
                isActive: _filterType != DebtFilter.all,
                onTap: _showFilterSheet,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Text(
                  emptyLabel,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                ),
              ),
            ),
          ...list.map((debtor) {
            final amountText = debtor.amount.replaceAll('₪', '').trim();
            final isRed =
                !amountText.startsWith('-') &&
                amountText != '0.0' &&
                amountText != '0';
            final color = isRed ? Colors.deepOrange : Colors.green;
            final label = isRed ? 'له دين' : 'لي دين';
            final displayAmount = amountText.startsWith('-')
                ? amountText.substring(1)
                : amountText;
            final avatarStr = debtor.name.startsWith('+')
                ? '+'
                : (debtor.name.isNotEmpty
                      ? debtor.name.split(' ').first[0]
                      : '؟');

            return InkWell(
              onTap: () {
                Navigator.push<void>(
                  context,
                  AppPageRoute<void>(
                    builder: (_) => CustomerDetailScreen(debtor: debtor),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, rowConstraints) {
                    final moneyMax = (rowConstraints.maxWidth * 0.38)
                        .clamp(_kDebtMoneyColumnMin, _kDebtMoneyColumnMax);
                    return Row(
                      children: [
                        // RTL: يمين الصف → الأفاتار + الاسم
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  avatarStr,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      debtor.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      debtor.status,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          fit: FlexFit.loose,
                          flex: 0,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: moneyMax),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hidden ? '****' : '₪ $displayAmount',
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                Text(
                                  label,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: (isOwner || canAddDebt) ? Padding(
        padding: const EdgeInsetsDirectional.only(end: 8, bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push<void>(
              context,
              AppPageRoute<void>(
                builder: (_) => AddCustomerScreen(isSupplier: isSuppliersTab),
              ),
            );
          },
          backgroundColor: AppColors.primary,
          elevation: 0,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          extendedIconLabelSpacing: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          icon: Icon(
            isSuppliersTab ? LucideIcons.truck : LucideIcons.userPlus,
            color: Colors.white,
            size: 19,
          ),
          label: Text(
            fabLabel,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: AppFonts.family,
              height: 1.2,
            ),
          ),
        ),
      ) : null,
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // RTL: يمين الزر → النص، يسار → الأيقونة
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 19,
              color: isSelected ? AppColors.primary : Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;

  const _FilterIconButton({required this.icon, this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
        ),
        child: Icon(icon, color: AppColors.primary, size: 19),
      ),
    );
  }
}

TextStyle _debtSummaryLabelStyle() => TextStyle(
      color: Colors.grey.shade600,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

TextStyle _debtSummaryValueStyle(Color color) => TextStyle(
      color: color,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// جدول بصري بلا حدود: عناوين بعمود ثابت + مبالغ بمحاذاة LTR نحو العناوين.
class _DebtSummaryAmountsTable extends StatelessWidget {
  const _DebtSummaryAmountsTable({
    required this.hidden,
    required this.totalReceivedLabel,
    required this.totalGaveLabel,
  });

  final bool hidden;
  final String totalReceivedLabel;
  final String totalGaveLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final safeW = w.isFinite && w > 0 ? w : 280.0;
        final labelCol =
            (safeW * 0.34).clamp(78.0, 118.0);
        final valueCol = (safeW - labelCol).clamp(104.0, 400.0);
        return Table(
          columnWidths: {
            0: FixedColumnWidth(labelCol),
            1: FixedColumnWidth(valueCol),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('سداد', style: _debtSummaryLabelStyle()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      hidden ? '****' : totalReceivedLabel,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.end,
                      style: _debtSummaryValueStyle(Colors.green),
                    ),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('دين جديد', style: _debtSummaryLabelStyle()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      hidden ? '****' : totalGaveLabel,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.end,
                      style: _debtSummaryValueStyle(Colors.deepOrange),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
