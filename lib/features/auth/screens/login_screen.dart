import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/auth/firestore_registered_phone_auth.dart';
import '../../../core/auth/phone_auth_messages.dart';
import '../../../core/auth/phone_auth_service.dart';
import '../../../core/auth/phone_auth_support.dart';
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
  final _phoneAuthService = PhoneAuthService();

  var _showOtp = false;
  var _submitting = false;
  String _otpCode = '';
  final _otpKey = GlobalKey<OtpCodeFieldState>();

  /// هل رقم الهاتف له مستند في [registered_phones] (يُحمَّل الاسم بعدها).
  bool _listedInFirestore = false;

  // Firebase Phone Auth state
  String? _verificationId;
  int? _resendToken;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _phone.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) t.cancel();
      });
    });
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0 || _submitting) return;
    setState(() => _submitting = true);
    try {
      await _phoneAuthService.startVerification(
        rawPhoneDigits: _phone.text.trim(),
        forceResendingToken: _resendToken,
        onCodeSent: (vid, token) {
          if (!mounted) return;
          setState(() {
            _verificationId = vid;
            _resendToken = token;
          });
          _startResendCountdown();
          showAppSnackBar(context, 'تم إعادة إرسال رمز التحقق');
        },
        onSignedIn: (uc) async {
          if (!mounted) return;
          await _finishLoginAfterVerification();
        },
        onFailed: (e) {
          if (!mounted) return;
          showAppSnackBar(context, phoneAuthMessageAr(e));
        },
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _afterFirebaseSignIn({
    required String rawDigits,
    String? displayNameFromFirestore,
    String? ownerUidOverride,
    String? role,
    List<String>? permissions,
  }) async {
    final docId = FirestoreRegisteredPhoneAuth.documentIdFromE164(
      phoneDigitsToE164(rawDigits),
    );
    final resolvedRole = role ?? 'owner';
    final resolvedPerms = resolvedRole == 'owner'
        ? <String>[]
        : List<String>.from(permissions ?? const []);
    await ref.read(appSessionProvider.notifier).onLoginSuccess(
          phoneDocId: docId,
          displayNameFromFirestore: displayNameFromFirestore,
          ownerUidOverride: ownerUidOverride,
          role: resolvedRole,
          permissions: resolvedPerms,
        );
  }

  /// يفرِّق بين: موجود في Firestore (مسموح ومُدار) أو لم يُسجَّل بعد (إنشاء عبر Firebase Auth المعتادة).
  Future<void> _beginOtpStep() async {
    final raw = _phone.text.trim();
    if (raw.length < 8) {
      showAppSnackBar(context, 'أدخل رقماً صحيحاً');
      return;
    }
    final online = await checkDeviceOnlineNow();
    if (!online) {
      if (mounted) {
        showAppSnackBar(
          context,
          'فعّل الإنترنت للتحقّق من رقم المتجر ومزامنة البيانات.',
        );
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      try {
        phoneDigitsToE164(raw);
      } on FormatException {
        if (!mounted) return;
        showAppSnackBar(
          context,
          'تنسيق الرقم غير مدعوم. جرّب إدخال الرقم كاملاً مع المفتاح الدولي.',
        );
        return;
      }
      DocumentSnapshot<Map<String, dynamic>>? snap;
      try {
        snap =
            await FirestoreRegisteredPhoneAuth.lookupPhone(raw); // مستند موجود / null
      } catch (e, st) {
        debugPrint('Firestore lookupPhone: $e\n$st');
        if (!mounted) return;
        showAppSnackBar(
          context,
          'تعذر مراجعة رقم المتجر ضد Firestore. تحقّق من الاتصال.',
        );
        return;
      }
      if (!mounted) return;
      _listedInFirestore = snap != null;

      // إرسال رمز تحقق SMS حقيقي عبر Firebase Phone Auth
      if (isFirebasePhoneVerificationSupported) {
        await _phoneAuthService.startVerification(
          rawPhoneDigits: raw,
          forceResendingToken: _resendToken,
          onCodeSent: (vid, token) {
            if (!mounted) return;
            setState(() {
              _verificationId = vid;
              _resendToken = token;
              _showOtp = true;
              _otpCode = '';
            });
            _otpKey.currentState?.clear();
            _startResendCountdown();
          },
          onSignedIn: (uc) async {
            // تحقق تلقائي على Android — إكمال تسجيل الدخول مباشرة
            if (!mounted) return;
            await _finishLoginAfterVerification();
          },
          onFailed: (e) {
            if (!mounted) return;
            showAppSnackBar(context, phoneAuthMessageAr(e));
          },
        );
      } else {
        // أنظمة سطح المكتب — الرجوع للسلوك القديم
        setState(() {
          _showOtp = true;
          _otpCode = '';
        });
        _otpKey.currentState?.clear();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// يتحقق من رمز SMS الحقيقي ثم يسجّل الدخول بـ email/password للحفاظ على UID البيانات.
  Future<void> _confirmOtp() async {
    if (_otpCode.length < OtpCodeField.otpLength) {
      showAppSnackBar(context, 'أدخل الأرقام الستة لرمز التحقق');
      return;
    }
    final online = await checkDeviceOnlineNow();
    if (!online) {
      if (mounted) {
        showAppSnackBar(
          context,
          'يجب اتصال بالإنترنت لتحميل بيانات المتجر من السحابة وحفظها للعمل بدون شبكة.',
        );
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      // التحقق من رمز SMS الحقيقي عبر Firebase Phone Auth
      if (isFirebasePhoneVerificationSupported && _verificationId != null) {
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: _otpCode.trim(),
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      // بعد التحقق، إكمال تسجيل الدخول بـ email/password
      await _finishLoginAfterVerification();
    } on FirebaseAuthException catch (e) {
      ref.read(postLoginLedgerLoadingProvider.notifier).setLoading(false);
      if (mounted) showAppSnackBar(context, phoneAuthMessageAr(e));
    } catch (e, st) {
      ref.read(postLoginLedgerLoadingProvider.notifier).setLoading(false);
      debugPrint('$e\n$st');
      if (mounted) showAppSnackBar(context, 'تعذر إكمال التحقق. حاول لاحقاً.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// منطق ما بعد التحقق: تسجيل دخول email/password + team invites + session
  Future<void> _finishLoginAfterVerification() async {
    ref.read(postLoginLedgerLoadingProvider.notifier).setLoading(true);
    final raw = _phone.text.trim();
    setState(() => _submitting = true);
    try {
      await FirestoreRegisteredPhoneAuth.signInWithRegisteredPhoneAllowed(
        rawPhoneDigits: raw,
      );
      if (_listedInFirestore) {
        await FirestoreRegisteredPhoneAuth.mergePhoneRegistryDocFromLogin(raw);
      }
      String? displayName;
      if (_listedInFirestore) {
        try {
          final snap = await FirestoreRegisteredPhoneAuth.lookupPhone(raw);
          displayName = snap?.data()?['displayName'] as String?;
        } catch (_) {}
      }

      // Check for team invites (pending = choice dialog; active = re‑grant access + same session)
      final e164 = phoneDigitsToE164(raw);
      final phoneDocId = FirestoreRegisteredPhoneAuth.documentIdFromE164(e164);
      final inviteSnap =
          await FirebaseFirestore.instance.collection('team_invites').doc(phoneDocId).get();

      if (inviteSnap.exists) {
        final inviteData = inviteSnap.data()!;
        final status = inviteData['status'] as String?;
        final ownerUid = inviteData['ownerUid'] as String?;
        final roleRaw = inviteData['role'] as String? ?? 'viewer';
        final invitePerms = List<String>.from(inviteData['permissions'] ?? []);

        if (ownerUid != null &&
            ownerUid.isNotEmpty &&
            (status == 'pending' || status == 'active')) {
          Future<void> finishAsTeamMember() async {
            await LedgerTeamAccess.grantForActiveMember(
              ownerUid: ownerUid,
              phoneDocId: phoneDocId,
              role: roleRaw,
              permissions: invitePerms,
            );
            await _afterFirebaseSignIn(
              rawDigits: raw,
              displayNameFromFirestore: displayName,
              ownerUidOverride: ownerUid,
              role: roleRaw,
              permissions: invitePerms,
            );
          }

          if (status == 'active') {
            if (!mounted) return;
            await finishAsTeamMember();
            return;
          }

          if (!mounted) return;
          ref.read(postLoginLedgerLoadingProvider.notifier).setLoading(false);

          final storeName = inviteData['storeName'] ?? 'المتجر';
          final roleLabel = roleRaw == 'cashier' ? 'كاشير' : 'مشاهد';

          final accept = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('دعوة انضمام لفريق'),
                content: Text(
                  'تمت دعوتك للانضمام إلى متجر "$storeName" بصلاحية "$roleLabel". هل تود الاستكمال كعضو في هذا المتجر?\n\n'
                  'إذا اخترت «لا»، ستدخل إلى متجرك الشخصي.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('لا، متجري الشخصي'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('نعم، قبول الدعوة'),
                  ),
                ],
              ),
            ),
          );

          if (accept == true) {
            await inviteSnap.reference.update({'status': 'active'});
            if (!mounted) return;
            await finishAsTeamMember();
            return;
          }

          final authUid = FirebaseAuth.instance.currentUser?.uid;
          if (authUid != null) {
            await LedgerTeamAccess.revokeMember(
              ownerUid: ownerUid,
              memberAuthUid: authUid,
            );
          }
        }
      }

      if (!mounted) return;
      await _afterFirebaseSignIn(
        rawDigits: raw,
        displayNameFromFirestore: displayName,
      );
    } on FirebaseAuthException catch (e) {
      ref.read(postLoginLedgerLoadingProvider.notifier).setLoading(false);
      if (mounted) {
        showAppSnackBar(context, _authErrorAr(e));
      }
    } catch (e, st) {
      ref.read(postLoginLedgerLoadingProvider.notifier).setLoading(false);
      debugPrint('$e\n$st');
      if (mounted) {
        showAppSnackBar(context, 'تعذر إكمال الدخول. حاول لاحقاً.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _authErrorAr(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return 'لم نستطع المصادقة. تأكّد أن «البريد/كلمة المرور» مفعَّل في Firebase، وألا يكون هذا الحساب مُنشأ سابقاً بكلمة مختلفة خارج التطبيق.';
      case 'network-request-failed':
        return 'لا يوجد اتصال؛ حاول لاحقاً.';
      case 'too-many-requests':
        return 'محاولات كثيرة؛ انتظر ثم حاول.';
      default:
        return e.message ?? 'فشل تسجيل الدخول';
    }
  }

  Future<void> _continue() async {
    if (_submitting) return;
    if (!_showOtp) {
      await _beginOtpStep();
      return;
    }
    await _confirmOtp();
  }

  @override
  Widget build(BuildContext context) {
    return LightLoadingOverlay(
      visible: _submitting,
      semanticLabel: 'جاري التحقق',
      child: VaultBrandedShell(
        headerSubtitle: _showOtp
            ? 'أدخل رمز الدخول'
            : 'تسجيل دخول آمن',
        belowBrand: Center(child: _LoginStepIndicator(onOtpStep: _showOtp)),
        sheet: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  24,
                  AppSpacing.lg,
                  12,
                ),
                child: Column(
                  children: [
                    Material(
                      color: AppColors.backgroundSecondary,
                      borderRadius: AppRadius.rxl,
                      elevation: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.rxl,
                          border: Border.all(color: AppColors.outlineSoft),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.07),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_showOtp) ...[
                              Text(
                                'رقم الهاتف',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: const Color(0xFF12121F),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'مثال: 599123456 أو 9665…',
                                  prefixIcon: Icon(
                                    LucideIcons.smartphone,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      LucideIcons.smartphone,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _phone.text,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _listedInFirestore
                                    ? 'رقمك موجود في قائمة المتجر؛ أدخل كلمة المرور الخاصة بك.'
                                    : 'رقمك غير مُدرَج في القائمة بعد؛ سيتم إنشاء حساب جديد لك.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OtpCodeField(
                                key: _otpKey,
                                onCodeChanged: (s) {
                                  setState(() => _otpCode = s);
                                },
                              ),
                            ],
                            if (_showOtp) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: _submitting
                                        ? null
                                        : () {
                                            setState(() {
                                              _showOtp = false;
                                              _otpCode = '';
                                              _listedInFirestore = false;
                                            });
                                            _otpKey.currentState?.clear();
                                          },
                                    child: const Text('تصحيح رقم الهاتف'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'بمتابعة الدخول تؤكد موافقتك على استخدام التطبيق لإدارة متجرك.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const VaultTrustStrip(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SafiButton(
                label: _showOtp
                    ? (_submitting ? 'جاري الدخول...' : 'تأكيد والدخول')
                    : 'متابعة',
                icon: _showOtp ? LucideIcons.check : null,
                onPressed: _submitting ? null : _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// مؤشر خطوتين تحت شعار صافي (نفس أسلوب نقاط الأونبوردنغ).
class _LoginStepIndicator extends StatelessWidget {
  const _LoginStepIndicator({required this.onOtpStep});

  final bool onOtpStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepDot(active: !onOtpStep, done: onOtpStep),
        const SizedBox(width: 8),
        _stepDot(active: onOtpStep, done: false),
      ],
    );
  }

  Widget _stepDot({required bool active, required bool done}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      height: 6,
      width: active ? 28 : 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: active || done
            ? Colors.white
            : Colors.white.withValues(alpha: 0.28),
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }
}

/// خانات مرتبة لرمز التحقق (6 أرقام) — LTR للأرقام، تركيز تلقائي، دعم لصق
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({super.key, required this.onCodeChanged});

  static const int otpLength = 6;

  final ValueChanged<String> onCodeChanged;

  @override
  OtpCodeFieldState createState() => OtpCodeFieldState();
}

class OtpCodeFieldState extends State<OtpCodeField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  int? _focusedI;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      OtpCodeField.otpLength,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(OtpCodeField.otpLength, (i) => FocusNode());
    for (var i = 0; i < OtpCodeField.otpLength; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          setState(() => _focusedI = i);
        } else {
          if (_focusedI == i) setState(() => _focusedI = null);
        }
      });
    }
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  bool _onHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return false;
    }
    final i = _focusedI;
    if (i == null || i <= 0) {
      return false;
    }
    if (_controllers[i].text.isNotEmpty) {
      return false;
    }
    _focusNodes[i - 1].requestFocus();
    _controllers[i - 1].text = '';
    _emit();
    return true;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    for (final n in _focusNodes) {
      n.dispose();
    }
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final code = _controllers.map((c) => c.text).join();
    widget.onCodeChanged(code);
  }

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes.first.requestFocus();
    }
    _emit();
  }

  void _distribute(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return;
    for (var k = 0; k < OtpCodeField.otpLength; k++) {
      _controllers[k].text = k < d.length ? d[k] : '';
    }
    if (d.length >= OtpCodeField.otpLength) {
      _focusNodes[OtpCodeField.otpLength - 1].requestFocus();
      FocusScope.of(context).unfocus();
    } else {
      _focusNodes[d.length].requestFocus();
    }
    _emit();
  }

  void _onFieldChanged(int i, String value) {
    var v = value.replaceAll(RegExp(r'\D'), '');
    if (v.length > 1) {
      _distribute(v);
      return;
    }
    if (v.length == 1) {
      if (i < OtpCodeField.otpLength - 1) {
        _focusNodes[i + 1].requestFocus();
      } else {
        FocusScope.of(context).unfocus();
      }
    } else {
      if (i > 0) {
        _focusNodes[i - 1].requestFocus();
      }
    }
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: List.generate(OtpCodeField.otpLength, (i) {
          final isFocused = _focusedI == i;
          final hasValue = _controllers[i].text.isNotEmpty;
          return Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 48,
                decoration: BoxDecoration(
                  color: isFocused
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : hasValue
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : AppColors.backgroundSecondary,
                  borderRadius: AppRadius.rmd,
                  border: Border.all(
                    color: isFocused
                        ? AppColors.primary
                        : hasValue
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.textMuted.withValues(alpha: 0.25),
                    width: isFocused ? 1.8 : 1.2,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    onChanged: (s) => _onFieldChanged(i, s),
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    showCursor: false,
                    autofillHints: i == 0
                        ? const [AutofillHints.oneTimeCode]
                        : const [],
                    textInputAction: i == OtpCodeField.otpLength - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    style: AppTextStyles.numberLarge.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      color: AppColors.primary,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    decoration: const InputDecoration(
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
