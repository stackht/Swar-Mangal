import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:swar_mangal/main.dart';

/// Stable on-device smoke test: proves the real APK builds, installs,
/// launches, login screen renders, and demo login reaches the shell.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo founder login + shell renders', (tester) async {
    await tester.pumpWidget(const AcademyApp());
    await tester.pumpAndSettle();

    // Login screen shows
    expect(find.text('SwarMangal'), findsWidgets);

    // Tap demo founder
    await tester.tap(find.text('Demo · Founder'));
    await tester.pumpAndSettle();

    // Founder shell renders — drawer header shows app name,
    // and the default Home view label is visible.
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('demo staff login + branch gate', (tester) async {
    await tester.pumpWidget(const AcademyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Demo · Staff'));
    await tester.pumpAndSettle();

    // Branch gate appears
    expect(find.text('Choose your branch'), findsOneWidget);
    await tester.tap(find.text('GOREGAON'));
    await tester.pumpAndSettle();

    // Staff shell renders with Today's task cards
    expect(find.text('Fees Due Today'), findsWidgets);
  });
}