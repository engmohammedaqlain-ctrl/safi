import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../sales/models/cashbook_entry.dart';
import '../../sales/providers/cashbook_ui_provider.dart';
import '../data/financial_account_model.dart';
import '../providers/accounts_provider.dart';

// ════════════════════════════════════════════════════════════════
//  تفاصيل حركة الصافي — تصميم سلس مطابق لطابع التطبيق
// ════════════════════════════════════════════════════════════════
class CashbookEntryDetailScreen extends ConsumerWidget {
  const CashbookEntryDetailScreen({super.key, required this.entry});

  final CashbookEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(cashbookEntriesProvider);
    final live = entries.firstWhere(
      (e) => e.id == entry.id,
      orElse: () => entry,
    );

    final accounts = ref.watch(accountsProvider);
    String? accName;
    IconData accIcon = LucideIcons.wallet;
    for (final a in accounts) {
      if (a.id == live.accountId) {
        accName = a.name;
        accIcon = a.type.icon;
        break;
      }
    }

    if (live.isDeleted) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'تفاصيل المعاملة',
              style: TextStyle(
                color: AppColors.primary,
                fontFamily: AppFonts.family,
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
          ),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'تم حذف هذه الحركة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final isIncome = live.isIncome;
    final accent = isIncome ? AppColors.flowIn : AppColors.warning;
    final typeLabel = isIncome ? 'دخل' : 'مصروف';
    final sign = isIncome ? '+' : '−';
    final amt = formatShekelAmount(live.amount);

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
            icon: const Icon(
              LucideIcons.arrowRight,
              color: AppColors.primary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'تفاصيل المعاملة',
            style: TextStyle(
              color: AppColors.primary,
              fontFamily: AppFonts.family,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // ── بطاقة المبلغ المركزية ──
            _AmountHero(
              typeLabel: typeLabel,
              amount: '$sign$amt',
              accent: accent,
              when: _formatWhen(live.date),
              isIncome: isIncome,
            ),
            const SizedBox(height: 22),

            // ── معلومات المعاملة ──
            _InfoSection(
              rows: [
                if (accName != null)
                  _RowData(
                    icon: accIcon,
                    label: 'المحفظة',
                    value: accName,
                  ),
                if (live.category != null && live.category!.isNotEmpty)
                  _RowData(
                    icon: LucideIcons.tag,
                    label: 'التصنيف',
                    value: live.category!,
                  ),
                if (live.title.isNotEmpty)
                  _RowData(
                    icon: isIncome
                        ? LucideIcons.trendingUp
                        : LucideIcons.trendingDown,
                    label: 'البيان',
                    value: live.title,
                  ),
                if (live.note.isNotEmpty && live.note != live.title)
                  _RowData(
                    icon: LucideIcons.fileText,
                    label: 'ملاحظة',
                    value: live.note,
                  ),
              ],
            ),

            // ── المرفق ──
            if (!kIsWeb &&
                live.imagePath != null &&
                live.imagePath!.isNotEmpty) ...[
              const SizedBox(height: 18),
              _SectionTitle('المرفق'),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(live.imagePath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 26),

            // ── أزرار الإجراءات ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickAction(
                  icon: LucideIcons.share2,
                  label: 'مشاركة',
                  onTap: () => _share(context, live, accName),
                ),
                _QuickAction(
                  icon: LucideIcons.edit2,
                  label: 'تعديل',
                  onTap: () =>
                      _openEditSheet(context, ref, live, accounts),
                ),
                _QuickAction(
                  icon: LucideIcons.trash2,
                  label: 'حذف',
                  onTap: () => _confirmDelete(context, ref, live),
                  danger: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── مشاركة ──
  void _share(
    BuildContext context,
    CashbookEntry e,
    String? accName,
  ) {
    final lines = <String>[
      e.isIncome ? '📥 دخل' : '📤 مصروف',
      'المبلغ: ${e.isIncome ? '+' : '−'}${formatShekelAmount(e.amount)} ₪',
      if (accName != null) 'المحفظة: $accName',
      if (e.category != null && e.category!.isNotEmpty)
        'التصنيف: ${e.category}',
      if (e.title.isNotEmpty) 'البيان: ${e.title}',
      if (e.note.isNotEmpty && e.note != e.title) 'ملاحظة: ${e.note}',
      'التاريخ: ${_formatWhen(e.date)}',
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    showAppSnackBar(context, 'تم نسخ تفاصيل المعاملة');
  }

  // ── تعديل ──
  void _openEditSheet(
    BuildContext context,
    WidgetRef ref,
    CashbookEntry e,
    List<FinancialAccount> accounts,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(entry: e, accounts: accounts, ref: ref),
    );
  }

  // ── حذف ──
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CashbookEntry e,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'حذف المعاملة؟',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'سيتم حذف الحركة نهائياً من الصافي.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFE8E6),
                foregroundColor: const Color(0xFFC62828),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'حذف',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      ref.read(cashbookEntriesProvider.notifier).removeById(e.id);
      if (context.mounted) {
        Navigator.pop(context);
        showAppSnackBar(context, 'تم حذف المعاملة');
      }
    }
  }
}

String _formatWhen(DateTime d) {
  const months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}  ·  '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ════════════════════════════════════════════════════════════════
//  بطاقة المبلغ — مركزية، نظيفة، بدون بطاقات داخلية
// ════════════════════════════════════════════════════════════════
class _AmountHero extends StatelessWidget {
  const _AmountHero({
    required this.typeLabel,
    required this.amount,
    required this.accent,
    required this.when,
    required this.isIncome,
  });

