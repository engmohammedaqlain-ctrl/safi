import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/debts_ui_provider.dart';

class AddCustomerDetailScreen extends ConsumerStatefulWidget {
  final String? initialName;
  final String? initialPhone;

  const AddCustomerDetailScreen({super.key, this.initialName, this.initialPhone});

  @override
  ConsumerState<AddCustomerDetailScreen> createState() => _AddCustomerDetailScreenState();
}

class _AddCustomerDetailScreenState extends ConsumerState<AddCustomerDetailScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    String p = widget.initialPhone ?? '';
    if (p.startsWith('+')) p = p.substring(1);
    _phoneCtrl = TextEditingController(text: p);
    _addressCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('إضافة عميل', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text('الاسم', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('رقم الهاتف', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: const Text('+', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('العنوان', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressCtrl,
                    decoration: InputDecoration(
                      hintText: 'أدخل موقع أو عنوان العميل',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('التصنيفات', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Text('إضافة تصنيفات', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                                  const SizedBox(width: 4),
                                  Icon(LucideIcons.plusCircle, color: AppColors.primary, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'استخدم تصنيفات مخصصة (مثل VIP، جملة، المنطقة) لتصنيف جهات الاتصال الخاصة بك للتجميع والتصفية بسرعة',
                          style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final phoneInput = _phoneCtrl.text.trim();
                    if (phoneInput.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرجاء إدخال رقم الهاتف'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final formattedPhone = '+$phoneInput';
                    
                    final existingDebtors = ref.read(debtorsUiProvider);
                    final phoneExists = existingDebtors.any((d) => 
                        d.phone == formattedPhone || 
                        d.phone == phoneInput || 
                        d.phone.replaceAll('+', '') == phoneInput);

                    if (phoneExists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('رقم الهاتف مسجل مسبقاً، لا يمكن إضافة حسابين بنفس الرقم'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final newCustomer = DebtorUi(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameCtrl.text.trim().isEmpty ? phoneInput : _nameCtrl.text.trim(),
                      phone: formattedPhone,
                      address: _addressCtrl.text.trim(),
                      amount: '0.0',
                      status: 'اليوم',
                      urgency: DebtUrgency.low,
                    );
                    ref.read(debtorsUiProvider.notifier).addCustomer(newCustomer);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('تأكيد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
