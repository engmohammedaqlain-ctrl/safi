import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safi_button.dart';
import '../data/financial_account_model.dart';
import '../providers/accounts_provider.dart';

class FinancialAccountsScreen extends ConsumerWidget {
  const FinancialAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المحافظ والبنوك')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'إدارة حساباتك المالية حيث تتدفق الأموال الواردة وتخرج النفقات.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SafiButton(
                label: 'إضافة',
                icon: LucideIcons.plus,
                isExpanded: false,
                onPressed: () => _showAddAccountSheet(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (accounts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'لا توجد حسابات مضافة.',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            )
          else
            GlassCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: accounts.length,
                separatorBuilder: (context, _) =>
                    const Divider(height: 1, indent: 52),
                itemBuilder: (context, index) {
                  final acc = accounts[index];
                  return Dismissible(
                    key: Key(acc.id),
                    direction: DismissDirection.startToEnd,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: AppColors.error,
                      child: const Icon(
                        LucideIcons.trash2,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (_) {
                      ref.read(accountsProvider.notifier).deleteAccount(acc.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم حذف ${acc.name}')),
                      );
                    },
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppRadius.rmd,
                        ),
                        child: Icon(acc.type.icon, color: AppColors.primary),
                      ),
                      title: Text(acc.name, style: AppTextStyles.titleSmall),
                      subtitle:
                          acc.accountNumber != null || acc.accountOwner != null
                          ? Text(
                              [
                                if (acc.accountOwner != null) acc.accountOwner!,
                                if (acc.accountNumber != null)
                                  acc.accountNumber!,
                              ].join(' — '),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            )
                          : null,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₪ ${acc.balance}',
                            style: AppTextStyles.numberMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronLeft,
                            size: 14,
                            color: AppColors.textDisabled,
                          ),
                        ],
                      ),
                      onTap: () => _showEditAccountSheet(context, ref, acc),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AccountFormSheet(
        onSave: (acc) => ref.read(accountsProvider.notifier).addAccount(acc),
      ),
    );
  }

  void _showEditAccountSheet(
    BuildContext context,
    WidgetRef ref,
    FinancialAccount existing,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AccountFormSheet(
        existingAccount: existing,
        onSave: (acc) => ref.read(accountsProvider.notifier).updateAccount(acc),
        onDelete: () {
          ref.read(accountsProvider.notifier).deleteAccount(existing.id);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _AccountFormSheet extends StatefulWidget {
  const _AccountFormSheet({
    this.existingAccount,
    required this.onSave,
    this.onDelete,
  });

  final FinancialAccount? existingAccount;
  final ValueChanged<FinancialAccount> onSave;
  final VoidCallback? onDelete;

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _owner = TextEditingController();
  AccountType _type = AccountType.wallet;

  @override
  void initState() {
    super.initState();
    final acc = widget.existingAccount;
    if (acc != null) {
      _name.text = acc.name;
      _number.text = acc.accountNumber ?? '';
      _owner.text = acc.accountOwner ?? '';
      _type = acc.type;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _owner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existingAccount == null ? 'إضافة حساب جديد' : 'تعديل الحساب',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 20),
          SegmentedButton<AccountType>(
            segments: [
              ButtonSegment(
                value: AccountType.wallet,
                label: const Text('محفظة'),
                icon: Icon(AccountType.wallet.icon),
              ),
              ButtonSegment(
                value: AccountType.bank,
                label: const Text('بنك'),
                icon: Icon(AccountType.bank.icon),
              ),
              ButtonSegment(
                value: AccountType.cash,
                label: const Text('كاش'),
                icon: Icon(AccountType.cash.icon),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'اسم الحساب (مثال: بنك فلسطين)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _number,
            decoration: const InputDecoration(
              labelText: 'رقم الحساب أو المحفظة',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _owner,
            decoration: const InputDecoration(
              labelText: 'اسم صاحب الحساب (اختياري)',
            ),
          ),
          const SizedBox(height: 24),
          SafiButton(
            label: 'حفظ الحساب',
            icon: LucideIcons.save,
            onPressed: () {
              if (_name.text.trim().isEmpty) return;
              widget.onSave(
                FinancialAccount(
                  id:
                      widget.existingAccount?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _name.text.trim(),
                  type: _type,
                  accountNumber: _number.text.trim(),
                  accountOwner: _owner.text.trim(),
                  balance: widget.existingAccount?.balance ?? 0.0,
                ),
              );
              Navigator.pop(context);
            },
          ),
          if (widget.onDelete != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // Delete confirmation could be added here
                widget.onDelete!();
              },
              icon: const Icon(LucideIcons.trash2),
              label: const Text('حذف الحساب'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}
