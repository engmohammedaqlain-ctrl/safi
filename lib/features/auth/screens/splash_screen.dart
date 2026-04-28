import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/bootstrap/startup_ledger_data.dart';
import '../../../features/debts/providers/debts_ui_provider.dart';
import '../../../features/sales/providers/cashbook_ui_provider.dart';

/// مرحلة إقلاع تقنية فقط — نفس لون الـ native splash (#F3EFF7) دون شعار مكرر.
/// التصميم الظاهر للمستخدم يبقى من شاشة النظام الأصلية حتى الانتقال للخطوة التالية.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// يطابق `android:.../values/colors.xml` ‎splash_background
  static const Color nativeSplashColor = Color(0xFFF3EFF7);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapAfterFirstFrame());
    });
  }

  Future<void> _bootstrapAfterFirstFrame() async {
    await StartupLedgerData.ensureLoaded();
    if (!mounted) return;
    ref
      ..invalidate(debtorsUiProvider)
      ..invalidate(transactionsProvider)
      ..invalidate(cashbookEntriesProvider);
    ref.invalidate(appSessionProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'صافي، جاري التحميل',
      child: Scaffold(
        backgroundColor: SplashScreen.nativeSplashColor,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SplashScreen.nativeSplashColor,
                Color(0xFFECE5F3),
              ],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
