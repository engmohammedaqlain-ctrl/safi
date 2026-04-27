import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/account_selector.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safi_button.dart';
import '../../debts/providers/debts_ui_provider.dart';
import '../providers/sales_ui_provider.dart';
import '../widgets/product_quick_tile.dart';

class SalesPosCatalog extends ConsumerStatefulWidget {
  const SalesPosCatalog({super.key, this.bottomInset = 0});

  final double bottomInset;

  @override
  ConsumerState<SalesPosCatalog> createState() => _SalesPosCatalogState();
}

class _SalesPosCatalogState extends ConsumerState<SalesPosCatalog> {
  String? _paymentMethodId;
  DebtorUi? _pickedFromList;
  bool _isNewCustomer = false;
  final _customerNameCtrl = TextEditingController();

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(quickProductsProvider);
    final allCustomers = ref.watch(debtorsUiProvider);
    final w = MediaQuery.sizeOf(context).width;
    final crossAxis = w > 700 ? 3 : 2;
    final bottomPad = 12.0 + widget.bottomInset;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomPad,
      ),
      children: [
        // ── العميل ──
        Text(
          'ربط البيع بعميل (اختياري)',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.35,
          ),
        ),
        const SizedBox(height: 6),
        if (_isNewCustomer)
          GlassCard(
            child: Column(
              children: [
                TextField(
                  controller: _customerNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل الجديد',
                    prefixIcon: Icon(LucideIcons.userPlus, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _isNewCustomer = false;
                      _customerNameCtrl.clear();
                    }),
                    icon: const Icon(LucideIcons.arrowRight, size: 16),
                    label: const Text('عودة للبحث في العملاء'),
                  ),
                ),
              ],
            ),
          )
        else
          GlassCard(
            child: Column(
              children: [
                InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.search, size: 20),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<DebtorUi>(
                      isExpanded: true,
                      value: _pickedFromList,
                      hint: const Text('ابحث أو اختر عميلاً...'),
                      items: allCustomers
                          .map(
                            (d) =>
                                DropdownMenuItem(value: d, child: Text(d.name)),
                          )
                          .toList(),
                      onChanged: (d) => setState(() => _pickedFromList = d),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _isNewCustomer = true;
                      _pickedFromList = null;
                    }),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('إضافة عميل جديد'),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: AppSpacing.xl),

        // ── نقطة البيع والمنتجات ──
        Text(
          'نقطة البيع (المنتجات)',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.35,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'ابحث باسم المنتج...',
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            prefixIcon: const Icon(
              LucideIcons.search,
              color: AppColors.textMuted,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.rlg,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.rlg,
              borderSide: BorderSide(color: AppColors.outlineSoft),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.rlg,
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxis,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, i) => ProductQuickTile(product: products[i]),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── طريقة الدفع ──
        Text(
          'كيف استلمت قيمة البيع؟',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.35,
          ),
        ),
        const SizedBox(height: 6),
        AccountSelector(
          selectedAccountId: _paymentMethodId,
          onChanged: (acc) => setState(() => _paymentMethodId = acc.id),
        ),

        const SizedBox(height: AppSpacing.xl),
        GlassCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي السلة',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MAD 426',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.flowIn,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SafiButton(
                label: 'إتمام البيع',
                icon: LucideIcons.check,
                isExpanded: false,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
