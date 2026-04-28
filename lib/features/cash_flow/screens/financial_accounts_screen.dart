import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:safi/core/router/app_page_route.dart';

import '../../../core/router/main_shell.dart' show hideBalanceProvider;
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../data/financial_account_model.dart';
import '../providers/accounts_provider.dart';
import 'wallet_detail_screen.dart';

/// شاشة المحافظ والبنوك — نفس ثيم دفتر الديون بالضبط
class FinancialAccountsScreen extends ConsumerWidget {
  const FinancialAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final hidden = ref.watch(hideBalanceProvider);
    final total = accounts.fold<double>(0, (s, a) => s + a.balance);
    final highest = accounts.isEmpty
        ? 0.0
        : accounts.map((a) => a.balance).reduce((a, b) => a > b ? a : b);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'المحافظ والبنوك',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ── بطاقة الملخص (نفس قالب بطاقة دفتر الديون) ──
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
                  // يمين: عناصر القياس (مثل أخذت/أعطيت في الديون)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryMetricRow(
                        label: 'الإجمالي',
                        value: hidden
                            ? '****'
                            : '₪ ${formatShekelAmount(total)}',
                        valueColor: Colors.green,
                      ),
                      const SizedBox(height: 6),
                      _SummaryMetricRow(
                        label: 'أعلى رصيد',
                        value: hidden
                            ? '****'
                            : '₪ ${formatShekelAmount(highest)}',
                        valueColor: AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'المحافظ: ${accounts.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  // يسار: أيقونات الإجراءات (مثل دفتر الديون)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionButton(
                        icon: LucideIcons.fileText,
                        label: 'تقرير عام',
                        onTap: () {
                          showAppSnackBar(context, 'تقرير المحافظ — قريباً');
                        },
                      ),
                      const SizedBox(width: 12),
                      _ActionButton(
                        icon: LucideIcons.barChart2,
                        label: 'إحصائيات',
                        onTap: () {
                          showAppSnackBar(context, 'إحصائيات المحافظ — قريباً');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── عنوان «المحافظ (N)» ──
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'المحافظ (${accounts.length})',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── القائمة ──
            if (accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Center(
                  child: Text(
                    'لا توجد محافظ بعد',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ...accounts.map(
              (a) => _AccountTile(
                account: a,
                hidden: hidden,
                onTap: () => Navigator.push<void>(
                  context,
                  AppPageRoute<void>(
                    builder: (_) => WalletDetailScreen(accountId: a.id),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push<void>(
            context,
            AppPageRoute<void>(
              builder: (_) => const AccountFormScreen(),
            ),
          ),
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: const Icon(LucideIcons.plus, color: Colors.white),
          label: const Text(
            'إضافة محفظة',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  بطاقة محفظة في القائمة — مطابقة لصف العميل في دفتر الديون
// ════════════════════════════════════════════════════════════════
class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.hidden,
    required this.onTap,
  });

  final FinancialAccount account;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amountStr = hidden
        ? '****'
        : '₪ ${formatShekelAmount(account.balance)}';
    final subtitle = _subtitle(account);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // يمين: أيقونة + الاسم
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
                  child: Icon(
                    account.type.icon,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // يسار: المبلغ
            Text(
              amountStr,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(FinancialAccount a) {
    if (a.accountOwner != null && a.accountOwner!.isNotEmpty) {
      return a.accountOwner!;
    }
    if (a.accountNumber != null && a.accountNumber!.isNotEmpty) {
      return a.accountNumber!;
    }
    return '';
  }
}

// ════════════════════════════════════════════════════════════════
//  ودجات مشتركة مأخوذة من قالب دفتر الديون
// ════════════════════════════════════════════════════════════════
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
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ],
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

// ════════════════════════════════════════════════════════════════
//  صفحة إضافة/تعديل محفظة — نفس ثيم «إضافة عميل»
// ════════════════════════════════════════════════════════════════
class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.existingAccount});

  final FinancialAccount? existingAccount;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _number;
  late final TextEditingController _owner;
  late final TextEditingController _balance;
  AccountType _type = AccountType.wallet;

  @override
  void initState() {
    super.initState();
    final acc = widget.existingAccount;
    _name = TextEditingController(text: acc?.name ?? '');
    _number = TextEditingController(text: acc?.accountNumber ?? '');
    _owner = TextEditingController(text: acc?.accountOwner ?? '');
    _balance = TextEditingController(
      text: acc == null || acc.balance == 0
          ? ''
          : (acc.balance == acc.balance.roundToDouble()
              ? acc.balance.toStringAsFixed(0)
              : acc.balance.toStringAsFixed(2)),
    );
    _type = acc?.type ?? AccountType.wallet;
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _owner.dispose();
    _balance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingAccount != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            isEdit ? 'تعديل المحفظة' : 'إضافة محفظة',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  children: [
                    _SectionLabel('النوع'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final t in AccountType.values) ...[
                          Expanded(
                            child: _TypeChip(
                              type: t,
                              selected: _type == t,
                              onTap: () => setState(() => _type = t),
                            ),
                          ),
                          if (t != AccountType.values.last)
                            const SizedBox(width: 10),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('اسم المحفظة'),
                    const SizedBox(height: 10),
                    _SoftField(
                      controller: _name,
                      hint: 'مثال: بنك فلسطين / جوال بي / الدرج الرئيسي',
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel('رقم الحساب أو المحفظة (اختياري)'),
                    const SizedBox(height: 10),
                    _SoftField(
                      controller: _number,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: false,
                        decimal: false,
                      ),
                      ltr: true,
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel('اسم صاحب الحساب (اختياري)'),
                    const SizedBox(height: 10),
                    _SoftField(controller: _owner),
                    const SizedBox(height: 18),
                    _SectionLabel('الرصيد الحالي'),
                    const SizedBox(height: 10),
                    _SoftField(
                      controller: _balance,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      suffix: '₪',
                      ltr: true,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _save,
                    child: Text(
                      isEdit ? 'حفظ التعديلات' : 'إضافة المحفظة',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppSnackBar(
        context,
        'الرجاء إدخال اسم المحفظة',
        backgroundColor: Colors.red,
      );
      return;
    }
    final balance = double.tryParse(_balance.text.trim()) ??
        widget.existingAccount?.balance ??
        0;

    final acc = FinancialAccount(
      id: widget.existingAccount?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: _type,
      accountNumber: _number.text.trim().isEmpty ? null : _number.text.trim(),
      accountOwner: _owner.text.trim().isEmpty ? null : _owner.text.trim(),
      balance: balance,
    );

    if (widget.existingAccount == null) {
      ref.read(accountsProvider.notifier).addAccount(acc);
    } else {
      ref.read(accountsProvider.notifier).updateAccount(acc);
    }
    Navigator.pop(context);
  }
}

// ════════════════════════════════════════════════════════════════
//  ودجات صفحة الإضافة الناعمة
// ════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SoftField extends StatelessWidget {
  const _SoftField({
    required this.controller,
    this.hint,
    this.keyboardType,
    this.suffix,
    this.ltr = false,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final String? suffix;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: ltr ? TextAlign.left : TextAlign.right,
      textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        suffixText: suffix,
        suffixStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: AppColors.primary.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
    if (ltr) {
      return Directionality(textDirection: TextDirection.ltr, child: field);
    }
    return field;
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final AccountType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : Colors.white;
    final fg = selected ? Colors.white : AppColors.primary;
    final border = selected
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.20);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            border: Border.all(color: border, width: selected ? 0 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, size: 22, color: fg),
              const SizedBox(height: 6),
              Text(
                type.label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
