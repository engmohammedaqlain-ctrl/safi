import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/vault_subpage_scaffold.dart';
import '../providers/debts_ui_provider.dart';
import '../../ai_assistant/providers/ai_assistant_provider.dart';
import '../../../core/services/notification_service.dart';

class DebtCollectionScreen extends ConsumerStatefulWidget {
  const DebtCollectionScreen({super.key, this.suppliersOnly = false});

  /// عند `true` تُعرض فقط الموردون الذين عليهم دين لك؛ وإلا العملاء فقط.
  final bool suppliersOnly;

  @override
  ConsumerState<DebtCollectionScreen> createState() => _DebtCollectionScreenState();
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
      // Ask for time (optional)
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

      ref.read(debtorsUiProvider.notifier).updateCustomerDueDate(debtor.id, finalDateTime);
      
      final amt = double.tryParse(debtor.amount.replaceAll('₪', '').trim()) ?? 0;
      await NotificationService().scheduleDebtReminder(debtor.id, debtor.name, amt, finalDateTime);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديد موعد السداد بنجاح')),
        );
      }
    }
  }

  void _openWhatsAppSheet(BuildContext context, DebtorUi debtor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _WhatsAppSheet(debtor: debtor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDebtors = ref.watch(debtorsUiProvider);
    final scopeSuppliers = widget.suppliersOnly;
    // Filter debtors who owe us money (net amount > 0)
    final debtorsWithDebt = allDebtors.where((d) {
      if (d.isSupplier != scopeSuppliers) return false;
      final amt = double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
      return amt > 0;
    }).toList();

    final searchHint = scopeSuppliers ? 'ابحث عن مورد...' : 'ابحث عن عميل...';
    final emptyMessage = scopeSuppliers
        ? 'لا يوجد موردون عليهم ديون حالياً'
        : 'لا يوجد عملاء عليهم ديون حالياً';

    final filtered = debtorsWithDebt.where((d) {
      if (_query.isEmpty) return true;
      return d.name.toLowerCase().contains(_query.toLowerCase()) ||
          d.phone.contains(_query);
    }).toList();

    // Sort by due date (closest first), then by amount
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

    return VaultSubpageScaffold(
      title: 'تحصيل الديون',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(LucideIcons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      emptyMessage,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final d = filtered[index];
                      final isOverdue = d.dueDate != null && d.dueDate!.isBefore(DateTime.now());
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    d.name,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₪ ${d.amount}',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.flowOut,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (d.dueDate != null)
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.calendarClock,
                                    size: 16,
                                    color: isOverdue ? AppColors.flowOut : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'موعد السداد: ${d.dueDate!.year}/${d.dueDate!.month}/${d.dueDate!.day} ${_formatTime(d.dueDate!)}\n'
                                      '(${_formatTimeRemaining(d.dueDate!)})',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: isOverdue ? AppColors.flowOut : AppColors.textSecondary,
                                        fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _selectDueDate(d),
                                    icon: const Icon(LucideIcons.calendar, size: 18),
                                    label: const Text('الموعد'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openWhatsAppSheet(context, d),
                                    icon: const Icon(LucideIcons.messageCircle, size: 18),
                                    label: const Text('تذكير'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppSheet extends ConsumerStatefulWidget {
  const _WhatsAppSheet({required this.debtor});
  final DebtorUi debtor;

  @override
  ConsumerState<_WhatsAppSheet> createState() => _WhatsAppSheetState();
}

class _WhatsAppSheetState extends ConsumerState<_WhatsAppSheet> {
  final _promptController = TextEditingController(text: 'اكتب رسالة تذكير مهذبة ومختصرة');
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _promptController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _generateMessage() async {
    setState(() => _isLoading = true);
    final msg = await ref
        .read(aiAssistantProvider.notifier)
        .generateWhatsAppMessage(widget.debtor, _promptController.text);
    if (mounted) {
      setState(() {
        _messageController.text = msg;
        _isLoading = false;
      });
    }
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

    String formattedPhone = phone;
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '970${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+$formattedPhone';
    }

    final url = Uri.parse('whatsapp://send?phone=$formattedPhone&text=${Uri.encodeComponent(text)}');
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
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: AppColors.aiPurple),
              const SizedBox(width: 8),
              Text(
                'توليد رسالة بالذكاء الاصطناعي',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            decoration: InputDecoration(
              labelText: 'كيف تريد أن تكون الرسالة؟',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _generateMessage,
            icon: _isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.wand2, size: 18),
            label: Text(_isLoading ? 'جاري التوليد...' : 'توليد الرسالة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.aiPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'نص الرسالة النهائي',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _send,
            icon: const Icon(LucideIcons.send, size: 18),
            label: const Text('إرسال عبر واتساب'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}