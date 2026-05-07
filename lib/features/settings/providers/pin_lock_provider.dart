import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/bootstrap/prefs_keys.dart';

/// حالة قفل PIN
class PinLockState {
  final bool isEnabled;
  final String? pinCode;

  const PinLockState({this.isEnabled = false, this.pinCode});

  PinLockState copyWith({bool? isEnabled, String? pinCode}) {
    return PinLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      pinCode: pinCode ?? this.pinCode,
    );
  }
}

/// مزوّد إدارة حالة قفل PIN
final pinLockProvider =
    NotifierProvider<PinLockNotifier, PinLockState>(PinLockNotifier.new);

class PinLockNotifier extends Notifier<PinLockState> {
  @override
  PinLockState build() {
    _loadFromPrefs();
    return const PinLockState();
  }

  Future<void> _loadFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    final enabled = p.getBool(PrefsKeys.pinLockEnabled) ?? false;
    final pin = p.getString(PrefsKeys.pinLockCode);
    state = PinLockState(isEnabled: enabled && pin != null, pinCode: pin);
  }

  /// تعيين رمز PIN جديد وتفعيل القفل
  Future<void> setPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(PrefsKeys.pinLockCode, pin);
    await p.setBool(PrefsKeys.pinLockEnabled, true);
    state = PinLockState(isEnabled: true, pinCode: pin);
  }

  /// تغيير رمز PIN
  Future<void> changePin(String newPin) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(PrefsKeys.pinLockCode, newPin);
    state = state.copyWith(pinCode: newPin);
  }

  /// إيقاف القفل وحذف الرمز
  Future<void> removePin() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(PrefsKeys.pinLockCode);
    await p.setBool(PrefsKeys.pinLockEnabled, false);
    state = const PinLockState(isEnabled: false, pinCode: null);
  }

  /// التحقق من الرمز المدخل
  bool verifyPin(String input) {
    return state.pinCode != null && state.pinCode == input;
  }
}

/// هل يجب عرض شاشة القفل الآن؟
final pinLockGateProvider =
    NotifierProvider<PinLockGateNotifier, bool>(PinLockGateNotifier.new);

class PinLockGateNotifier extends Notifier<bool> {
  @override
  bool build() {
    _init();
    return false;
  }

  Future<void> _init() async {
    final p = await SharedPreferences.getInstance();
    final enabled = p.getBool(PrefsKeys.pinLockEnabled) ?? false;
    final pin = p.getString(PrefsKeys.pinLockCode);
    if (enabled && pin != null) {
      state = true;
    }
  }

  /// عند فتح التطبيق — يتم قفله إن كان PIN مفعلاً
  void lockIfEnabled() {
    final pinState = ref.read(pinLockProvider);
    if (pinState.isEnabled) {
      state = true;
    }
  }

  /// فتح القفل بعد إدخال PIN صحيح
  void unlock() {
    state = false;
  }
}
