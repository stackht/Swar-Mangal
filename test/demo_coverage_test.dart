import 'package:flutter_test/flutter_test.dart';

import 'package:swar_mangal/models/models.dart';
import 'package:swar_mangal/services/demo_api.dart';
import 'package:swar_mangal/core/api.dart';

/// Contract-coverage suite over the full DemoApiClient surface.
/// Every read the screens use must return `ok:true` plus the key the screen
/// relies on (catch 'rows vs results' style drift); every model must parse
/// the fixture it receives.
Map<String, dynamic> asMap(dynamic v) => v as Map<String, dynamic>;

void main() {
  group('DemoApiClient — full read surface resolves true (ok + shape)', () {
    late DemoApiClient d;

    setUp(() => d = DemoApiClient());

    Future<Map<String, dynamic>> call(String api, [Map<String, dynamic>? arg]) async =>
        asMap(await d.call(api, arg ?? const {}));

    test('api_bootstrap — role, paymentModes, classCodes', () async {
      final b = await call('api_bootstrap');
      expect(b['ok'], true);
      expect(b['role'], 'FOUNDER_ADMIN');
      expect(b['paymentModes'], isNotEmpty);
      expect(b['classCodes'], contains('GMC'));
    });

    test('api_staff_boot — branches + isOpsAccount', () async {
      final b = await call('api_staff_boot');
      expect(b['ok'], true);
      expect(b['isOpsAccount'], true);
      expect(b['branches'], containsAll(['GOREGAON', 'KANDIVALI']));
    });

    test('api_searchStudent — results', () async {
      final b = await call('api_searchStudent', {'q': '', 'includeAll': true});
      expect(b['ok'], true);
      expect(b['results'], isA<List>());
      expect(b['results'], isNotEmpty);
    });

    test('api_searchReceipt — results', () async {
      final b = await call('api_searchReceipt', const {});
      expect(b['results'], isNotEmpty);
    });

    test('api_listTeachers — teachers', () async {
      final b = await call('api_listTeachers');
      expect(b['teachers'], isNotEmpty);
    });

    test('api_dashboard — todayCollection + metrics', () async {
      final b = await call('api_dashboard', {'scope': ''});
      expect(b['ok'], true);
      expect(b['todayCollection'], isA<num>());
      expect(b['metrics'], isA<Map>());
      expect(b['recent'], isA<List>());
    });

    test('api_dueReminders — three buckets', () async {
      final b = await call('api_dueReminders', {'branch': 'ALL'});
      expect(b['dueSoon'], isA<List>());
      expect(b['dueToday'], isA<List>());
      expect(b['overdue'], isA<List>());
    });

    test('api_cashbookReport — entries', () async {
      final b = await call('api_cashbookReport', const {});
      expect(b['entries'], isNotEmpty);
    });

    test('api_staff_todaysTasks — cards', () async {
      final b = await call('api_staff_todaysTasks', {'branch': 'GOREGAON'});
      expect(b['cards'], isNotEmpty);
    });

    test('api_staff_todaysClasses — rows + outcomes', () async {
      final b = await call('api_staff_todaysClasses', {'branch': 'GOREGAON', 'date': '2026-09-11'});
      expect(b['rows'], isNotEmpty);
      expect(b['outcomes'], contains('HELD'));
    });

    test('api_staff_attendanceRoster — students + instruments', () async {
      final b = await call('api_staff_attendanceRoster', {'branch': 'GOREGAON', 'date': '2026-09-11'});
      expect(b['students'], isNotEmpty);
      expect(b['instruments'], isNotEmpty);
    });

    test('api_staff_inquiryQueue — rows', () async {
      final b = await call('api_staff_inquiryQueue', {'branch': 'GOREGAON'});
      expect(b['rows'], isNotEmpty);
    });

    test('api_founder_approvalsList — groups + items', () async {
      final b = await call('api_founder_approvalsList', const {});
      expect(b['groups'], isNotEmpty);
      expect(b['items'], isNotEmpty);
    });

    test('api_founder_listPaymentDrafts — rows incl APPROVED authority', () async {
      final b = await call('api_founder_listPaymentDrafts', const {});
      final rows = (b['rows'] as List).cast<Map<String, dynamic>>();
      expect(rows, isNotEmpty);
      expect(
        rows.where((r) => r['status'] == 'APPROVED').first,
        containsPair('approvalAuthority', 'FOUNDER'),
      );
    });

    test('api_teacherPayoutPreview — results', () async {
      final b = await call('api_teacherPayoutPreview', {'month': '2026-09'});
      expect(b['results'], isNotEmpty);
    });

    test('api_staff_listMyApprovals — rows', () async {
      final b = await call('api_staff_listMyApprovals', {'branch': 'GOREGAON'});
      expect(b['rows'], isNotEmpty);
    });

    test('api_staff_studentHub — profile + pending.canFinalise', () async {
      final b = await call('api_staff_studentHub', {'studentId': 'STU-55DCD622', 'branch': 'GOREGAON'});
      expect(b['profile'], isA<Map>());
      final pending = asMap(b['pending']);
      final rows = (pending['rows'] as List).cast<Map<String, dynamic>>();
      expect(rows.firstWhere((r) => r['canFinalise'] == true), isNotEmpty);
    });

    test('api_staff_commGenerate — subject + body + COPY_ONLY', () async {
      final b = await call('api_staff_commGenerate', {'type': 'FEE_REMINDER'});
      expect(b['subject'], isNotEmpty);
      expect(b['body'], isNotEmpty);
      expect(b['mode'], contains('COPY_ONLY'));
      expect(b['providerSend'], contains('DISABLED'));
    });

    test('api_staff_sessionRoster — rows', () async {
      final b = await call('api_staff_sessionRoster', {'branch': 'GOREGAON', 'scheduledSessionId': 'SCSS-DEMO-1'});
      expect(b['rows'], isNotEmpty);
    });
  });

  group('DemoApiClient — writes always carry demo provenance', () {
    const writes = <String, String>{
      'api_addStudent': '{}',
      'api_staff_saveStudentDraft': '{"branch":"GOREGAON"}',
      'api_addFeePayment': '{"amount":5000}',
      'api_staff_prepareReceiptDraft': '{"studentId":"S1","amountPaise":500000}',
      'api_addTeacher': '{}',
      'api_addExpenseEntry': '{"amount":100}',
      'api_staff_submitExpenseDraft': '{"amountPaise":10000,"branch":"GOREGAON"}',
      'api_staff_inquiryQuickAdd': '{"name":"N","phone":"9"}',
      'api_staff_inquiryTransition': '{"inquiryId":"Q","action":"LOG_CONTACT"}',
      'api_staff_markAttendance': '{"studentId":"S","state":"PRESENT"}',
      'api_staff_scheduleSession': '{}',
      'api_staff_resolveTodaysClass': '{"eventId":"E","outcome":"HELD"}',
      'api_founder_setStudentStatus': '{"studentId":"S","status":"LEFT","reason":"r"}',
      'api_updateTeacherStatus': '{"teacherId":"T","newStatus":"INACTIVE","reason":"r"}',
      'api_founder_paymentDraftApprove': '{"draftId":"D"}',
      'api_founder_paymentDraftReject': '{"draftId":"D","comment":"c"}',
      'api_founder_finalisePaymentDraft': '{"draftId":"D"}',
      'api_staff_finalisePaymentDraft': '{"draftId":"D"}',
      'api_founder_mergeStudentDraft': '{"draftId":"D"}',
    };

    for (final entry in writes.entries) {
      test('${entry.key} is stamped demo, never claims persistence', () async {
        final m = asMap(await DemoApiClient().call(entry.key, const {}));
        expect(m['demo'], true, reason: '${entry.key} must be marked demo');
        expect((m['demoNote'] ?? '').toString(), contains('Not persisted'));
      });
    }
  });

  group('Model parsing — fixture contract shapes (no drift)', () {
    late DemoApiClient d;
    setUp(() => d = DemoApiClient());
    Future<Map<String, dynamic>> call(String api, [Map<String, dynamic>? arg]) async =>
        asMap(await d.call(api, arg ?? const {}));

    test('Student.fromApi parses search results', () async {
      final b = await call('api_searchStudent', {'q': '', 'includeAll': true});
      final s = Student.fromApi((b['results'] as List).cast<Map<String, dynamic>>().first);
      expect(s.studentId, isNotEmpty);
      expect(s.studentName, isNotEmpty);
    });

    test('ReceiptRow.fromApi parses search receipts', () async {
      final b = await call('api_searchReceipt', const {});
      final r = ReceiptRow.fromApi((b['results'] as List).cast<Map<String, dynamic>>().first);
      expect(r.receiptNo, isNotEmpty);
    });

    test('Teacher.fromApi parses teacher list', () async {
      final b = await call('api_listTeachers');
      final t = Teacher.fromApi((b['teachers'] as List).cast<Map<String, dynamic>>().first);
      expect(t.teacherId, isNotEmpty);
      expect(t.teacherName, isNotEmpty);
    });

    test('ExpenseEntry.fromApi parses cashbook', () async {
      final b = await call('api_cashbookReport', const {});
      final e = ExpenseEntry.fromApi((b['entries'] as List).cast<Map<String, dynamic>>().first);
      expect(e.entryId, isNotEmpty);
      expect(e.amount, greaterThan(0));
    });

    test('TodaysClassOptions.fromApi parses classes', () async {
      final b = await call('api_staff_todaysClasses', {'branch': 'GOREGAON', 'date': '2026-09-11'});
      final o = TodaysClassOptions.fromApi(b);
      expect(o.rows, isNotEmpty);
      expect(o.outcomes, isNotEmpty);
      for (final c in o.rows.take(1)) {
        expect(c.eventId, isNotEmpty);
      }
    });

    test('TaskCard.fromApi parses today cards', () async {
      final b = await call('api_staff_todaysTasks', {'branch': 'GOREGAON'});
      final c = TaskCard.fromApi((b['cards'] as List).cast<Map<String, dynamic>>().first);
      expect(c.key, isNotEmpty);
      expect(c.label, isNotEmpty);
    });

    test('ApprovalsData.fromApi parses groups', () async {
      final b = await call('api_founder_approvalsList', const {});
      final a = ApprovalsData.fromApi(b);
      expect(a.groups, isNotEmpty);
      expect(a.groups.first.items, isNotEmpty);
      expect(a.groups.first.items.first.itemId, isNotEmpty);
    });

    test('PaymentDraftRow authority label is honest about ROUTINE_LANE', () async {
      final b = await call('api_founder_listPaymentDrafts', const {});
      final rows = (b['rows'] as List).cast<Map<String, dynamic>>();
      final founder = rows.firstWhere((r) => r['status'] == 'APPROVED');
      final founderRow = PaymentDraftRow.fromApi(founder);
      expect(founderRow.authorityLabel, contains('sharvil@demo'));
      // ROUTINE_LANE must never render a human approver.
      final routine = PaymentDraftRow.fromApi({
        'draftId': 'D', 'status': 'APPROVED',
        'approvalAuthority': 'ROUTINE_LANE', 'approvedBy': '',
      });
      expect(routine.authorityLabel, isNot(contains('Approved by')));
      expect(routine.authorityLabel, contains('Routine'));
    });

    test('PayoutRow.fromApi parses preview results', () async {
      final b = await call('api_teacherPayoutPreview', {'month': '2026-09'});
      final rows = (b['results'] as List).cast<Map<String, dynamic>>();
      final r = PayoutRow.fromApi(rows.first);
      expect(r.teacherName, isNotEmpty);
      expect(r.payable, greaterThanOrEqualTo(0));
    });

    test('ApprovalRequestRow.fromApi parses staff requests', () async {
      final b = await call('api_staff_listMyApprovals', {'branch': 'GOREGAON'});
      final r = ApprovalRequestRow.fromApi((b['rows'] as List).cast<Map<String, dynamic>>().first);
      expect(r.id, isNotEmpty);
      expect(r.type, isNotEmpty);
    });

    test('StaffHub.fromApi parses hub w/ pending finalisable', () async {
      final b = await call('api_staff_studentHub', {'studentId': 'STU-55DCD622', 'branch': 'GOREGAON'});
      final hub = StaffHub.fromApi(b);
      expect(hub.profile.studentId, isNotEmpty);
      expect(hub.pending.where((p) => p.canFinalise), isNotEmpty);
    });

    test('CommMessage.fromApi parses generated message', () async {
      final b = await call('api_staff_commGenerate', {'type': 'FEE_REMINDER'});
      final m = CommMessage.fromApi(b);
      expect(m.subject, isNotEmpty);
      expect(m.body, isNotEmpty);
      expect(m.copyOnly, true);
    });

    test('DashboardMetrics.fromApi parses dashboard', () async {
      final b = await call('api_dashboard', {'scope': ''});
      final m = DashboardMetrics.fromApi(b);
      expect(m.todayCollection, greaterThanOrEqualTo(0));
      expect(m.recent, isA<List>());
    });

    test('Bootstrap.fromApi parses founder boot', () async {
      final b = await call('api_bootstrap');
      final boot = Bootstrap.fromApi(b);
      expect(boot.operator.isFounder, true);
      expect(boot.operator.isStaff, false);
      expect(boot.classCodes, isNotEmpty);
    });

    test('Inquiry.fromApi parses leads', () async {
      final b = await call('api_staff_inquiryQueue', {'branch': 'GOREGAON'});
      final q = Inquiry.fromApi((b['rows'] as List).cast<Map<String, dynamic>>().first);
      expect(q.inquiryId, isNotEmpty);
      expect(q.name, isNotEmpty);
    });
  });

  group('Error contract', () {
    test('ApiException carries server code + message', () {
      final e = ApiException('Student not found.', code: 'STUDENT_NOT_FOUND');
      expect(e.code, 'STUDENT_NOT_FOUND');
      expect(e.toString(), contains('STUDENT_NOT_FOUND'));
    });

    test('ApiUnreachable is a distinct transport failure', () {
      expect(ApiUnreachable('timeout').toString(), contains('timeout'));
    });
  });
}