# PRD — تطبيق الديون والكاشير (Debt & Cashier App)

**Flutter Mobile Application — Product Requirements Document**  
Version: 1.0 | Date: 2026-04-26 | Direction: RTL (Arabic)

---

## 1. نظرة عامة / Overview

تطبيق موبايل مخصص لأصحاب المحلات التجارية لإدارة ديون العملاء وتشغيل نقطة بيع سريعة مع مسح الباركود. يعمل بالكامل باللغة العربية ومن اليمين إلى اليسار.

**المنصة:** Flutter (Android + iOS)  
**الحالة:** MVP Phase 1  
**التخزين:** Local (Hive / SQLite) — بدون سيرفر في المرحلة الأولى

---

## 2. الهوية البصرية / Design Tokens

```dart
// lib/core/theme/app_colors.dart
class AppColors {
  static const primary   = Color(0xFF7B68EE); // أرجواني هادئ
  static const success   = Color(0xFF2ECC71); // أخضر للموجب
  static const danger    = Color(0xFFE74C3C); // أحمر للديون/المصروف
  static const surface   = Color(0xFFFFFFFF);
  static const bgLight   = Color(0xFFF8F8FA);
  static const textMain  = Color(0xFF1A1A2E);
  static const textMuted = Color(0xFF8E8E9A);
  static const border    = Color(0xFFEEEEF4);
}
```

---

## 3. هيكل مجلدات المشروع / Folder Structure

```
lib/
│
├── main.dart
├── app.dart                          # MaterialApp + ThemeData + RTL
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart            # ThemeData (light)
│   ├── constants/
│   │   └── app_strings.dart          # كل النصوص العربية
│   ├── utils/
│   │   ├── currency_formatter.dart   # تنسيق العملة
│   │   ├── date_formatter.dart       # تنسيق التاريخ بالعربي
│   │   └── validators.dart
│   └── widgets/                      # Widgets مشتركة
│       ├── app_bar_widget.dart
│       ├── bottom_nav_bar.dart       # شريط التنقل الثلاثي
│       ├── custom_card.dart
│       ├── amount_badge.dart         # شارة المبلغ (أخضر/أحمر)
│       └── empty_state_widget.dart
│
├── features/
│   │
│   ├── debts/                        ── تبويب ١: الديون ──
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── customer_model.dart
│   │   │   │   └── debt_record_model.dart
│   │   │   └── repositories/
│   │   │       └── debt_repository.dart
│   │   ├── domain/
│   │   │   └── debt_service.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── debts_home_screen.dart      # قائمة العملاء المدينين
│   │       │   ├── customer_detail_screen.dart  # ملف زبون + سجل الديون
│   │       │   ├── add_debt_screen.dart         # إضافة دين جديد
│   │       │   ├── add_payment_screen.dart      # تسجيل سداد
│   │       │   └── alerts_screen.dart           # تنبيهات الديون المتأخرة
│   │       ├── widgets/
│   │       │   ├── customer_card.dart
│   │       │   ├── debt_list_item.dart
│   │       │   ├── payment_list_item.dart
│   │       │   └── debt_summary_header.dart     # بطاقة الإجمالي العلوية
│   │       └── controllers/
│   │           └── debt_controller.dart         # (Provider / Riverpod)
│   │
│   ├── shop/                         ── تبويب ٢: المحل ──
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── product_model.dart
│   │   │   │   ├── cart_item_model.dart
│   │   │   │   └── sale_model.dart
│   │   │   └── repositories/
│   │   │       ├── product_repository.dart
│   │   │       └── sale_repository.dart
│   │   ├── domain/
│   │   │   ├── cart_service.dart
│   │   │   └── sale_service.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── cashier_screen.dart           # الكاشير الرئيسي
│   │       │   ├── barcode_scanner_screen.dart   # مسح الباركود
│   │       │   └── receipt_screen.dart           # الإيصال / الفاتورة
│   │       ├── widgets/
│   │       │   ├── cart_item_tile.dart
│   │       │   ├── product_search_bar.dart
│   │       │   ├── numpad_widget.dart            # لوحة الأرقام
│   │       │   ├── cart_summary_bar.dart         # شريط الإجمالي السفلي
│   │       │   └── scanner_overlay.dart          # إطار المسح المرئي
│   │       └── controllers/
│   │           ├── cart_controller.dart
│   │           └── scanner_controller.dart
│   │
│   └── more/                         ── تبويب ٣: المزيد ──
│       ├── data/
│       │   └── models/
│       │       └── shop_settings_model.dart
│       └── presentation/
│           ├── screens/
│           │   ├── more_home_screen.dart         # قائمة الإعدادات
│           │   ├── shop_info_screen.dart          # معلومات المحل + الشعار
│           │   ├── general_settings_screen.dart   # العملة، اللغة، الثيم
│           │   └── backup_screen.dart             # نسخ احتياطي / استعادة
│           └── widgets/
│               ├── settings_tile.dart
│               └── section_header.dart
│
└── shared/
    ├── local_storage/
    │   ├── hive_boxes.dart           # تعريف صناديق Hive
    │   └── db_helper.dart
    └── services/
        ├── notification_service.dart # تنبيهات الديون المتأخرة
        └── share_service.dart        # مشاركة الإيصال
```

