/// مفاتيح التخزين المحلي لمسار التطبيق
abstract final class PrefsKeys {
  static const loggedIn = 'safi_logged_in';
  static const onboardingDone = 'safi_onboarding_done';
  static const userName = 'safi_user_name';

  /// آخر [User.uid] لربط المحتوى المحفوظ محلياً بحساب Firebase (يطابق دفتر الحافظة).
  static const ledgerOwnerUid = 'safi_ledger_owner_uid';

  /// آخر مستند مسجِّل لتسجيل الدخول (أرقام فقط لـ [registered_phones]).
  static const phoneDocId = 'safi_phone_doc_id';
  static const debtors = 'safi_ledger_debtors_v1';
  static const transactions = 'safi_ledger_transactions_v1';
  static const cashbook = 'safi_ledger_cashbook_v1';

  static const accounts = 'safi_accounts_v1';
  static const debtCategories = 'safi_debt_categories_v1';

  /// آخر طابع زمني طبّقناه مع سحب/دفع سحابي للحافظة (مطابقة بسيطة).
  static const lastLedgerSyncedMs = 'safi_last_ledger_synced_ms';
}
