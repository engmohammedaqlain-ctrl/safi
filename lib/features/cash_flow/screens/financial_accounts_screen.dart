import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:safi/core/router/app_page_route.dart';

import '../../../core/router/main_shell.dart' show hideBalanceProvider;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/vault_branded_shell.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../data/financial_account_model.dart';
import '../providers/accounts_provider.dart';
import 'wallet_detail_screen.dart';

/// شاشة المحافظ والبنوك — إطار الخزينة وبطاقات بنكية كما في الأونبوردينغ
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

    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: VaultInsetPageShell(
        title: const Text(
          'المحافظ والبنوك',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 96 + bottomPad),
              children: [
                _WalletsOverviewPlasticCard(
                  accounts: accounts,
                  hidden: hidden,
                  total: total,
                  highest: highest,
                  onReport: () =>
                      showAppSnackBar(context, 'تقرير المحافظ — قريباً'),
                  onStats: () =>
                      showAppSnackBar(context, 'إحصائيات المحافظ — قريباً'),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Icon(
                      LucideIcons.creditCard,
                      size: 20,
                      color: AppColors.primary.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'محافظك (${accounts.length})',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (accounts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 28),
                    child: Center(
                      child: Text(
                        'لا توجد محافظ بعد.\nاضغط «إضافة محفظة» للبدء.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ...accounts.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WalletAccountCard(
                      account: a,
                      hidden: hidden,
                      onTap: () => Navigator.push<void>(
                        context,
                        AppPageRoute<void>(
                          builder: (_) =>
                              WalletDetailScreen(accountId: a.id),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            PositionedDirectional(
              bottom: 16 + bottomPad,
              end: 16,
              child: FloatingActionButton.extended(
                heroTag: 'financial_accounts_fab',
                onPressed: () => Navigator.push<void>(
                  context,
                  AppPageRoute<void>(
                    builder: (_) => const AccountFormScreen(),
                  ),
                ),
                backgroundColor: AppColors.primary,
                elevation: 3,
                highlightElevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                icon: const Icon(LucideIcons.plus, color: Colors.white),
                label: const Text(
                  'إضافة محفظة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة ملخص بلاستيكية — حبوب نوع + مبلغ + عدد المحافظ (شبيهة بمعاينة الأونبوردينغ).
class _WalletsOverviewPlasticCard extends StatelessWidget {
  const _WalletsOverviewPlasticCard({
    required this.accounts,
    required this.hidden,
    required this.total,
    required this.highest,
    required this.onReport,
    required this.onStats,
  });

  final List<FinancialAccount> accounts;
  final bool hidden;
  final double total;
  final double highest;
  final VoidCallback onReport;
  final VoidCallback onStats;

  static const List<Color> _gradientColors = [
    Color(0xFF9C27B0),
    Color(0xFF6A1B9A),
    Color(0xFF4A148C),
  ];

  static String _countPhrase(int n) {
    if (n == 0) return 'لا يوجد';
    if (n == 1) return 'محفظة واحدة';
    return '$n محافظ';
  }

  @override
  Widget build(BuildContext context) {
    var cashSum = 0.0,
        bankSum = 0.0,
        walletSum = 0.0;
    var cashN = 0, bankN = 0, walletN = 0;
    for (final a in accounts) {
      switch (a.type) {
        case AccountType.cash:
          cashSum += a.balance;
          cashN++;
          break;
        case AccountType.bank:
          bankSum += a.balance;
          bankN++;
          break;
        case AccountType.wallet:
          walletSum += a.balance;
          walletN++;
          break;
      }
    }

    final cap = AppTextStyles.labelSmall.copyWith(
      color: Colors.white.withValues(alpha: 0.82),
      fontSize: 10,
      height: 1.2,
    );
    final val = AppTextStyles.labelSmall.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 11,
      height: 1.2,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: _gradientColors.last.withValues(alpha: 0.42),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -16,
            top: -18,
            child: Icon(
              LucideIcons.circle,
              size: 120,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF0E6D2),
                          Color(0xFFC9A66B),
                          Color(0xFF9A7847),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: AppRadius.rfull,
                    ),
                    child: Text(
                      'الصافي',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _GlassIconButton(
                    icon: LucideIcons.fileText,
                    onTap: onReport,
                  ),
                  const SizedBox(width: 8),
                  _GlassIconButton(
                    icon: LucideIcons.barChart2,
                    onTap: onStats,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _TypeMiniPill(
                              icon: LucideIcons.banknote,
                              label: 'كاش',
                              amountText: hidden
                                  ? '****'
                                  : '₪ ${formatShekelAmount(cashSum)}',
                              countPhrase: _countPhrase(cashN),
                              captionStyle: cap,
                              valueStyle: val,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _TypeMiniPill(
                              icon: LucideIcons.landmark,
                              label: 'بنك',
                              amountText: hidden
                                  ? '****'
                                  : '₪ ${formatShekelAmount(bankSum)}',
                              countPhrase: _countPhrase(bankN),
                              captionStyle: cap,
                              valueStyle: val,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _TypeMiniPill(
                              icon: LucideIcons.smartphone,
                              label: 'محفظة',
                              amountText: hidden
                                  ? '****'
                                  : '₪ ${formatShekelAmount(walletSum)}',
                              countPhrase: _countPhrase(walletN),
                              captionStyle: cap,
                              valueStyle: val,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('الرصيد الموحّد', style: cap.copyWith(fontSize: 11)),
                          Text(
                            hidden
                                ? '  ****'
                                : '  ₪ ${formatShekelAmount(total)}',
                            style: val.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'أعلى رصيد في محفظة واحدة',
                              style: cap.copyWith(fontSize: 9.5),
                            ),
                            Text(
                              hidden
                                  ? '  ****'
                                  : '  ₪ ${formatShekelAmount(highest)}',
                              style: val.copyWith(fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ملخص الأرصدة',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '••••  ••••  ••••  ${accounts.length.toString().padLeft(4, '0')}',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: Colors.white,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.wallet,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.95),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _TypeMiniPill extends StatelessWidget {
  const _TypeMiniPill({
    required this.icon,
    required this.label,
    required this.amountText,
    required this.countPhrase,
    required this.captionStyle,
    required this.valueStyle,
  });

  final IconData icon;
  final String label;
  final String amountText;
  final String countPhrase;
  final TextStyle captionStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white.withValues(alpha: 0.88),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: captionStyle.copyWith(fontSize: 8.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            amountText,
            style: valueStyle.copyWith(fontSize: 9.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            countPhrase,
            style: captionStyle.copyWith(fontSize: 8),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  بطاقة محفظة — ظل وبُعد ملوّن حسب نوع الحساب (كاش / بنك / محفظة)
// ════════════════════════════════════════════════════════════════
class _WalletAccountCard extends StatelessWidget {
  const _WalletAccountCard({
    required this.account,
    required this.hidden,
    required this.onTap,
  });

  final FinancialAccount account;
  final bool hidden;
  final VoidCallback onTap;

  static Color _accent(AccountType t) {
    switch (t) {
      case AccountType.cash:
        return const Color(0xFF2E7D32);
      case AccountType.bank:
        return const Color(0xFF1565C0);
      case AccountType.wallet:
        return AppColors.primaryDark;
    }
  }

  /// نفس أسماء الحبوب في بطاقة الملخص — مختصرة لتجنّب الزحمة في البطاقة.
  static String _typeChipShort(AccountType t) {
    switch (t) {
      case AccountType.cash:
        return 'كاش';
      case AccountType.bank:
        return 'بنك';
      case AccountType.wallet:
        return 'محفظة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountStr = hidden
        ? '****'
        : '₪ ${formatShekelAmount(account.balance)}';
    final subtitle = _subtitle(account);
    final accent = _accent(account.type);

    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outlineSoft),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(17),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withValues(alpha: 0.14),
                                accent.withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            account.type.icon,
                            color: accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                account.name,
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _typeChipShort(account.type),
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        subtitle,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              amountStr,
                              textDirection: TextDirection.ltr,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.flowIn,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Icon(
                              LucideIcons.chevronLeft,
                              size: 18,
                              color: AppColors.textMuted.withValues(alpha: 0.65),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
              fontWeight: FontWeight.w600,
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
                      hint: 'مثال: بنك فلسطين / جوال بي / كاش',
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
                        fontWeight: FontWeight.w600,
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
        fontWeight: FontWeight.w600,
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
          fontWeight: FontWeight.w600,
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