---

## 4. نماذج البيانات / Data Models

```dart
// customer_model.dart
class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final DateTime createdAt;
  double get totalDebt; // محسوب من debt_records
}

// debt_record_model.dart
class DebtRecordModel {
  final String id;
  final String customerId;
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime? dueDate;       // تاريخ الاستحقاق (للتنبيهات)
  final DebtStatus status;       // open / partial / paid
  final List<PaymentModel> payments;
}

// product_model.dart
class ProductModel {
  final String id;
  final String name;
  final String? barcode;
  final double price;
  final int? stock;
}

// sale_model.dart
class SaleModel {
  final String id;
  final List<CartItemModel> items;
  final double total;
  final double paid;
  final double change;
  final DateTime date;
  final String? customerId; // إذا اشترى زبون مدين
}
```

---

## 5. تفاصيل الشاشات / Screen Specifications

### ── تبويب الديون ──

#### 5.1 `debts_home_screen.dart` — قائمة العملاء المدينين

- Header card: إجمالي الديون الكلي (أحمر) + عدد العملاء
- Search bar: بحث بالاسم أو الرقم
- ListView: بطاقة لكل زبون (الاسم + المبلغ المتبقي + آخر حركة)
- FAB: زر إضافة زبون جديد / دين جديد
- Badge: تنبيه مرئي على العملاء المتأخرين

#### 5.2 `customer_detail_screen.dart` — ملف الزبون

- Header: اسم الزبون + رقمه + إجمالي دينه
- Tabs داخلية: الديون / المدفوعات
- Timeline: قائمة زمنية للحركات (دين + سداد)
- Buttons: إضافة دين جديد | تسجيل سداد

#### 5.3 `add_debt_screen.dart` — إضافة دين

- Input: المبلغ (numpad)
- Input: الملاحظة (اختياري)
- DatePicker: تاريخ الاستحقاق (اختياري)
- Customer selector إذا فُتحت من الرئيسية

#### 5.4 `alerts_screen.dart` — التنبيهات

- List: الديون التي تجاوزت تاريخ الاستحقاق
- مرتبة من الأقدم إلى الأحدث
- زر اتصال سريع (phone_launcher)

---

### ── تبويب المحل ──

#### 5.5 `cashier_screen.dart` — الكاشير

- Search bar علوي: بحث عن منتج بالاسم
- زر كاميرا: يفتح `barcode_scanner_screen`
- ListView: السلة الحالية مع الكميات
- Bottom bar ثابت: الإجمالي + زر "إتمام البيع"
- Numpad: لإدخال الكميات أو مبلغ مخصص

#### 5.6 `barcode_scanner_screen.dart` — مسح الباركود

- Camera preview ممتلئ الشاشة
- Overlay: إطار مسح مرئي + خط متحرك
- يستخدم: `mobile_scanner` package
- عند النجاح: يعود ويضيف المنتج للسلة تلقائياً
- إذا لم يُعرف الباركود: نافذة لإضافة منتج جديد

