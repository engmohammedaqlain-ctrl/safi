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
    final all = ref.watch(debtorsUiProvider);
    final my = ref.watch(debtMyNumbersProvider);
    final list = filterDebtors(all, _q);
    final hidden = ref.watch(hideBalanceProvider);

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _ActionButton(
                      icon: LucideIcons.bell, 
                      label: 'تحصيل الديون',
                      onTap: () => Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => const RecordPaymentScreen())),
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: LucideIcons.barChart2, 
                      label: 'التقارير',
                      onTap: () {},
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('أخذت', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    Text(hidden ? '****' : my.totalReceivedLabel, style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('أعطيت', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    Text(hidden ? '****' : my.totalGaveLabel, style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('متأخر: ${hidden ? '**' : my.overdueCount}', style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Text('العملاء: ${hidden ? '**' : my.debtorCount}', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
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
                'العملاء (${list.length})',
                style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _FilterIconButton(icon: LucideIcons.fileText),
              const SizedBox(width: 8),
              _FilterIconButton(icon: LucideIcons.slidersHorizontal),
              const SizedBox(width: 8),
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
                    decoration: InputDecoration(
                      hintText: 'البحث',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(LucideIcons.search, color: Colors.grey.shade500, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Text('لا يوجد عملاء', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ),
            ),
          ...list.map((debtor) {
            final amountText = debtor.amount.replaceAll('₪', '').trim();
            final isRed = !amountText.startsWith('-') && amountText != '0.0' && amountText != '0';
            final color = isRed ? Colors.red : Colors.green;
            final label = isRed ? 'أعطيت' : 'أخذت';
            final displayAmount = amountText.startsWith('-') ? amountText.substring(1) : amountText;
            final avatarStr = debtor.name.startsWith('+') ? '+' : (debtor.name.isNotEmpty ? debtor.name.split(' ').first[0] : '؟');

            return InkWell(
              onTap: () {
                Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => CustomerDetailScreen(debtor: debtor)));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hidden ? '****' : '₪ $displayAmount', 
                          textDirection: TextDirection.ltr,
                          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(debtor.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(debtor.status, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(width: 12),
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
                            style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold),
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
          Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => const AddCustomerScreen()));
        },
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(LucideIcons.userPlus, color: Colors.white),
        label: const Text('إضافة عميل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 18, color: isSelected ? AppColors.primary : Colors.grey.shade500),
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

  const _ActionButton({required this.icon, required this.label, required this.onTap});

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
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
