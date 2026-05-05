import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/reports_style_shell.dart';
import '../providers/debts_ui_provider.dart';
import '../../../core/services/notification_service.dart';

class DebtCollectionScreen extends ConsumerStatefulWidget {
  const DebtCollectionScreen({super.key, this.suppliersOnly = false});

  final bool suppliersOnly;

  @override
  ConsumerState<DebtCollectionScreen> createState() =>
      _DebtCollectionScreenState();
}

class _DebtCollectionScreenState extends ConsumerState<DebtCollectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  String _formatDate(DateTime d) => '${d.year}/${d.month}/${d.day}';

  String _formatTimeRemaining(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.isNegative) {
      final days = diff.inDays.abs();
      if (days == 0) return 'متأخر منذ اليوم';
      return 'متأخر $days يوم';
    }
    final days = diff.inDays;
    if (days == 0) {
      final hours = diff.inHours;
      if (hours == 0) return 'متبقي ${diff.inMinutes} د';
      return 'متبقي $hours س';
    }
    return 'متبقي $days يوم';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(DebtorUi debtor) async {
    final current = debtor.dueDate ?? DateTime.now();
    final pickedDate = await AppTheme.showAppDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current),
        helpText: 'اختر وقت السداد (اختياري)',
        cancelText: 'تخطي',
        confirmText: 'تأكيد',
      );

      DateTime finalDateTime = pickedDate;
      if (pickedTime != null) {
        finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }

      ref
          .read(debtorsUiProvider.notifier)
          .updateCustomerDueDate(debtor.id, finalDateTime);

      final amt =
          double.tryParse(debtor.amount.replaceAll('₪', '').trim()) ?? 0;
      await NotificationService().scheduleDebtReminder(
        debtor.id,
        debtor.name,
        amt,
        finalDateTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديد موعد السداد بنجاح'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _openMessageSheet(BuildContext context, DebtorUi debtor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessageSheet(debtor: debtor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDebtors = ref.watch(debtorsUiProvider);
    final scopeSuppliers = widget.suppliersOnly;

    final debtorsWithDebt = allDebtors.where((d) {
      if (d.isSupplier != scopeSuppliers) return false;
      final amt = double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
      return amt > 0;
    }).toList();

    final searchHint =
        scopeSuppliers ? 'ابحث عن بائع جملة...' : 'ابحث عن زبون...';

    final filtered = debtorsWithDebt.where((d) {
      if (_query.isEmpty) return true;
      return d.name.toLowerCase().contains(_query.toLowerCase()) ||
          d.phone.contains(_query);
    }).toList();

    filtered.sort((a, b) {
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;
      final amtA = double.tryParse(a.amount.replaceAll('₪', '').trim()) ?? 0;
      final amtB = double.tryParse(b.amount.replaceAll('₪', '').trim()) ?? 0;
      return amtB.compareTo(amtA);
    });

    final overdueCount = filtered
        .where(
            (d) => d.dueDate != null && d.dueDate!.isBefore(DateTime.now()))
        .length;

    double totalDebt = 0;
    for (var d in filtered) {
      totalDebt += double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
    }

    return ReportsStylePage(
      title: 'تجميع الديون',
      subtitle: scopeSuppliers
          ? 'متابعة مستحقات بائعي الجملة'
          : 'متابعة وتحصيل مستحقات الزبائن',
      child: Column(
        children: [
          // ── Summary chips ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _StatChip(
                  label: 'الإجمالي',
                  value: '₪${totalDebt.toStringAsFixed(0)}',
                  icon: LucideIcons.coins,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'الحالات',
                  value: '${filtered.length}',
                  icon: LucideIcons.users,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'متأخرات',
                  value: '$overdueCount',
                  icon: LucideIcons.alertTriangle,
                  color: overdueCount > 0 ? AppColors.flowOut : AppColors.textMuted,
                ),
              ],
            ),
          ),

          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
                prefixIcon: const Icon(LucideIcons.search,
                    color: AppColors.textMuted, size: 19),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // ── List ──
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(suppliersOnly: widget.suppliersOnly)
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final d = filtered[index];
                      return _DebtCard(
                        debtor: d,
                        onSelectDate: () => _selectDueDate(d),
                        onNotify: () => _openMessageSheet(context, d),
                        formatDate: _formatDate,
                        formatTimeRemaining: _formatTimeRemaining,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Stat Chip — بطاقة إحصائية صغيرة في الأعلى
// ═══════════════════════════════════════════════════════════════
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: ReportsStyleSurfaces.whiteCardDecoration(radius: 16),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.numberMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Empty State
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.suppliersOnly});
  final bool suppliersOnly;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            suppliersOnly ? LucideIcons.truck : LucideIcons.users,
            size: 56,
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            suppliersOnly ? 'لا يوجد بائعي جملة مدينين' : 'لا يوجد زبائن مدينين',
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'جميع الديون محصلة',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Debt Card — بطاقة دين بسيطة ومتسقة مع الثيم
// ═══════════════════════════════════════════════════════════════
class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.debtor,
    required this.onSelectDate,
    required this.onNotify,
    required this.formatDate,
    required this.formatTimeRemaining,
  });

  final DebtorUi debtor;
  final VoidCallback onSelectDate;
  final VoidCallback onNotify;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTimeRemaining;

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        debtor.dueDate != null && debtor.dueDate!.isBefore(DateTime.now());
    final avatar =
        debtor.name.trim().isNotEmpty ? debtor.name.trim()[0] : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: ReportsStyleSurfaces.whiteCardDecoration(radius: 18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Row: avatar + info + amount ──
            Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    avatar,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debtor.name,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (debtor.phone.trim().isNotEmpty)
                        Text(
                          debtor.phone,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // Amount + overdue badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₪${debtor.amount}',
                      style: AppTextStyles.numberMedium.copyWith(
                        color: AppColors.flowOut,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isOverdue)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'متأخر',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.error,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // ── Due date row ──
            if (debtor.dueDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? AppColors.errorLight
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color:
                          isOverdue ? AppColors.error : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatDate(debtor.dueDate!),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isOverdue
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatTimeRemaining(debtor.dueDate!),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isOverdue
                            ? AppColors.error
                            : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Actions ──
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    onTap: onSelectDate,
                    icon: LucideIcons.calendarPlus,
                    label: 'موعد السداد',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    onTap: onNotify,
                    icon: LucideIcons.send,
                    label: 'إرسال تذكير',
                    color: const Color(0xFF25D366),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Action Button
// ═══════════════════════════════════════════════════════════════
class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Message Sheet — قالب رسالة تذكير جاهز + واتساب / SMS
// ═══════════════════════════════════════════════════════════════
class _MessageSheet extends StatefulWidget {
  const _MessageSheet({required this.debtor});
  final DebtorUi debtor;

  @override
  State<_MessageSheet> createState() => _MessageSheetState();
}

class _MessageSheetState extends State<_MessageSheet> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: _buildTemplate());
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _buildTemplate() {
    final amount = widget.debtor.amount.replaceAll('₪', '').trim();
    final dueDate = widget.debtor.dueDate;
    final buf = StringBuffer();
    buf.writeln('السلام عليكم ورحمة الله وبركاته');
    buf.writeln();
    buf.writeln('نود تذكيركم بالمبلغ المستحق وقدره $amount شيكل.');
    if (dueDate != null) {
      buf.writeln(
          'موعد السداد المتفق عليه: ${dueDate.year}/${dueDate.month}/${dueDate.day}.');
    }
    buf.writeln();
    buf.writeln('نرجو منكم التكرم بتسوية المبلغ في أقرب وقت ممكن.');
    buf.writeln('شكراً لتعاونكم.');
    return buf.toString().trim();
  }

  String? _cleanPhone() {
    String phone = widget.debtor.phone.trim();
    if (phone.isEmpty) return null;
    
    // Remove all non-digits
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    // Handle local Palestinian/Israeli numbers if country code is missing
    // 05x -> 9705x (or 9725x depending on context, using 970 as default for 'safi')
    if (digits.startsWith('05') && digits.length == 10) {
      digits = '970${digits.substring(1)}';
    } else if (digits.startsWith('5') && digits.length == 9) {
      digits = '970$digits';
    }
    
    return digits;
  }

  Future<void> _sendWhatsApp() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final phone = _cleanPhone();
    if (phone == null) {
      _showError('رقم الهاتف غير مسجل أو غير صالح');
      return;
    }
    final url = Uri.parse(
        'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(text)}');
    try {
      // Use LaunchMode.externalApplication to ensure it opens the app directly
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showError('تطبيق واتساب غير مثبت أو لا يمكن فتحه');
      }
    } catch (_) {
      _showError('حدث خطأ أثناء محاولة فتح واتساب');
    }
  }

  Future<void> _sendSms() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final phone = _cleanPhone();
    if (phone == null) {
      _showError('رقم الهاتف غير مسجل أو غير صالح');
      return;
    }
    final url =
        Uri.parse('sms:$phone?body=${Uri.encodeComponent(text)}');
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showError('تعذر فتح تطبيق الرسائل');
      }
    } catch (_) {
      _showError('حدث خطأ أثناء محاولة فتح تطبيق الرسائل');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.messageSquare,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رسالة تذكير',
                      style: AppTextStyles.titleSmall
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${widget.debtor.name} • ₪${widget.debtor.amount}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x, size: 18),
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Text field
          TextField(
            controller: _messageController,
            maxLines: 5,
            style: AppTextStyles.bodyMedium,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'نص رسالة التذكير...',
              hintStyle:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 18),

          // Send buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _sendWhatsApp,
                  icon: const Icon(LucideIcons.messageCircle, size: 18),
                  label: const Text('واتساب',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _sendSms,
                  icon: const Icon(LucideIcons.smartphone, size: 18),
                  label: const Text('SMS',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
