import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/auth/firestore_registered_phone_auth.dart';
import '../../../core/auth/phone_e164.dart';
import '../../../core/bootstrap/app_session.dart';
import '../../../core/network/connectivity_status.dart';
import '../../../core/services/ledger_team_access.dart';
import '../../../core/sync/post_login_loading.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/light_loading_overlay.dart';
import '../../../core/widgets/safi_button.dart';
import '../../../core/widgets/vault_branded_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _codeController = TextEditingController();

  var _showCodeInput = false;
  var _submitting = false;
  bool _listedInFirestore = false;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phone.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Widget _getPrefixWidget(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    String? flagText;
    if (phone.startsWith('+')) {
      if (phone.startsWith('+970')) flagText = '🇵🇸 +970';
      else if (phone.startsWith('+972')) flagText = '+972';
    } else if (digits.length >= 2) {
      if (digits.startsWith('05') && digits.length >= 3) {
        final p = digits.substring(0, 3);
        flagText = (p == '059' || p == '056') ? '🇵🇸 +970' : '+972';
      } else if (digits.startsWith('5') && digits.length >= 2) {
        final p = digits.substring(0, 2);
        flagText = (p == '59' || p == '56') ? '🇵🇸 +970' : '+972';
      } else if (digits.startsWith('970')) {
        flagText = '🇵🇸 +970';
      } else if (digits.startsWith('972')) {
        flagText = '+972';
      }
    }
    if (flagText != null) {
      return Container(
        margin: const EdgeInsetsDirectional.only(end: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: BorderDirectional(end: BorderSide(color: AppColors.outlineSoft)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flagText, textDirection: TextDirection.ltr,
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return const Icon(LucideIcons.smartphone, color: AppColors.primary);
  }

  // ── الخطوة 1: فحص الرقم والانتقال لإدخال الرمز ──
  Future<void> _checkPhoneStep() async {
    final raw = _phone.text.trim();
    if (raw.length < 8) { showAppSnackBar(context, 'أدخل رقماً صحيحاً'); return; }
    final online = await checkDeviceOnlineNow();
    if (!online) { if (mounted) showAppSnackBar(context, 'فعّل الإنترنت للتحقّق.'); return; }

    setState(() => _submitting = true);
    try {
      try { phoneDigitsToE164(raw); } on FormatException {
        if (mounted) showAppSnackBar(context, 'تنسيق الرقم غير مدعوم. جرّب إدخال الرقم كاملاً مع المفتاح الدولي.');
        return;
      }
      try {
        final snap = await FirestoreRegisteredPhoneAuth.lookupPhone(raw);
        _listedInFirestore = snap != null;
      } catch (_) { _listedInFirestore = false; }
      if (!mounted) return;
      setState(() { _showCodeInput = true; _codeController.clear(); });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── الخطوة 2: التحقق من رمز الدخول ──
  Future<void> _verifyCodeStep() async {
    final code = _codeController.text.trim();
    if (code.length < 4) { showAppSnackBar(context, 'أدخل رمز الدخول (4 أرقام)'); return; }
    final online = await checkDeviceOnlineNow();
    if (!online) { if (mounted) showAppSnackBar(context, 'يجب اتصال بالإنترنت.'); return; }

    setState(() => _submitting = true);
    try {
      final raw = _phone.text.trim();
      final valid = FirestoreRegisteredPhoneAuth.verifyAccessCode(rawPhoneDigits: raw, code: code);
      if (!valid) { if (mounted) showAppSnackBar(context, 'رمز الدخول غير صحيح. تواصل مع المسؤول.'); return; }
      await _finishLogin();
    } catch (e, st) {
      debugPrint('verifyCodeStep: $e\n$st');
      if (mounted) showAppSnackBar(context, 'تعذر إكمال الدخول. حاول لاحقاً.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── إكمال تسجيل الدخول ──
  Future<void> _afterFirebaseSignIn({
    required String rawDigits, String? displayNameFromFirestore,
    String? ownerUidOverride, String? role, List<String>? permissions,
  }) async {
    final docId = FirestoreRegisteredPhoneAuth.documentIdFromE164(phoneDigitsToE164(rawDigits));
    final resolvedRole = role ?? 'owner';
    final resolvedPerms = resolvedRole == 'owner' ? <String>[] : List<String>.from(permissions ?? const []);
    await ref.read(appSessionProvider.notifier).onLoginSuccess(
      phoneDocId: docId, displayNameFromFirestore: displayNameFromFirestore,
      ownerUidOverride: ownerUidOverride, role: resolvedRole, permissions: resolvedPerms,
    );
  }

  Future<void> _finishLogin() async {
    ref.read(postLoginLedgerLoadingProvider.notifier).setLoading(true);
    final raw = _phone.text.trim();
    setState(() => _submitting = true);
    try {
      await FirestoreRegisteredPhoneAuth.signInWithRegisteredPhoneAllowed(rawPhoneDigits: raw);
      if (_listedInFirestore) await FirestoreRegisteredPhoneAuth.mergePhoneRegistryDocFromLogin(raw);

      String? displayName;
      if (_listedInFirestore) {
        try { final s = await FirestoreRegisteredPhoneAuth.lookupPhone(raw); displayName = s?.data()?['displayName'] as String?; } catch (_) {}
      }

      final e164 = phoneDigitsToE164(raw);
      final phoneDocId = FirestoreRegisteredPhoneAuth.documentIdFromE164(e164);
      final inviteSnap = await FirebaseFirestore.instance.collection('team_invites').doc(phoneDocId).get();

      if (inviteSnap.exists) {
        final d = inviteSnap.data()!;
        final status = d['status'] as String?;
        final ownerUid = d['ownerUid'] as String?;
        final roleRaw = d['role'] as String? ?? 'viewer';
        final invitePerms = List<String>.from(d['permissions'] ?? []);

        if (ownerUid != null && ownerUid.isNotEmpty && (status == 'pending' || status == 'active')) {
          Future<void> finishAsTeam() async {
            await LedgerTeamAccess.grantForActiveMember(ownerUid: ownerUid, phoneDocId: phoneDocId, role: roleRaw, permissions: invitePerms);
            await _afterFirebaseSignIn(rawDigits: raw, displayNameFromFirestore: displayName, ownerUidOverride: ownerUid, role: roleRaw, permissions: invitePerms);
          }
          if (status == 'active') { if (!mounted) return; await finishAsTeam(); return; }
          if (!mounted) return;
          ref.read(postLoginLedgerLoadingProvider.notifier).setLoading(false);
          final storeName = d['storeName'] ?? 'المتجر';
          final roleLabel = roleRaw == 'cashier' ? 'كاشير' : 'مشاهد';
          final accept = await showDialog<bool>(context: context, barrierDismissible: false,
            builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
              title: const Text('دعوة انضمام لفريق'),
              content: Text('تمت دعوتك للانضمام إلى متجر "$storeName" بصلاحية "$roleLabel".\n\nإذا اخترت «لا»، ستدخل إلى متجرك الشخصي.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا، متجري الشخصي')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('نعم، قبول الدعوة')),
              ],
            )));
          if (accept == true) { await inviteSnap.reference.update({'status': 'active'}); if (!mounted) return; await finishAsTeam(); return; }
          final authUid = FirebaseAuth.instance.currentUser?.uid;
          if (authUid != null) await LedgerTeamAccess.revokeMember(ownerUid: ownerUid, memberAuthUid: authUid);
        }
      }
      if (!mounted) return;
      await _afterFirebaseSignIn(rawDigits: raw, displayNameFromFirestore: displayName);
    } on FirebaseAuthException catch (e) {
      ref.read(postLoginLedgerLoadingProvider.notifier).setLoading(false);
      if (mounted) showAppSnackBar(context, e.message ?? 'فشل تسجيل الدخول');
    } catch (e, st) {
      ref.read(postLoginLedgerLoadingProvider.notifier).setLoading(false);
      debugPrint('$e\n$st');
      if (mounted) showAppSnackBar(context, 'تعذر إكمال الدخول. حاول لاحقاً.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _continue() async {
    if (_submitting) return;
    if (!_showCodeInput) { await _checkPhoneStep(); return; }
    await _verifyCodeStep();
  }

  @override
  Widget build(BuildContext context) {
    return LightLoadingOverlay(
      visible: _submitting, semanticLabel: 'جاري التحقق',
      child: VaultBrandedShell(
        headerSubtitle: _showCodeInput ? 'أدخل رمز الدخول' : 'تسجيل دخول آمن',
        belowBrand: Center(child: _LoginStepIndicator(onCodeStep: _showCodeInput)),
        sheet: Column(children: [
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 24, AppSpacing.lg, 12),
            child: Column(children: [
              Material(color: AppColors.backgroundSecondary, borderRadius: AppRadius.rxl, elevation: 0,
                child: Container(
                  decoration: BoxDecoration(borderRadius: AppRadius.rxl, border: Border.all(color: AppColors.outlineSoft),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 6))]),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (!_showCodeInput) ...[
                      Text('رقم الهاتف', style: AppTextStyles.titleSmall.copyWith(color: const Color(0xFF12121F))),
                      const SizedBox(height: 8),
                      TextField(controller: _phone, keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(hintText: 'مثال: ... 970 59+', prefixIcon: _getPrefixWidget(_phone.text))),
                      const SizedBox(height: 12),
                      Container(padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15))),
                        child: Row(children: [
                          Icon(LucideIcons.info, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text('أدخل رقم هاتفك ثم ستحتاج رمز الدخول من المسؤول.',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, height: 1.5))),
                        ])),
                    ] else ...[
                      Row(children: [
                        Container(padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(LucideIcons.smartphone, size: 16, color: AppColors.primary)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_phone.text, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                        Container(padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(LucideIcons.checkCircle, size: 16, color: Colors.green)),
                      ]),
                      const SizedBox(height: 4),
                      Text('أدخل رمز الدخول الذي حصلت عليه من المسؤول.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 16),
                      Text('رمز الدخول', style: AppTextStyles.titleSmall.copyWith(color: const Color(0xFF12121F))),
                      const SizedBox(height: 8),
                      TextField(controller: _codeController, keyboardType: TextInputType.number,
                        maxLength: 4, textAlign: TextAlign.center,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                        style: AppTextStyles.titleMedium.copyWith(letterSpacing: 12, fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 28),
                        decoration: InputDecoration(hintText: '● ● ● ●', counterText: '',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted, letterSpacing: 8),
                          prefixIcon: const Icon(LucideIcons.keyRound, color: AppColors.primary)),
                        onSubmitted: (_) => _continue()),
                    ],
                    if (_showCodeInput) ...[
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        TextButton(onPressed: _submitting ? null : () {
                          setState(() { _showCodeInput = false; _codeController.clear(); _listedInFirestore = false; });
                        }, child: const Text('تصحيح رقم الهاتف')),
                      ]),
                    ],
                  ]),
                )),
              const SizedBox(height: AppSpacing.md),
              Text('بمتابعة الدخول تؤكد موافقتك على استخدام التطبيق لإدارة متجرك.',
                textAlign: TextAlign.center, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted, height: 1.4)),
            ]),
          )),
          const VaultTrustStrip(),
          Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            child: SafiButton(
              label: _showCodeInput ? (_submitting ? 'جاري الدخول...' : 'تأكيد والدخول') : 'متابعة',
              icon: _showCodeInput ? LucideIcons.check : null,
              onPressed: _submitting ? null : _continue)),
        ]),
      ),
    );
  }
}

class _LoginStepIndicator extends StatelessWidget {
  const _LoginStepIndicator({required this.onCodeStep});
  final bool onCodeStep;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _stepDot(active: !onCodeStep, done: onCodeStep),
      const SizedBox(width: 8),
      _stepDot(active: onCodeStep, done: false),
    ]);
  }
  Widget _stepDot({required bool active, required bool done}) {
    return AnimatedContainer(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic,
      height: 6, width: active ? 28 : 8,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(99),
        color: active || done ? Colors.white : Colors.white.withValues(alpha: 0.28),
        boxShadow: active ? [BoxShadow(color: Colors.white.withValues(alpha: 0.35), blurRadius: 8)] : null));
  }
}
