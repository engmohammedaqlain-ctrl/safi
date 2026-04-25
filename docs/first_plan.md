# 📱 خطة تطوير تطبيق صافي — Flutter + Firebase

> **الإصدار:** v1.0 | **التاريخ:** أبريل 2026 | **الحالة:** جاهز للتنفيذ

---

## 🎯 نظرة عامة

صافي هو تطبيق محاسبة ذكي للتجار الصغار — مبني بـ Flutter مع Firebase كـ backend رئيسي، وHive للتخزين المحلي (Offline-First).

---

## 🏗️ هيكل المشروع الكامل

```
lib/
├── main.dart
├── firebase_options.dart
├── l10n/generated/
├── core/
│   ├── constants/
│   ├── providers/
│   ├── router/
│   ├── services/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   ├── onboarding/
│   ├── home/
│   ├── sales/
│   ├── inventory/
│   ├── debts/
│   ├── reports/
│   ├── cash_flow/
│   ├── ai_assistant/
│   └── settings/
└── shared/
    ├── models/
    ├── repositories/
    └── services/
```

---

## 📦 الحزم المطلوبة (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^3.x
  firebase_auth: ^5.x
  cloud_firestore: ^5.x
  firebase_messaging: ^15.x
  firebase_remote_config: ^5.x
  firebase_analytics: ^11.x

  # State Management
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x

  # Navigation
  go_router: ^14.x

  # Local DB (Offline)
  hive_flutter: ^1.x

  # Barcode Scanner (مستخرج من flutter_billing_app)
  mobile_scanner: ^6.x

  # SMS
  telephony: ^0.2.x          # Android فقط
  url_launcher: ^6.x         # iOS بديل

  # AI / HTTP
  http: ^1.x
  dio: ^5.x

  # UI Helpers
  intl: ^0.19.x
  flutter_localizations:
    sdk: flutter
  cached_network_image: ^3.x
  shimmer: ^3.x
  fl_chart: ^0.69.x
  lottie: ^3.x

  # Utils
  uuid: ^4.x
  shared_preferences: ^2.x
  connectivity_plus: ^6.x
  permission_handler: ^11.x
  path_provider: ^2.x

dev_dependencies:
  build_runner: ^2.x
  riverpod_generator: ^2.x
  hive_generator: ^2.x
  json_serializable: ^6.x
  flutter_gen_runner: ^5.x
```

---

## 🔥 Firebase — الإعداد والهيكل

### Collections في Firestore

```
firestore/
├── shops/{shopId}                    # بيانات المحل الأساسية
│   ├── name, phone, type, currency
│   ├── ownerId, createdAt
│   └── settings/{settingsDoc}
│
├── shops/{shopId}/products/{productId}   # المنتجات والمخزون
│   ├── name, barcode, price, cost
│   ├── quantity, minQuantity
│   └── category, imageUrl
│
├── shops/{shopId}/sales/{saleId}         # سجل المبيعات
│   ├── items[], total, paymentType
│   ├── customerId (optional), isDebt
│   └── createdAt, createdBy
│
├── shops/{shopId}/debts/{debtId}         # الديون
│   ├── customerId, amount, paidAmount
│   ├── dueDate, status
│   └── smsHistory[]
│
├── shops/{shopId}/customers/{customerId} # الزبائن
│   ├── name, phone
│   └── totalDebt
│
└── users/{userId}                        # المستخدمين والصلاحيات
    ├── shopId, role (owner/cashier/admin)
    └── displayName, phone
```

### قواعد Firestore Security

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /shops/{shopId}/{document=**} {
      allow read, write: if request.auth != null
        && exists(/databases/$(database)/documents/users/$(request.auth.uid))
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.shopId == shopId;
    }
  }
}
```

---

## 📲 خدمة الباركود — مستخرجة من flutter_billing_app

### المصدر الأصلي

المشروع المرجعي:
`https://github.com/Dinesh-Sowndar/flutter_billing_app`

يستخدم المشروع الكاميرا لمسح الباركود وربطه بالمنتج مباشرة. نأخذ نفس المنطق ونكيّفه مع هيكل صافي.

### الملف: `lib/core/services/barcode_service.dart`

