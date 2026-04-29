import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/vault_branded_shell.dart';
import '../providers/debt_categories_provider.dart';
import '../providers/debts_ui_provider.dart';
import '../utils/customer_name_limits.dart';
import '../widgets/select_categories_bottom_sheet.dart';

class AddCustomerDetailScreen extends ConsumerStatefulWidget {
  final String? initialName;
  final String? initialPhone;
  final bool isSupplier;

  const AddCustomerDetailScreen({
    super.key,
    this.initialName,
    this.initialPhone,
    this.isSupplier = false,
  });

  @override
  ConsumerState<AddCustomerDetailScreen> createState() =>
      _AddCustomerDetailScreenState();
}

class _AddCustomerDetailScreenState
    extends ConsumerState<AddCustomerDetailScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  List<String> _categoryIds = [];
  bool _doubleLedger = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    String p = widget.initialPhone ?? '';
    p = p.replaceAll(RegExp(r'\D'), '');
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
    final allCategories = ref.watch(activeDebtCategoriesProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: VaultInsetPageShell(
        title: const Text(
          'إضافة عميل',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text(
                    'الاسم',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(kMaxCustomerNameLength),
                    ],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'رقم الهاتف',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // RTL: أول طفل = اليمين → حقل الأرقام
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: false,
                              decimal: false,
                            ),
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(15),
                            ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ثاني طفل = يسار الشاشة → +
                      const _PhonePrefixBox(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'العنوان',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'دفتر حساب مزدوج لهذا الطرف',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    subtitle: Text(
                      'يُشار إليه بالتطبيق فقط لتنظيم الحسابات؛ الرصيد كما كان.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.right,
                    ),
                    value: _doubleLedger,
                    onChanged: (v) => setState(() => _doubleLedger = v),
                  ),
                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.primary.withValues(alpha: 0.02),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'التصنيفات',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        if (_categoryIds.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.start,
                              children: _categoryIds.map((id) {
                                final match = allCategories.where(
                                  (c) => c.id == id,
                                );
                                final cat = match.isEmpty ? null : match.first;
                                if (cat == null) {
                                  return const SizedBox.shrink();
                                }
                                return InputChip(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  label: Text(
                                    cat.name,
                                    style: TextStyle(
                                      color: cat.color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  deleteIcon: Icon(
                                    LucideIcons.x,
                                    size: 16,
                                    color: cat.color,
                                  ),
                                  side: BorderSide(
                                    color: cat.color.withValues(alpha: 0.35),
                                  ),
                                  backgroundColor: cat.color.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      _categoryIds = [
                                        for (final k in _categoryIds)
                                          if (k != id) k,
                                      ];
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 6,
                              bottom: 4,
                              left: 0,
                              right: 0,
                            ),
                            child: Text(
                              'اختر تصنيفات (اختياري)',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Material(
                          color: AppColors.primary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () async {
                              final r = await showSelectCategoriesBottomSheet(
                                context,
                                initialSelected: _categoryIds.toSet(),
                              );
                              if (r != null) {
                                setState(
                                  () => _categoryIds = List<String>.from(r),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.layoutGrid,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'اختيار التصنيفات',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // أرقام فقط (المُنقّاة مسبقاً) — دون + مكرر
                    final phoneDigits = _phoneCtrl.text.replaceAll(
                      RegExp(r'\D'),
                      '',
                    );
                    if (phoneDigits.isEmpty) {
                      showAppSnackBar(
                        context,
                        'الرجاء إدخال رقم الهاتف (أرقام إنجليزية)',
                        backgroundColor: Colors.red,
                      );
                      return;
                    }
                    if (phoneDigits.length < 7) {
                      showAppSnackBar(
                        context,
                        'رقم الهاتف قصير جداً (على الأقل 7 أرقام)',
                        backgroundColor: Colors.red,
                      );
                      return;
                    }

                    final formattedPhone = '+$phoneDigits';

                    final existingDebtors = ref.read(debtorsUiProvider);
                    final phoneExists = existingDebtors.any((d) {
                      final stored = d.phone.replaceAll(RegExp(r'\D'), '');
                      return d.phone == formattedPhone ||
                          stored == phoneDigits ||
                          d.phone.replaceAll('+', '') == phoneDigits;
                    });

                    if (phoneExists) {
                      showAppSnackBar(
                        context,
                        'رقم الهاتف مسجل مسبقاً، لا يمكن إضافة حسابين بنفس الرقم',
                        backgroundColor: Colors.red,
                      );
                      return;
                    }

                    final nameTrimmed =
                        sanitizeCustomerName(_nameCtrl.text);
                    final newCustomer = DebtorUi(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameTrimmed.isEmpty ? phoneDigits : nameTrimmed,
                      phone: formattedPhone,
                      address: _addressCtrl.text.trim(),
                      amount: '0.0',
                      status: 'اليوم',
                      urgency: DebtUrgency.low,
                      categoryIds: List<String>.from(_categoryIds),
                      isSupplier: widget.isSupplier,
                      editedMs: DateTime.now().millisecondsSinceEpoch,
                      doubleLedger: _doubleLedger,
                    );
                    ref
                        .read(debtorsUiProvider.notifier)
                        .addCustomer(newCustomer);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text(
                    'تأكيد',
                    style: TextStyle(
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
    );
  }
}

/// مربع ثابت لعرض «+» (يسار في RTL) بجانب حقل الأرقام (يمين).
class _PhonePrefixBox extends StatelessWidget {
  const _PhonePrefixBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          '+',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
