import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safi/app.dart';
import 'package:safi/core/bootstrap/prefs_keys.dart';
import 'package:safi/core/bootstrap/startup_ledger_data.dart';

void main() {
  testWidgets('Safi app loads with Arabic shell after session gate', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      PrefsKeys.loggedIn: true,
      PrefsKeys.onboardingDone: true,
      PrefsKeys.userName: 'مستخدم',
    });
    await StartupLedgerData.load();

    await tester.pumpWidget(
      const ProviderScope(child: SafiApp()),
    );
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    expect(find.text('دفتر الديون'), findsOneWidget);
  });
}