```dart
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// نتيجة مسح الباركود
class BarcodeResult {
  final String value;
  final BarcodeFormat format;
  final DateTime scannedAt;

  const BarcodeResult({
    required this.value,
    required this.format,
    required this.scannedAt,
  });
}

/// خدمة الباركود — مستوحاة من flutter_billing_app
class BarcodeService {
  // Controller للكاميرا
  MobileScannerController? _controller;

  /// تشغيل الماسح
  MobileScannerController startScanner({
    bool autoStart = true,
    CameraFacing facing = CameraFacing.back,
    List<BarcodeFormat> formats = const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
    ],
  }) {
    _controller = MobileScannerController(
      autoStart: autoStart,
      facing: facing,
      formats: formats,
    );
    return _controller!;
  }

  /// إيقاف الماسح وتحرير الموارد
  Future<void> stopScanner() async {
    await _controller?.stop();
    _controller?.dispose();
    _controller = null;
  }

  /// تشغيل/إيقاف الفلاش
  Future<void> toggleTorch() async {
    await _controller?.toggleTorch();
  }

  /// تحويل نتيجة الباركود الخام إلى BarcodeResult
  BarcodeResult? parseBarcode(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return null;

    return BarcodeResult(
      value: barcode.rawValue!,
      format: barcode.format,
      scannedAt: DateTime.now(),
    );
  }
}

/// Provider للـ BarcodeService
final barcodeServiceProvider = Provider<BarcodeService>(
  (ref) => BarcodeService(),
);
```

### الملف: `lib/core/services/barcode_scanner_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'barcode_service.dart';

/// ويدجت الماسح — يمكن استخدامه في أي شاشة
class BarcodeScannerWidget extends StatefulWidget {
  final void Function(BarcodeResult result) onScanned;
  final bool showTorchButton;

  const BarcodeScannerWidget({
    super.key,
    required this.onScanned,
    this.showTorchButton = true,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  final _service = BarcodeService();
  late MobileScannerController _controller;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = _service.startScanner();
  }

  @override
  void dispose() {
    _service.stopScanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (_hasScanned) return;
            final result = _service.parseBarcode(capture);
            if (result != null) {
              setState(() => _hasScanned = true);
              widget.onScanned(result);
            }
          },
        ),
        // إطار المسح المرئي
        _ScanOverlay(),
        if (widget.showTorchButton)
          Positioned(
            bottom: 32,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white, size: 32),
              onPressed: _service.toggleTorch,
            ),
          ),
      ],
    );
  }
}

/// طبقة المسح المرئية
class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: const Color(0xFF00C896),
          borderRadius: 12,
          borderLength: 30,
          borderWidth: 4,
          cutOutSize: MediaQuery.of(context).size.width * 0.7,
        ),
      ),
    );
  }
}
```

### الاستخدام في شاشة المخزون

```dart
// في inventory_screen.dart
void _openBarcodeScanner(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: BarcodeScannerWidget(
        onScanned: (result) {
          Navigator.pop(context);
          // ابحث عن المنتج بالباركود في Firestore
          ref.read(inventoryProvider.notifier).findByBarcode(result.value);
        },
      ),
    ),
  );
}
```

---

## 📁 تفصيل كل مجلد

### `core/constants/`

```dart
// app_constants.dart
class AppConstants {
  // Firestore Collections
  static const String shopsCollection   = 'shops';
  static const String productsCol       = 'products';
  static const String salesCol          = 'sales';
  static const String debtsCol          = 'debts';
  static const String customersCol      = 'customers';
  static const String usersCollection   = 'users';

  // Hive Boxes
  static const String productsBox       = 'products_local';
  static const String salesBox          = 'sales_local';
  static const String settingsBox       = 'settings';

  // Limits
  static const int lowStockThreshold    = 5;
  static const int maxDebtReminders     = 3;
  static const Duration syncInterval    = Duration(minutes: 5);

