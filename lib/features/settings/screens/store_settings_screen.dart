import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/bootstrap/prefs_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/reports_style_shell.dart';

class StoreSettingsScreen extends ConsumerStatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  ConsumerState<StoreSettingsScreen> createState() =>
      _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  final _name = TextEditingController();
  final _currency = TextEditingController();
  final _address = TextEditingController();

  var _prefsLoaded = false;

  @override
  void dispose() {
    _name.dispose();
    _currency.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final p = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _name.text = (p.getString(PrefsKeys.userName) ?? '').trim();
        _currency.text = (p.getString(PrefsKeys.storeCurrencyLabel) ?? '')
                .trim()
                .isEmpty
            ? 'شيكل (₪)'
            : (p.getString(PrefsKeys.storeCurrencyLabel) ?? 'شيكل (₪)')
                .trim();
        final addr = (p.getString(PrefsKeys.storeAddress) ?? '').trim();
        _address.text = addr.isEmpty ? 'غزة العزة' : addr;
        _prefsLoaded = true;
      });
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم المتجر')),
      );
      return;
    }

    final cur = _currency.text.trim().isEmpty ? 'شيكل (₪)' : _currency.text.trim();
    final adr =
        _address.text.trim().isEmpty ? 'غزة العزة' : _address.text.trim();

    final p = await SharedPreferences.getInstance();
    await p.setString(PrefsKeys.storeCurrencyLabel, cur);
    await p.setString(PrefsKeys.storeAddress, adr);

    await ref.read(appSessionProvider.notifier).saveName(name);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ReportsStylePage(
        title: 'إعدادات المتجر',
        subtitle: 'الاسم، العملة والعنوان الظاهر في التقارير',
        child: !_prefsLoaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.lavender,
                    child: Icon(
                      LucideIcons.store,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(label: 'اسم المتجر', controller: _name),
                  const SizedBox(height: 16),
                  _buildTextField(
                      label: 'العملة الأساسية', controller: _currency),
                  const SizedBox(height: 16),
                  _buildTextField(label: 'العنوان', controller: _address),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'حفظ التغييرات',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
