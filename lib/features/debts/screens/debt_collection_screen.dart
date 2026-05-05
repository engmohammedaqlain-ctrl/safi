import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/vault_subpage_scaffold.dart';
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

  String _formatTime(DateTime date) {
    final h = date.hour;
    final m = date.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'م' : 'ص';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $ampm';
  }

  String _formatTimeRemaining(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.isNegative) {
      final days = diff.inDays.abs();
      if (days == 0) return 'متأخر منذ اليوم';
      return 'متأخر منذ $days يوم';
    } else {
      final days = diff.inDays;
      if (days == 0) {
        final hours = diff.inHours;
        if (hours == 0) {
          return 'متبقي ${diff.inMinutes} دقيقة';
        }
        return 'متبقي $hours ساعة';
      }
      return 'متبقي $days يوم';
    }
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

  void _openWhatsAppSheet(BuildContext context, DebtorUi debtor) {
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

    final searchHint = scopeSuppliers ? 'ابحث عن بائع جملة...' : 'ابحث عن زبون...';
    
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

    final overdueCount = filtered.where((d) => d.dueDate != null && d.dueDate!.isBefore(DateTime.now())).length;
    
    // Calculate total debt amount for filtered list
    double totalDebt = 0;
    for (var d in filtered) {
      totalDebt += double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
    }

    return VaultSubpageScaffold(
      title: 'تجميع الديون',
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
        ),
        child: Column(
          children: [
            // Header Summary
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    AppColors.background,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _SummaryTile(
                          label: 'إجمالي الديون',
                          value: '₪${totalDebt.toStringAsFixed(0)}',
                          icon: LucideIcons.wallet,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        _SummaryTile(
                          label: 'الحالات',
                          value: filtered.length.toString(),
                          icon: LucideIcons.users,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        _SummaryTile(
                          label: 'متأخرات',
                          value: overdueCount.toString(),
                          icon: LucideIcons.alertCircle,
                          color: AppColors.flowOut,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        hintText: searchHint,
                        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        suffixIcon: _query.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(suppliersOnly: widget.suppliersOnly)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final d = filtered[index];
                        return _DebtCollectionCard(
                          debtor: d,
                          onSelectDate: () => _selectDueDate(d),
                          onNotify: () => _openWhatsAppSheet(context, d),
                          formatTime: _formatTime,
                          formatTimeRemaining: _formatTimeRemaining,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
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
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.numberLarge.copyWith(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.suppliersOnly});
  final bool suppliersOnly;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              suppliersOnly ? LucideIcons.truck : LucideIcons.users,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            suppliersOnly ? 'لا يوجد بائعي جملة حالياً' : 'لا يوجد زبائن حالياً',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جميع الديون المسجلة محصلة بالكامل',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _DebtCollectionCard extends StatelessWidget {
  const _DebtCollectionCard({
    required this.debtor,
    required this.onSelectDate,
    required this.onNotify,
    required this.formatTime,
    required this.formatTimeRemaining,
  });

  final DebtorUi debtor;
  final VoidCallback onSelectDate;
  final VoidCallback onNotify;
  final String Function(DateTime) formatTime;
  final String Function(DateTime) formatTimeRemaining;

  @override
  Widget build(BuildContext context) {
    final isOverdue = debtor.dueDate != null && debtor.dueDate!.isBefore(DateTime.now());
    final statusColor = isOverdue ? AppColors.flowOut : (debtor.dueDate == null ? AppColors.textMuted : AppColors.flowIn);
    
    final avatarChar = debtor.name.trim().isNotEmpty ? debtor.name.trim()[0] : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Status Indicator Line
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 8),
                      // Avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.primary.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          avatarChar,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              debtor.name,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(LucideIcons.phone, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  debtor.phone,
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₪${debtor.amount}',
                            style: AppTextStyles.numberMedium.copyWith(
                              color: AppColors.flowOut,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (isOverdue)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'متأخر',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Due Date Info Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            debtor.dueDate != null ? LucideIcons.calendarClock : LucideIcons.calendarDays,
                            size: 16,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                debtor.dueDate != null ? 'موعد السداد المتوقع' : 'موعد السداد',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                debtor.dueDate != null 
                                  ? '${debtor.dueDate!.year}/${debtor.dueDate!.month}/${debtor.dueDate!.day} - ${formatTime(debtor.dueDate!)}'
                                  : 'لم يتم تحديد موعد بعد',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: debtor.dueDate != null ? statusColor : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (debtor.dueDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              formatTimeRemaining(debtor.dueDate!),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: _CardActionButton(
                          onTap: onSelectDate,
                          icon: LucideIcons.calendarPlus,
                          label: 'تحديد موعد',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CardActionButton(
                          onTap: onNotify,
                          icon: LucideIcons.messageCircle,
                          label: 'إرسال تذكير',
                          color: const Color(0xFF25D366),
                          isWhatsApp: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
    this.isWhatsApp = false,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;
  final bool isWhatsApp;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
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
    );
  }
}


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
    _messageController = TextEditingController(text: _buildTemplateMessage());
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// بناء رسالة قالب جاهزة من بيانات المدين
  String _buildTemplateMessage() {
    final amount = widget.debtor.amount.replaceAll('₪', '').trim();
    final dueDate = widget.debtor.dueDate;

    final buffer = StringBuffer();
    buffer.writeln('السلام عليكم ورحمة الله وبركاته');
    buffer.writeln();
    buffer.writeln('نود تذكيركم بالمبلغ المستحق وقدره $amount شيكل.');
    if (dueDate != null) {
      buffer.writeln(
        'موعد السداد المتفق عليه: ${dueDate.year}/${dueDate.month}/${dueDate.day}.',
      );
    }
    buffer.writeln();
    buffer.writeln('نرجو منكم التكرم بتسوية المبلغ في أقرب وقت ممكن.');
    buffer.writeln('شكراً لتعاونكم.');

    return buffer.toString().trim();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final phone = widget.debtor.phone.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الهاتف غير مسجل')),
      );
      return;
    }

    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الهاتف غير صالح')),
      );
      return;
    }

    final url = Uri.parse(
      'whatsapp://send?phone=$digitsOnly&text=${Uri.encodeComponent(text)}',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تطبيق واتساب غير مثبت على جهازك')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء فتح واتساب')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.outlineSoft,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.aiGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.aiPurple.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مساعد الذكاء الاصطناعي',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'توليد رسالة تذكير احترافية لواتساب',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x, color: AppColors.textMuted, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'النص النهائي للمراجعة',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_messageController.text.isNotEmpty)
                Text(
                  'جاهز للإرسال',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            maxLines: 4,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'سيظهر النص المولد هنا، يمكنك التعديل عليه بكل سهولة...',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: AppColors.outlineSoft, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(18),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25D366).withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.send, size: 22),
                  const SizedBox(width: 12),
                  const Text(
                    'إرسال عبر واتساب الآن',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