  // Route Names
  static const String routeSplash       = '/';
  static const String routeLogin        = '/login';
  static const String routeOnboarding   = '/onboarding';
  static const String routeHome         = '/home';
  static const String routeSales        = '/sales';
  static const String routeInventory    = '/inventory';
  static const String routeDebts        = '/debts';
  static const String routeReports      = '/reports';
  static const String routeAI           = '/ai-assistant';
  static const String routeSettings     = '/settings';
}
```

### `core/providers/`

```
providers/
├── theme_provider.dart          # ثيم التطبيق (فاتح/داكن)
├── settings_provider.dart       # إعدادات المحل (العملة، اللغة)
├── connectivity_provider.dart   # مراقبة الاتصال بالإنترنت
└── sync_provider.dart           # مزامنة Hive ↔ Firestore
```

### `core/router/`

```dart
// app_router.dart — go_router مع Shell للـ Bottom Nav
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authStateProvider).value != null;
      if (!isLoggedIn && state.fullPath != AppConstants.routeLogin) {
        return AppConstants.routeLogin;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home',      builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/sales',     builder: (_, __) => const SalesScreen()),
          GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
          GoRoute(path: '/debts',     builder: (_, __) => const DebtsScreen()),
          GoRoute(path: '/reports',   builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/ai-assistant', builder: (_, __) => const AIAssistantScreen()),
          GoRoute(path: '/settings',  builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
```

### `core/services/`

```
services/
├── barcode_service.dart         # ✅ مشروحة بالتفصيل أعلاه
├── sms_service.dart             # إرسال SMS للديون
├── ai_service.dart              # OpenAI / Gemini API
├── fcm_service.dart             # Firebase Cloud Messaging
└── remote_config_service.dart   # Feature flags
```

### `shared/models/`

```dart
// product.dart
@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String barcode;
  @HiveField(3) double price;
  @HiveField(4) double cost;
  @HiveField(5) int quantity;
  @HiveField(6) int minQuantity;
  @HiveField(7) String category;
  String shopId;
  DateTime updatedAt;
  bool isSynced;          // هل متزامن مع Firestore؟
}

// sale.dart
@HiveType(typeId: 1)
class Sale extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) List<SaleItem> items;
  @HiveField(2) double total;
  @HiveField(3) PaymentType paymentType; // cash / debt / partial
  @HiveField(4) String? customerId;
  @HiveField(5) DateTime createdAt;
  String shopId;
  bool isSynced;
}

// debt.dart
@HiveType(typeId: 2)
class Debt extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String customerId;
  @HiveField(2) double amount;
  @HiveField(3) double paidAmount;
  @HiveField(4) DebtStatus status; // active / partial / paid
  @HiveField(5) DateTime? dueDate;
  @HiveField(6) List<String> smsHistory;
  String shopId;
}
```

### `shared/repositories/`

```dart
// product_repository.dart
abstract class IProductRepository {
  Future<List<Product>> getAll();
  Future<Product?> getByBarcode(String barcode);
  Future<void> save(Product product);
  Future<void> updateQuantity(String id, int delta);
  Stream<List<Product>> watchLowStock();
}

// تطبيق Firestore
class FirestoreProductRepository implements IProductRepository {
  final FirebaseFirestore _db;
  final String _shopId;

  @override
  Future<Product?> getByBarcode(String barcode) async {
    final snap = await _db
        .collection('shops/$_shopId/products')
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Product.fromJson(snap.docs.first.data());
  }
  // ...
}

// تطبيق Hive (Offline)
class HiveProductRepository implements IProductRepository {
  final Box<Product> _box;
  // ...
}
```

### `shared/services/`

```dart
// firestore_service.dart — CRUD عام
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> set(String path, Map<String, dynamic> data) async {
    await _db.doc(path).set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> get(String path) async {
    final snap = await _db.doc(path).get();
    return snap.data();
  }

  Stream<QuerySnapshot> watch(String collection, {
    List<QueryFilter> filters = const [],
    String? orderBy,
    int? limit,
  }) {
    Query query = _db.collection(collection);
    for (final f in filters) {
      query = query.where(f.field, isEqualTo: f.value);
    }
    if (orderBy != null) query = query.orderBy(orderBy, descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots();
  }
}

// local_db_service.dart — Hive Wrapper
class LocalDbService {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(SaleAdapter());
    Hive.registerAdapter(DebtAdapter());
    await Hive.openBox<Product>(AppConstants.productsBox);
    await Hive.openBox<Sale>(AppConstants.salesBox);
    await Hive.openBox(AppConstants.settingsBox);
  }
}
```

---

## 📋 تفصيل كل Feature

### 1. `auth/`

```
auth/
├── screens/
│   ├── splash_screen.dart
│   └── login_screen.dart       # رقم هاتف + SMS OTP
├── providers/
│   └── auth_provider.dart      # FirebaseAuth state
└── services/
    └── auth_service.dart       # signInWithPhone, verifyOTP, signOut
```

**المنطق:**
- تسجيل برقم الهاتف + OTP عبر Firebase Phone Auth
- حفظ بيانات المستخدم في `users/{uid}`
- ربط المستخدم بـ `shopId` عند التسجيل الأول

### 2. `onboarding/`

```
onboarding/
├── screens/
│   └── onboarding_screen.dart  # 4 خطوات تعليمية
└── providers/
    └── onboarding_provider.dart