  final String typeLabel;
  final String amount;
  final Color accent;
  final String when;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? LucideIcons.trendingUp : LucideIcons.trendingDown,
              color: accent,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            typeLabel,
            style: TextStyle(
              fontFamily: AppFonts.family,
              color: accent.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          // المبلغ في سطر واحد LTR
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    amount,
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      color: accent,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₪',
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      color: accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            when,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  قسم المعلومات
// ════════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 2),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppFonts.family,
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEBF2)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF3F0F7),
                ),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

// ── سطر معلومة بنمط صفحة الديون ──
class _RowData extends StatelessWidget {
  const _RowData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  زر إجراء سريع — مشابه لـ _QuickCircle في صفحة الدين
// ════════════════════════════════════════════════════════════════
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: danger ? AppColors.error : Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  ورقة التعديل
// ════════════════════════════════════════════════════════════════
class _EditSheet extends ConsumerStatefulWidget {
  const _EditSheet({
    required this.entry,
    required this.accounts,
    required this.ref,
  });

  final CashbookEntry entry;
  final List<FinancialAccount> accounts;
  final WidgetRef ref;

  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  late TextEditingController _noteCtrl;
  late TextEditingController _catCtrl;
  late DateTime _date;
  late String? _accountId;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.entry.note);
    _catCtrl = TextEditingController(text: widget.entry.category ?? '');
    _date = widget.entry.date;
    _accountId = widget.entry.accountId;
    _imagePath = widget.entry.imagePath;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final note = _noteCtrl.text.trim();
    final cat = _catCtrl.text.trim();
    final updated = CashbookEntry(
      id: widget.entry.id,
      title: note.isEmpty ? widget.entry.title : note,
      amount: widget.entry.amount,
      isIncome: widget.entry.isIncome,
      date: _date,
      note: note,
      accountId: _accountId ?? widget.entry.accountId,
      category: cat.isEmpty ? null : cat,
      imagePath: _imagePath,
    );
    widget.ref.read(cashbookEntriesProvider.notifier).update(updated);
    Navigator.pop(context);
    showAppSnackBar(context, 'تم حفظ التعديلات');
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 88,
    );
    if (x != null) setState(() => _imagePath = x.path);
  }

  void _pickDate() {
    AppTheme.showAppDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    ).then((d) {
      if (d != null) setState(() => _date = d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      margin: const EdgeInsets.only(top: 64),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + keyboard),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'تعديل المعاملة',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: AppFonts.family,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              _SoftInputBox(
                icon: LucideIcons.fileText,
                child: TextField(
                  controller: _noteCtrl,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'ملاحظة / بيان...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _SoftInputBox(
                icon: LucideIcons.tag,
                child: TextField(
                  controller: _catCtrl,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    hintText: 'التصنيف (اختياري)',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _SoftTapBox(
                icon: LucideIcons.calendar,
                label:
                    '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                onTap: _pickDate,
              ),

              if (widget.accounts.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(right: 4, bottom: 8),
                  child: Text(
                    'المحفظة',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: AppFonts.family,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      for (final a in widget.accounts)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 2),
                          child: _WalletPill(
                            name: a.name,
                            icon: a.type.icon,
                            selected: a.id == _accountId,
                            onTap: () => setState(() => _accountId = a.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),
              _SoftTapBox(
                icon: LucideIcons.camera,
                label:
                    _imagePath == null ? 'إضافة صورة' : 'تغيير الصورة',
                onTap: _pickImage,
              ),
              if (_imagePath != null && !kIsWeb) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(_imagePath!),
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],

              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: Color(0xFFE0DCE8)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'حفظ',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
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

class _SoftInputBox extends StatelessWidget {
  const _SoftInputBox({required this.icon, required this.child});
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SoftTapBox extends StatelessWidget {
  const _SoftTapBox({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outlineSoft),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Text(
                label,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
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

class _WalletPill extends StatelessWidget {
  const _WalletPill({
    required this.name,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineSoft,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: AppFonts.family,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color:
                      selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
