import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../models/debt_category_model.dart';
import '../providers/debt_categories_provider.dart';
import 'category_color_palette.dart';

/// ورقة سفلية: إضافة/تعديل تصنيف — اسم + شبكة ألوان
Future<void> showAddCategoryBottomSheet(
  BuildContext context, {
  DebtCategory? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AddCategoryBody(existing: existing),
  );
}

class _AddCategoryBody extends ConsumerStatefulWidget {
  const _AddCategoryBody({this.existing});

  final DebtCategory? existing;

  @override
  ConsumerState<_AddCategoryBody> createState() => _AddCategoryBodyState();
}

class _AddCategoryBodyState extends ConsumerState<_AddCategoryBody> {
  late final TextEditingController _name;
  late int _colorValue;
  static const int _kMaxNameLen = 32;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _colorValue = widget.existing?.colorValue ?? defaultCategoryColorArgb;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final n = _name.text.trim();
    if (n.isEmpty) {
      showAppSnackBar(
        context,
        'أدخل اسماً للتصنيف',
        backgroundColor: Colors.red,
      );
      return;
    }
    final p = ref.read(debtCategoriesProvider.notifier);
    if (widget.existing != null) {
      p.update(DebtCategory(
        id: widget.existing!.id,
        name: n,
        colorValue: _colorValue,
      ));
    } else {
      p.add(DebtCategory(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: n,
        colorValue: _colorValue,
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final palette = categoryColorPalette;
    final isEdit = widget.existing != null;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, color: AppColors.primary),
                  ),
                  Expanded(
                    child: Text(
                      isEdit ? 'تعديل التصنيف' : 'إضافة تصنيف جديد',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(_colorValue).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outline),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _name,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLength: _kMaxNameLen,
                      decoration: InputDecoration(
                        labelText: 'الاسم',
                        labelStyle: const TextStyle(color: AppColors.primary),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'اختر اللون',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: palette.length,
                itemBuilder: (context, i) {
                  final c = palette[i];
                  final argb = c.toARGB32();
                  final sel = argb == _colorValue;
                  return Material(
                    color: c,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => setState(() => _colorValue = argb),
                      borderRadius: BorderRadius.circular(8),
                      child: sel
                          ? const Icon(
                              LucideIcons.check,
                              color: Colors.white,
                              size: 22,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('حفظ', style: TextStyle(fontSize: 16)),
                    ),
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