```

**الخطوات الأربع:**
1. أضف منتجك الأول (بالباركود أو يدوياً)
2. سجّل أول بيعة
3. أضف زبون مدين
4. جرّب إرسال SMS

### 3. `sales/`

```
sales/
├── screens/
│   ├── sales_screen.dart       # لوحة البيع السريع
│   ├── cart_screen.dart        # السلة
│   └── receipt_screen.dart     # الفاتورة
├── providers/
│   ├── cart_provider.dart
│   └── sales_provider.dart
└── widgets/
    ├── product_tile.dart
    ├── barcode_button.dart     # يفتح BarcodeScannerWidget
    └── payment_modal.dart      # نقدي / آجل / جزئي
```

**المنطق الأساسي:**
1. المستخدم يضغط زر الباركود → `BarcodeScannerWidget` يفتح
2. يمسح الباركود → يبحث في Hive أولاً، ثم Firestore
3. يضيف المنتج للسلة
4. عند الدفع: اختيار نقدي أو آجل
5. إذا آجل: ينشئ `Debt` تلقائياً ويربطه بالزبون

### 4. `inventory/`

```
inventory/
├── screens/
│   ├── inventory_screen.dart   # قائمة المنتجات
│   └── add_product_screen.dart # إضافة/تعديل منتج
├── providers/
│   └── inventory_provider.dart
└── widgets/
    ├── product_card.dart
    ├── low_stock_alert.dart
    └── barcode_scanner_button.dart
```

**ربط الباركود بالمنتج:**
```dart
// عند إضافة منتج جديد
void _scanBarcode() async {
  final result = await showModalBottomSheet<BarcodeResult>(
    context: context,
    builder: (_) => BarcodeScannerWidget(
      onScanned: (r) => Navigator.pop(context, r),
    ),
  );
  if (result != null) {
    barcodeController.text = result.value;
  }
}
```

### 5. `debts/`

```
debts/
├── screens/
│   ├── debts_screen.dart       # قائمة الديون
│   └── debt_detail_screen.dart # تفاصيل دين + تاريخ SMS
├── providers/
│   └── debts_provider.dart
└── widgets/
    ├── debt_card.dart
    ├── sms_composer_modal.dart  # AI يكتب الرسالة
    └── payment_log_tile.dart
```

### 6. `ai_assistant/`

```
ai_assistant/
├── screens/
│   └── ai_chat_screen.dart     # محادثة مع AI
├── providers/
│   └── ai_provider.dart
└── services/
    └── (يستخدم core/services/ai_service.dart)
```

**وظائف الـ AI:**
- كتابة رسائل SMS للديون (ودي / رسمي / حازم)
- تحليل المبيعات ("ليش نقصت مبيعاتي؟")
- اقتراح المنتجات الأكثر ربحية
- تنبيهات المخزون المنخفض

### 7. `reports/`

```
reports/
├── screens/
│   ├── reports_screen.dart
│   └── cash_flow_screen.dart
├── providers/
│   └── reports_provider.dart
└── widgets/
    ├── revenue_chart.dart       # fl_chart
    ├── profit_card.dart
    └── date_filter_bar.dart
```

---

## 🔄 نظام المزامنة (Offline-First)

```dart
// sync_provider.dart
class SyncNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> syncAll() async {
    // 1. تحقق من الاتصال
    final hasInternet = await ref.read(connectivityProvider.future);
    if (!hasInternet) return;

    // 2. ارفع كل السجلات غير المزامنة من Hive
    final pendingSales = Hive.box<Sale>(AppConstants.salesBox)
        .values.where((s) => !s.isSynced).toList();

    for (final sale in pendingSales) {
      await ref.read(firestoreServiceProvider).set(
        'shops/${sale.shopId}/sales/${sale.id}',
        sale.toJson(),
      );
      sale.isSynced = true;
      await sale.save();
    }

    // 3. نفس المنطق للمنتجات والديون
  }
}

// يعمل تلقائياً كل 5 دقائق + عند عودة الاتصال
```

---

## 🔔 Firebase Cloud Messaging (FCM)

```dart
// fcm_service.dart
class FCMService {
  Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen((message) {
      // إشعار داخل التطبيق
      _showLocalNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(_handleBackground);
  }

  // تذكيرات الديون التلقائية
  Future<void> scheduleDebtReminder(Debt debt) async {
    // يرسل Cloud Function إشعار عند اقتراب موعد الدفع
  }
}
```

---

## 📨 خدمة SMS

```dart
// sms_service.dart
class SmsService {
  /// إرسال SMS مباشر (Android - telephony)
  Future<bool> sendSms({
    required String phone,
    required String message,
  }) async {
    try {
      final telephony = Telephony.instance;
      final canSend = await telephony.requestSmsPermissions;
      if (canSend != true) return false;

      await telephony.sendSms(
        to: phone,
        message: message,
      );
      return true;
    } catch (e) {
      // iOS بديل: فتح تطبيق الرسائل
      final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
      return launchUrl(uri);
    }
  }
}
```

---

## 🌐 خدمة AI

```dart
// ai_service.dart
class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  /// كتابة رسالة SMS للمدين
  Future<String> generateDebtSms({
    required String customerName,
    required double amount,
    required String tone, // ودي / رسمي / حازم
    required String currency,
  }) async {
    final prompt = '''
أنت مساعد لكتابة رسائل تحصيل ديون للتجار.
اكتب رسالة SMS قصيرة (أقل من 160 حرف) بنبرة $tone باللغة العربية العامية.
الزبون: $customerName
المبلغ: $amount $currency
الرسالة يجب أن تكون محترمة وتذكّر بالدين.
''';

    final response = await _callAPI(prompt);
    return response;
  }

