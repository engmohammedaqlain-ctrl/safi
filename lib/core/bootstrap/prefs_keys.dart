/// مفاتيح التخزين المحلي لمسار التطبيق
abstract final class PrefsKeys {
  static const loggedIn = 'safi_logged_in';

  /// شرائح الترحيب قبل أول إدخال لرقم الهاتف — لا تُمسح عند تسجيل الخروج.
  static const welcomeOnboardingDone = 'safi_welcome_onboarding_done';

  /// قديم: كان يُستخدم بعد الدخول؛ يُقرأ للترقية من إصدارات سابقة فقط.
  static const onboardingDone = 'safi_onboarding_done';
  static const userName = 'safi_user_name';

  /// عنوان فرعية بطاقة المتجر (محلياً؛ التقارير تستخدم الاسم مع [userName]).
  static const storeCurrencyLabel = 'safi_store_currency_label';
  static const storeAddress = 'safi_store_address';

  /// آخر [User.uid] لربط المحتوى المحفوظ محلياً بحساب Firebase (يطابق دفتر الحافظة).
  static const ledgerOwnerUid = 'safi_ledger_owner_uid';

  /// آخر مستند مسجِّل لتسجيل الدخول (أرقام فقط لـ [registered_phones]).
  static const phoneDocId = 'safi_phone_doc_id';

  /// عند `true` (الافتراضي): الرصيد الفعلي للمحفظة يشمل تأثير الديون/السداد المربوطة بها.
  static const includeDebtsInWalletBalance =
      'safi_include_debts_in_wallet_balance';

  static const debtors = 'safi_ledger_debtors_v1';
  static const transactions = 'safi_ledger_transactions_v1';
  static const cashbook = 'safi_ledger_cashbook_v1';

  static const accounts = 'safi_accounts_v1';
  static const debtCategories = 'safi_debt_categories_v1';

  /// آخر طابع زمني طبّقناه مع سحب/دفع سحابي للحافظة (مطابقة بسيطة).
  static const lastLedgerSyncedMs = 'safi_last_ledger_synced_ms';

  /// صلاحيات المستخدم الحالي (المالك أو عضو فريق)
  static const userRole = 'safi_user_role'; // 'owner', 'cashier', 'viewer'
  static const userPermissions = 'safi_user_permissions'; // List<String>

  /// محادثة المساعد الذكي (محلياً + تُرفع إلى `users/{uid}/ai_history`)
  static const aiChatHistory = 'safi_ai_chat_history';
}
