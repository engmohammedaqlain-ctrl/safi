import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/bootstrap/startup_ledger_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/debts/providers/debts_ui_provider.dart';
import '../../../features/sales/providers/cashbook_ui_provider.dart';

/// مرحلة إقلاع — خلفية مطابقة لـ native splash وحرف «ص» داخل مربع أرجواني.
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
      label: 'الصافي، جاري التحميل',
      child: Scaffold(
        backgroundColor: SplashScreen.nativeSplashColor,
        body: Center(
          child: Container(
            width: 96,
            height: 96,
            color: AppColors.primary,
            alignment: Alignment.center,
            child: Text(
              'ص',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onPrimary,
                fontSize: 52,
                fontWeight: FontWeight.w900,
                fontFamily: AppFonts.family,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
