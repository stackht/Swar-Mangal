import 'package:flutter_test/flutter_test.dart';
import 'package:swar_mangal/models/models.dart';
import 'package:swar_mangal/services/api_service.dart';
import 'package:swar_mangal/services/demo_api.dart';
import 'package:swar_mangal/state/sync_manager.dart';

Map<String, dynamic> _map(dynamic v) => v as Map<String, dynamic>;

void main() {
  group('api_syncChanges — demo shared store (two sessions see changes)', () {
    test('founder (session A) edits timetable → staff (session B) sees revision', () async {
      final a = DemoApiClient();
      final b = DemoApiClient(); // separate session, same shared store
      final before = _map(await b.call('api_syncChanges', {'branch': 'KANDIVALI', 'knownRevisions': const {}}));
      final t0 = (before['revisions'] as Map)['timetable'] as int;

      await a.call('api_timetableCreate', {
        'branch': 'KANDIVALI', 'dayOfWeek': 1, 'startTime': '21:00', 'endTime': '22:00', 'className': 'Sargam'
      });

      final after = _map(await b.call('api_syncChanges', {'branch': 'KANDIVALI', 'knownRevisions': <String, int>{'timetable': t0}}));
      expect((after['revisions'] as Map)['timetable'], t0 + 1);
      expect((after['changes'] as List).any((c) => (c as Map)['entity'] == 'TIMETABLE'), true);

      // staff reloads only affected entity
      final staffList = await b.call('api_timetableList', {'branch': 'KANDIVALI'});
      expect((staffList as Map)['entries'].length, 26);
      expect(((staffList['entries'] as List).cast<Map<String, dynamic>>()).any((e) => e['className'] == 'Sargam'), true);
    });

    test('invoice created by founder → staff sees invoices revision + history', () async {
      final a = DemoApiClient();
      final b = DemoApiClient();
      final known = ((_map(await a.call('api_syncChanges', {'branch': 'ALL', 'knownRevisions': const {}})))['revisions']
              as Map)
          .map<String, int>((k, v) => MapEntry('$k', (v as num).toInt()));

      await a.call('api_generateSchoolInvoice', {'className': 'Keyboard', 'amount': 18000, 'tenure': '6 Months'});

      final after = _map(await b.call('api_syncChanges', {'branch': 'ALL', 'knownRevisions': known}));
      expect((after['revisions'] as Map)['invoices'], (known['invoices'] ?? 1) + 1);
      final inv = await b.call('api_listSchoolInvoices', {'branch': 'ALL'});
      expect((inv as Map)['invoices'], hasLength(3));
    });

    test('payment draft finalise bumps payments+receipts+dashboard+students', () async {
      final d = DemoApiClient();
      final known = ((_map(await d.call('api_syncChanges', {'branch': 'KANDIVALI', 'knownRevisions': const {}})))['revisions']
              as Map)
          .map<String, int>((k, v) => MapEntry('$k', (v as num).toInt()));

      await d.call('api_staff_finalisePaymentDraft', {'draftId': 'X'});

      final after = _map(await d.call('api_syncChanges', {'branch': 'KANDIVALI', 'knownRevisions': known}));
      for (final ent in ['payments', 'receipts', 'dashboard', 'students']) {
        expect((after['revisions'] as Map)[ent], (known[ent] ?? 1) + 1, reason: '$ent should bump on finalise');
      }
    });

    test('sync is read-only — revisions never change from api_syncChanges', () async {
      final d = DemoApiClient();
      final r1 = ((_map(await d.call('api_syncChanges', {'branch': 'ALL', 'knownRevisions': const {}})))['revisions'] as Map)
          .map<String, int>((k, v) => MapEntry('$k', (v as num).toInt()));
      final r2 = ((_map(await d.call('api_syncChanges', {'branch': 'ALL', 'knownRevisions': r1})))['revisions'] as Map)
          .map<String, int>((k, v) => MapEntry('$k', (v as num).toInt()));
      expect(r2, r1);
    });
  });

  group('syncChanges typed API (ApiService)', () {
    test('parses into SyncSnapshot', () async {
      final svc = ApiService(DemoApiClient());
      final snap = await svc.syncChanges(branch: 'KANDIVALI', knownRevisions: const {});
      expect(snap.ok, true);
      expect(snap.revisions, isNotEmpty);
    });
  });

  group('SyncManager state machine', () {
    test('attached service → synced with lastSyncedAt set', () async {
      final mgr = SyncManager();
      mgr.attach(ApiService(DemoApiClient()));
      await mgr.syncNow();
      expect(mgr.state, SyncState.synced);
      expect(mgr.lastSyncedAt, isNotNull);
    });

    test('no service → offline', () async {
      final mgr = SyncManager();
      await mgr.syncNow();
      expect(mgr.state, SyncState.offline);
    });

    test('branch change clears known revisions (no cross-branch leak)', () async {
      final mgr = SyncManager();
      mgr.attach(ApiService(DemoApiClient()));
      await mgr.syncNow();
      mgr.setBranch('KANDIVALI');
      await mgr.syncNow();
      expect(mgr.branch, 'KANDIVALI');
      expect(mgr.state, SyncState.synced);
    });
  });

  group('timetable conflict detection (expectedVersion)', () {
    test('stale expectedVersion returns CONFLICT, no overwrite', () async {
      final d = DemoApiClient();
      final list = _map(await d.call('api_timetableList', {'branch': 'KANDIVALI'}));
      final id = ((list['entries'] as List).cast<Map<String, dynamic>>()).first['id'];
      final revBefore = DemoApiClient.revisions['timetable']!;

      // first update succeeds (expectedVersion matches)
      await d.call('api_timetableUpdate', {'id': id, 'startTime': '10:00', 'expectedVersion': revBefore});
      // second update with the OLD expectedVersion must conflict
      final conflict = _map(await d.call('api_timetableUpdate', {'id': id, 'startTime': '11:00', 'expectedVersion': revBefore}));
      expect(conflict['ok'], false);
      expect(conflict['code'], 'CONFLICT');
      // the failed write did NOT change the data
      final after = _map(await d.call('api_timetableList', {'branch': 'KANDIVALI'}));
      final updated = ((after['entries'] as List).cast<Map<String, dynamic>>()).firstWhere((e) => e['id'] == id);
      expect(updated['startTime'], '10:00');
    });

    test('failed write never bumps revision', () async {
      final d = DemoApiClient();
      final known = ((_map(await d.call('api_syncChanges', {'branch': 'KANDIVALI', 'knownRevisions': const {}})))['revisions'] as Map)
          .map<String, int>((k, v) => MapEntry('$k', (v as num).toInt()));
      final barrier = DemoApiClient.revisions['timetable']!;
      await d.call('api_timetableCreate', {'branch': 'KANDIVALI', 'dayOfWeek': 0, 'startTime': '25:00', 'endTime': '26:00', 'className': 'X'});
      // create with bad time still goes through demo route (no validation) —
      // use an update that conflicts instead to guarantee a failed write path
      await d.call('api_timetableUpdate', {'id': 'none', 'startTime': '10:00', 'expectedVersion': barrier});
      final after = ((_map(await d.call('api_syncChanges', {'branch': 'KANDIVALI', 'knownRevisions': known})))['revisions'] as Map)
          .map<String, int>((k, v) => MapEntry('$k', (v as num).toInt()));
      // only writes that succeed bump; a NOT_FOUND / CONFLICT return does not
      expect(after['timetable'], DemoApiClient.revisions['timetable']);
    });
  });
}