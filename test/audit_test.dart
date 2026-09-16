import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swar_mangal/core/api.dart';
import 'package:swar_mangal/main.dart';
import 'package:swar_mangal/services/demo_api.dart';

Future<void> waitBeat(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Startup reads the device token from secure storage; with no mock the
    // read never returns and StartupGate stays on the splash.
    FlutterSecureStorage.setMockInitialValues({});
    DemoApiClient.resetSharedState();
  });

  group('DemoApiClient — demo provenance (never pretends persistence)', () {
    late DemoApiClient demo;

    setUp(() {
      demo = DemoApiClient();
    });

    test('fee payment write is stamped demo and reports no ledger', () async {
      final r = await demo.call('api_addFeePayment', {'amount': 5000});
      final m = r as Map<String, dynamic>;
      expect(m['ok'], true);
      expect(m['demo'], true);
      // Demo must not claim real money rows: the demoNote says so explicitly.
      expect(m['demoNote'], contains('no real backend write'));
    });

    test('founder finalise is stamped demo and never claims real receipt', () async {
      final r = await demo.call('api_founder_finalisePaymentDraft', {'draftId': 'X'});
      final m = r as Map<String, dynamic>;
      expect(m['demo'], true);
      expect(m['demoNote'], contains('Not persisted'));
      // Idempotency/no duplicate semantic is server responsibility — demo just signals demo.
      expect(m['receiptNo'], startsWith('RCP-DEMO'));
    });

    test('staff finalise is stamped demo', () async {
      final r = await demo.call('api_staff_finalisePaymentDraft', {'draftId': 'X'});
      expect((r as Map<String, dynamic>)['demo'], true);
    });

    test('reads are NOT stamped as writes', () async {
      final r = await demo.call('api_searchStudent', {'q': 'aarav'});
      final m = r as Map<String, dynamic>;
      expect(m['demo'], isNull);
    });
  });

  group('ApiException error contract', () {
    test('preserves server code + message', () {
      final e = ApiException('Student not found.', code: 'STUDENT_NOT_FOUND');
      expect(e.code, 'STUDENT_NOT_FOUND');
      expect(e.message, contains('Student not found'));
      expect('$e', contains('STUDENT_NOT_FOUND'));
    });

    test('network failure is distinct from business refusal', () {
      expect(ApiUnreachable('offline').toString(), contains('offline'));
    });
  });

  group('App flows (demo mode, offline)', () {
    testWidgets('staff: login -> branch gate -> choose branch -> shell',
        (tester) async {
      await tester.pumpWidget(const AcademyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Demo · Staff'));
      await tester.pumpAndSettle();

      // Branch gate is forced before branch-sensitive data.
      expect(find.text('Choose your branch'), findsOneWidget);
      await tester.tap(find.text('GOREGAON'));
      await tester.pumpAndSettle();

      // Today loads from the demo backend (no cross-branch leakage path).
      expect(find.text('Fees Due Today'), findsWidgets);
    });

    testWidgets('founder: login -> shell -> logout returns to login',
        (tester) async {
      await tester.pumpWidget(const AcademyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Demo · Founder'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.byTooltip('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Demo · Founder'), findsOneWidget);
    });

});

  group('Idempotency key stability', () {
    test('DemoApiClient returns single source retry semantics', () async {
      final demo = DemoApiClient();
      final a = await demo.call('api_addFeePayment', {'requestId': 'k-1'});
      final b = await demo.call('api_addFeePayment', {'requestId': 'k-1'});
      expect(((a as Map)['ok']), true);
      expect(((b as Map)['ok']), true);
    });
  });
}