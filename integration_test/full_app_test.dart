import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:swar_mangal/main.dart';

/// Full on-device walk-through. Screenshots every screen and COLLECTS errors
/// (exceptions, layout overflows) instead of stopping at the first one.
///
/// It adapts to the state the phone is in, and never destroys a real login:
///  * Login screen showing  -> DEMO mode for founder and staff, including
///    interactions (demo writes nothing).
///  * A real saved session  -> READ-ONLY walk of that role: opens every
///    screen, presses no action buttons, and does NOT sign out.
///
/// Run with screenshots:
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/full_app_test.dart -d DEVICE_ID
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const founderScreens = [
    'Home', 'Approvals', 'Students', 'Add Student', 'Add Fee', 'Receipts', 'Teachers',
    'Expenses & Cashbook', 'Teacher Payouts', 'Timetable', 'School Invoice', 'Activity Log', 'About',
  ];
  const staffScreens = [
    'Today', "Today's Classes", 'Students', 'Add Student (Draft)', 'Attendance', 'Add Fee',
    'Receipts', 'Expenses', 'Inquiries', 'My Requests', 'Timetable', 'School Invoice', 'About',
  ];

  testWidgets('every screen, adapting to the phone state', (tester) async {
    final errors = <String>[];
    final visited = <String>[];
    var where = 'startup';
    var shot = 0;
    var mode = 'unknown';

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add('[$where] ${details.exceptionAsString().split('\n').first}');
    };

    Future<void> settle([int ms = 1500]) async {
      // Ambient animations never fully settle, so pump through the latency.
      for (var i = 0; i < ms ~/ 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    void collect() {
      final e = tester.takeException();
      if (e != null) errors.add('[$where] ${e.toString().split('\n').first}');
    }

    bool shows(String text) => find.text(text).evaluate().isNotEmpty;

    Future<void> screenshot(String name) async {
      shot++;
      final safe = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      try {
        await binding.takeScreenshot('${shot.toString().padLeft(2, '0')}_$safe');
      } catch (_) {
        // Only works under `flutter drive`; `flutter test` still walks every screen.
      }
    }

    Future<bool> openScreen(String label) async {
      where = label;
      final menu = find.byTooltip('Open navigation menu');
      if (menu.evaluate().isEmpty) {
        errors.add('[$label] navigation menu button not found');
        return false;
      }
      await tester.tap(menu);
      await settle(700);
      final item = find.descendant(of: find.byType(Drawer), matching: find.text(label));
      if (item.evaluate().isEmpty) {
        // The drawer list is lazy: items below the fold are not built yet.
        final scrollable = find.descendant(of: find.byType(Drawer), matching: find.byType(Scrollable));
        if (scrollable.evaluate().isNotEmpty) {
          try {
            await tester.scrollUntilVisible(item, 150, scrollable: scrollable.first, maxScrolls: 20);
            await settle(300);
          } catch (_) {
            // falls through to the "not present" report below
          }
        }
      }
      if (item.evaluate().isEmpty) {
        errors.add('[$label] not present in the drawer');
        final nav = tester.state<NavigatorState>(find.byType(Navigator).last);
        nav.maybePop();
        await settle(500);
        return false;
      }
      await tester.ensureVisible(item.first);
      await settle(300);
      await tester.tap(item.first, warnIfMissed: false);
      await settle(2500);
      collect();
      final title = find.descendant(of: find.byType(AppBar), matching: find.text(label));
      if (title.evaluate().isEmpty) errors.add('[$label] app bar title did not switch');
      visited.add('$mode:$label');
      return true;
    }

    Future<void> walk(String role, List<String> screens, {required bool interact}) async {
      for (final label in screens) {
        if (!await openScreen(label)) continue;
        await screenshot('$mode $role $label');
        if (!interact) continue;

        if (label == 'Students') {
          final field = find.byType(TextField);
          if (field.evaluate().isNotEmpty) {
            await tester.enterText(field.first, 'a');
            await settle();
            collect();
            await screenshot('$mode $role students search');
          }
        }
        if (label == 'Teacher Payouts' && shows('Record payment')) {
          await tester.ensureVisible(find.text('Record payment').first);
          await settle(300);
          await tester.tap(find.text('Record payment').first, warnIfMissed: false);
          await settle(1000);
          collect();
          await screenshot('$mode payout dialog');
          final confirm = find.widgetWithText(FilledButton, 'Record');
          if (confirm.evaluate().isEmpty) {
            errors.add('[Teacher Payouts] record dialog has no Record button');
          } else {
            await tester.tap(confirm);
            await settle(2500);
            collect();
            await screenshot('$mode payout recorded');
          }
        }
        if (label == 'Activity Log') {
          if (!shows('Mark attendance')) errors.add('[Activity Log] demo "Mark attendance" entry missing');
          if (shows('Failures only')) {
            await tester.tap(find.text('Failures only'));
            await settle();
            collect();
            await screenshot('$mode activity failures');
          }
        }
      }
    }

    // ------------------------------------------------------------- startup
    await tester.pumpWidget(const AcademyApp());
    await settle(5000);
    collect();
    await binding.convertFlutterSurfaceToImage();
    await settle(300);
    await screenshot('startup');

    if (shows('Demo · Founder')) {
      // ============================================ DEMO: founder then staff
      mode = 'demo';
      where = 'demo founder login';
      await tester.tap(find.text('Demo · Founder'));
      await settle(3000);
      collect();
      await walk('founder', founderScreens, interact: true);

      where = 'dark mode';
      if (await openScreen('Home')) {
        final dark = find.byTooltip('Dark mode');
        if (dark.evaluate().isNotEmpty) {
          await tester.tap(dark);
          await settle(1500);
          collect();
          await screenshot('demo founder home dark');
          final light = find.byTooltip('Light mode');
          if (light.evaluate().isNotEmpty) {
            await tester.tap(light);
            await settle(1500);
          }
        }
      }

      where = 'demo founder sign out'; // demo sessions are memory-only
      await tester.tap(find.byTooltip('Sign out'));
      await settle(2500);
      collect();
      if (!shows('Demo · Staff')) errors.add('[demo founder sign out] did not return to login');

      where = 'demo staff login';
      await tester.tap(find.text('Demo · Staff'));
      await settle(3000);
      collect();
      await screenshot('demo staff branch gate');
      if (!shows('Choose your branch')) errors.add('[demo staff login] branch gate missing');
      await tester.tap(find.text('GOREGAON'));
      await settle(3000);
      collect();
      await walk('staff', staffScreens, interact: true);

      where = 'demo staff sign out';
      await tester.tap(find.byTooltip('Sign out'));
      await settle(2500);
      collect();
    } else {
      // ============================ REAL SESSION: read-only, never sign out
      mode = 'live';
      if (shows('Choose your branch')) {
        where = 'live branch gate';
        await screenshot('live branch gate');
        await tester.tap(find.text('KANDIVALI'));
        await settle(5000);
        collect();
      }
      final isFounder = find
          .descendant(of: find.byType(AppBar), matching: find.text('Home'))
          .evaluate()
          .isNotEmpty;
      await walk(isFounder ? 'founder' : 'staff', isFounder ? founderScreens : staffScreens,
          interact: false);
    }

    FlutterError.onError = originalOnError;

    debugPrint('MODE $mode');
    debugPrint('VISITED ${visited.length}: ${visited.join(" | ")}');
    final unique = errors.toSet().toList();
    if (unique.isEmpty) {
      debugPrint('NO ERRORS');
    } else {
      debugPrint('ERRORS (${unique.length}):');
      for (final e in unique) {
        debugPrint('  $e');
      }
    }
    expect(unique, isEmpty);
  });
}
