import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safi/app.dart';
import 'package:safi/core/bootstrap/prefs_keys.dart';

void main() {
  testWidgets('Safi app loads with Arabic shell after session gate', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      PrefsKeys.loggedIn: true,
      PrefsKeys.onboardingDone: true,
    });

    await tester.pumpWidget(
      const ProviderScope(child: SafiApp()),
    );
    // شاشة البداية (≈1.6s) ثم التطبيق
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('لوحة التحكم'), findsOneWidget);
  });
}