  /// تحليل المبيعات
  Future<String> analyzeSales(Map<String, dynamic> salesData) async {
    final prompt = 'حلّل هذه البيانات وأعطني 3 توصيات: ${jsonEncode(salesData)}';
    return _callAPI(prompt);
  }

  Future<String> _callAPI(String prompt) async {
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConstants.openAiKey}',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [{'role': 'user', 'content': prompt}],
        'max_tokens': 200,
      }),
    );
    final data = jsonDecode(res.body);
    return data['choices'][0]['message']['content'];
  }
}
```

---

## 📏 ترتيب التطوير (مراحل)

### المرحلة 1 — الأساس (أسبوع 1-2)
- [ ] إعداد Firebase (Auth, Firestore, FCM)
- [ ] هيكل المجلدات كاملاً
- [ ] `local_db_service.dart` + Hive init
- [ ] `firestore_service.dart`
- [ ] `auth/` — تسجيل وتسجيل دخول بالهاتف
- [ ] `core/router/` — go_router كامل

### المرحلة 2 — القلب (أسبوع 3-4)
- [ ] `shared/models/` — Product, Sale, Debt, Customer
- [ ] `shared/repositories/` — Firestore + Hive
- [ ] `inventory/` — إضافة منتجات + مسح الباركود
- [ ] `barcode_service.dart` — مستخرج من flutter_billing_app

### المرحلة 3 — البيع والديون (أسبوع 5-6)
- [ ] `sales/` — سلة البيع السريع + 3 خطوات
- [ ] `debts/` — قائمة الديون + تتبع الدفعات
- [ ] `sms_service.dart` — إرسال تذكيرات

### المرحلة 4 — الذكاء والتقارير (أسبوع 7-8)
- [ ] `ai_assistant/` — SMS ذكي + تحليل
- [ ] `reports/` — رسوم بيانية + تدفق نقدي
- [ ] `sync_provider.dart` — مزامنة Offline↔Online
- [ ] `fcm_service.dart` — إشعارات

### المرحلة 5 — الإنهاء (أسبوع 9-10)
- [ ] `onboarding/` — تجربة أول مستخدم
- [ ] `settings/` — الفريق والصلاحيات
- [ ] اختبار شامل + تحسين الأداء
- [ ] نشر على Google Play + App Store

---

## ⚡ نقاط مهمة

| الموضوع | القرار |
|---------|--------|
| State Management | Riverpod 2 (Annotation) |
| Navigation | go_router + ShellRoute |
| Offline | Hive أولاً، Firestore مزامنة |
| Barcode | mobile_scanner (مستوحى من flutter_billing_app) |
| AI | OpenAI GPT-4o-mini |
| SMS | telephony (Android) / url_launcher (iOS) |
| Charts | fl_chart |
| Auth | Firebase Phone Auth + OTP |
| Security | Firestore Rules مبنية على shopId |

---

## 🔑 ملاحظات نهائية

1. **الباركود:** مستخرج من مشروع Dinesh-Sowndar، استُبدل `get_it` بـ `Riverpod` و`hive` بـ `Firestore`. المنطق الأساسي (CameraX + ML Kit) محافظ عليه عبر `mobile_scanner`.

2. **Offline-First:** كل عملية تُحفظ أولاً في Hive محلياً، ثم تُزامن مع Firestore عند الاتصال — التاجر لن يخسر أي بيانات.

3. **الأمان:** كل طلب Firestore مقيّد بـ `shopId` الخاص بالمستخدم — لا أحد يرى بيانات محل غيره.

4. **التوسعية:** هيكل الـ features مستقل تماماً — يمكن إضافة `loyalty/` أو `suppliers/` بسهولة في v2.
