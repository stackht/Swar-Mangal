import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:swar_mangal/main.dart';

/// Stable on-device smoke test: proves the real APK builds, installs,
/// launches, and reaches a working shell — adapting to whether the phone
/// already has a saved session or starts fresh on the login screen.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke: login or restore, then shell renders', (tester) async {
    final errors = <String>[];

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exceptionAsString().split('\n').first);
    };

    await tester.pumpWidget(const AcademyApp());
    // Wait for splash → restore or login to settle.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    bool shows(String text) => find.text(text).evaluate().isNotEmpty;

    if (shows('Demo · Founder')) {
      // Fresh install — login screen visible
      await tester.tap(find.text('Demo · Founder'));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (!shows('Home')) errors.add('founder shell did not render after demo login');
    } else if (shows('Home') || shows("Today's Classes")) {
      // Already logged in — shell is visible, good enough
    } else {
      errors.add('unexpected startup state: no login buttons, no shell');
    }

    FlutterError.onError = originalOnError;

    if (errors.isNotEmpty) {
      debugPrint('SMOKE ERRORS: $errors');
    }
    expect(errors, isEmpty);
  });
}