#### 5.7 `receipt_screen.dart` — الإيصال

- عرض تفاصيل الفاتورة: المنتجات + الكميات + الأسعار
- الإجمالي + المبلغ المدفوع + الباقي
- زر: مشاركة (WhatsApp / Screenshot)
- زر: طباعة (Bluetooth printer — Phase 2)

---

### ── تبويب المزيد ──

#### 5.8 `shop_info_screen.dart` — معلومات المحل

- اسم المحل، رقم الهاتف، العنوان
- رفع شعار المحل (يظهر في الإيصال)

#### 5.9 `general_settings_screen.dart` — الإعدادات العامة

- اختيار العملة (₪ / $ / د.أ / ر.س)
- تنبيهات الديون: تشغيل/إيقاف + عدد الأيام
- لون التطبيق الرئيسي (اختياري)

#### 5.10 `backup_screen.dart` — النسخ الاحتياطي

- تصدير البيانات (JSON)
- استيراد من ملف
- مشاركة الملف عبر التطبيقات

---

## 6. الـ Packages المقترحة

```yaml
# pubspec.yaml dependencies

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.0 # أو provider حسب التفضيل

  # Local Storage
  hive_flutter: ^1.1.0
  hive: ^2.2.3

  # Barcode Scanner
  mobile_scanner: ^5.1.0

  # Navigation
  go_router: ^13.0.0

  # UI Utilities
  flutter_slidable: ^3.1.0 # سحب لحذف/تعديل
  intl: ^0.19.0 # تنسيق التاريخ والأرقام العربية

  # Share & Launch
  share_plus: ^9.0.0
  url_launcher: ^6.3.0 # اتصال سريع

  # Image Picker (شعار المحل)
  image_picker: ^1.1.0

  # Notifications
  flutter_local_notifications: ^17.0.0

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.0
```

---

## 7. إدارة الحالة / State Management

```
Pattern: Riverpod (StateNotifier)

Providers:
  - debtListProvider        → قائمة العملاء + إجماليات
  - customerDetailProvider  → ملف زبون واحد
  - cartProvider            → سلة الكاشير الحالية
  - settingsProvider        → إعدادات التطبيق
  - alertsProvider          → الديون المتأخرة
```

---

## 8. التنقل / Navigation

```
/                     → main_shell (BottomNavBar)
  /debts              → debts_home_screen
    /debts/:id        → customer_detail_screen
    /debts/add        → add_debt_screen
    /debts/alerts     → alerts_screen
  /shop               → cashier_screen
    /shop/scanner     → barcode_scanner_screen
    /shop/receipt/:id → receipt_screen
  /more               → more_home_screen
    /more/shop-info   → shop_info_screen
    /more/settings    → general_settings_screen
    /more/backup      → backup_screen
```

---

## 9. مراحل التطوير / Milestones

| المرحلة | الميزات                                 | الوقت التقديري |
| ------- | --------------------------------------- | -------------- |
| MVP     | الديون الأساسية (إضافة/سداد/قائمة)      | أسبوعان        |
| v1.1    | الكاشير + مسح الباركود                  | أسبوع          |
| v1.2    | التنبيهات + الإعدادات + النسخ الاحتياطي | أسبوع          |
| v2.0    | طباعة بلوتوث + مزامنة سحابية            | مرحلة مستقبلية |

---

## 10. ملاحظات تقنية

- **RTL:** تُضبط في `main.dart` عبر `Directionality(textDirection: TextDirection.rtl)`
- **الخط:** استخدام `Cairo` أو `Tajawal` من Google Fonts للواجهة العربية
- **الكاميرا:** تحتاج صلاحيات `CAMERA` في `AndroidManifest.xml` و `Info.plist`
- **الإشعارات:** جدولة يومية للتحقق من الديون المتأخرة عند الفتح أو في الخلفية
- **الأداء:** استخدام `const` widgets وتجنب إعادة البناء غير الضرورية

---

_PRD generated for: تطبيق الديون والكاشير | Flutter MVP_
