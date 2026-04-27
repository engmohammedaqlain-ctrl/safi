import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/debts_ui_provider.dart';
import '../utils/debtor_filter.dart';
import '../../../core/router/main_shell.dart' show hideBalanceProvider;
import 'add_customer_screen.dart';
import 'record_payment_screen.dart';
import 'customer_detail_screen.dart';
import 'package:safi/core/router/app_page_route.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  final _search = TextEditingController();
  String _q = '';
  int _selectedTab = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
    final list = filterDebtors(source, _q);
    final hidden = ref.watch(hideBalanceProvider);

    final entityLabel = isSuppliersTab ? 'الموردين' : 'العملاء';
    final emptyLabel = isSuppliersTab ? 'لا يوجد موردون' : 'لا يوجد عملاء';
    final fabLabel = isSuppliersTab ? 'إضافة مورد' : 'إضافة عميل';
    final summaryCountLabel = '$entityLabel: ${hidden ? '**' : my.debtorCount}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    title: 'الموردين',
                    icon: LucideIcons.truck,
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // أول طفل = يمين البطاقة في RTL: «أخذت / أعطيت» + سطر العدّاد
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryMetricRow(
                      label: 'أخذت',
                      value: hidden ? '****' : my.totalReceivedLabel,
                      valueColor: Colors.green,
                    ),
                    const SizedBox(height: 6),
                    _SummaryMetricRow(
                      label: 'أعطيت',
                      value: hidden ? '****' : my.totalGaveLabel,
                      valueColor: Colors.deepOrange,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'متأخر: ${hidden ? '**' : my.overdueCount}',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                // ثاني طفل = يسار البطاقة في RTL: أيقونات الإجراءات
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isSuppliersTab) ...[
                      _ActionButton(
                        icon: LucideIcons.bell,
                        label: 'تحصيل الديون',
                        onTap: () => Navigator.push<void>(
                          context,
                          AppPageRoute<void>(
                            builder: (_) => const RecordPaymentScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    _ActionButton(
                      icon: LucideIcons.barChart2,
                      label: 'التقارير',
                      onTap: () {},
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _q = v),
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'البحث',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(
                        LucideIcons.search,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _FilterIconButton(icon: LucideIcons.slidersHorizontal),
              const SizedBox(width: 8),
              _FilterIconButton(icon: LucideIcons.fileText),
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
            final label = isRed ? 'أعطيت' : 'أخذت';
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
                  vertical: 16,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // RTL: يمين الصف → الأفاتار + الاسم
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            avatarStr,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              debtor.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              debtor.status,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // RTL: يسار الصف → المبلغ ووسم أعطيت/أخذت
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          hidden ? '****' : '₪ $displayAmount',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: Icon(
          isSuppliersTab ? LucideIcons.truck : LucideIcons.userPlus,
          color: Colors.white,
        ),
        label: Text(
          fabLabel,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
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
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  final IconData icon;

  const _FilterIconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

/// صف عرض «أخذت / أعطيت» داخل بطاقة الملخص.
/// - الوسم على اليمين، المبلغ على اليسار (مثل تطبيق كناش).
/// - المبلغ نفسه يستخدم LTR لأن الرقم والرمز مكتوبان بالأرقام اللاتينية.
class _SummaryMetricRow extends StatelessWidget {
  const _SummaryMetricRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
