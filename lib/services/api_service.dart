import 'dart:convert';

import '../core/api.dart';
import '../models/models.dart';

/// Typed facade over the raw Apps Script RPC surface. Endpoint names must
/// match the deployed backend exactly (`api_*` for the founder app,
/// `api_staff_*` for the staff app).
class ApiService {
  ApiService(this._api);

  final ApiClient _api;

  // ---------------------------------------------------------- auth / boot
  Future<Bootstrap> bootstrap() async {
    final b = await _api.call('api_bootstrap');
    return Bootstrap.fromApi(b as Map<String, dynamic>);
  }

  Future<Bootstrap> staffBoot() async {
    final b = await _api.call('api_staff_boot');
    return Bootstrap.fromApi(b as Map<String, dynamic>);
  }

  // ------------------------------------------------------------- students
  Future<List<Student>> searchStudents(String q, {String classCode = 'ALL'}) async {
    final b = await _api.call('api_searchStudent', {
      'q': q,
      'classCode': classCode,
      'includeAll': true,
    });
    return ((b as Map)['results'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(Student.fromApi)
            .toList() ??
        [];
  }

  Future<List<Student>> staffSearchStudents(String q, {String branch = 'ALL'}) async {
    final b = await _api.call('api_staff_searchStudents', {
      'q': q,
      'branch': branch,
      'includeAll': true,
    });
    // Staff API returns `rows` not `results`
    final m = b as Map;
    return (m['rows'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(Student.fromApi)
            .toList() ??
        [];
  }

  Future<StaffHub> staffStudentHub(String studentId, {String branch = 'ALL'}) async {
    final b = await _api.call('api_staff_studentHub', {
      'studentId': studentId,
      'branch': branch,
    });
    return StaffHub.fromApi(b as Map<String, dynamic>);
  }

  Future<dynamic> addStudent(Map<String, dynamic> form) =>
      _api.call('api_addStudent', form);

  Future<dynamic> saveStudentDraft(Map<String, dynamic> form) =>
      _api.call('api_staff_saveStudentDraft', form);

  // ---------------------------------------------------------------- money
  Future<dynamic> addFeePayment(Map<String, dynamic> form) =>
      _api.call('api_addFeePayment', form);

  Future<dynamic> receiptPreflight(Map<String, dynamic> form) =>
      _api.call('api_receiptPreflight', form);

  Future<List<ReceiptRow>> searchReceipts({
    String q = '',
    String studentName = '',
    String receiptNo = '',
    String classCode = 'ALL',
    String status = '',
    String dateFrom = '',
    String dateTo = '',
    int limit = 50,
    int offset = 0,
  }) async {
    final b = await _api.call('api_searchReceipt', {
      'q': q,
      'studentName': studentName,
      'receiptNo': receiptNo,
      'classCode': classCode,
      'status': status,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
      'limit': limit,
      'offset': offset,
    });
    return ((b as Map)['results'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ReceiptRow.fromApi)
            .toList() ??
        [];
  }

  // ------------------------------------------------------------ dashboard
  Future<DashboardMetrics> dashboard(String scope) async {
    final b = await _api.call('api_dashboard', scope == 'ALL' ? '' : scope);
    return DashboardMetrics.fromApi(b as Map<String, dynamic>);
  }

  Future<DueReminders> dueReminders(String branch) async {
    final b = await _api.call('api_dueReminders', branch);
    return DueReminders.tryFrom(b as Map<String, dynamic>) ??
        DueReminders(branch: branch, advanceDays: 0, dueSoon: [], dueToday: [],
            overdue: [], gmcActive: 0, kmcActive: 0);
  }

  // -------------------------------------------------------------- teachers
  Future<List<Teacher>> listTeachers() async {
    final b = await _api.call('api_listTeachers');
    return ((b as Map)['teachers'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(Teacher.fromApi)
            .toList() ??
        [];
  }

  Future<dynamic> addTeacher(Map<String, dynamic> form) =>
      _api.call('api_addTeacher', form);

  // -------------------------------------------------------------- expenses
  Future<dynamic> addExpenseEntry(Map<String, dynamic> form) =>
      _api.call('api_addExpenseEntry', form);

  Future<List<ExpenseEntry>> cashbookReport({
    String from = '',
    String to = '',
    String branch = 'ALL',
  }) async {
    final b = await _api.call('api_cashbookReport', {
      'dateFrom': from,
      'dateTo': to,
      'branch': branch,
    });
    return ((b as Map)['entries'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ExpenseEntry.fromApi)
            .toList() ??
        [];
  }

  // -------------------------------------------------------------- staff os
  Future<List<Inquiry>> staffInquiryQueue({String branch = 'ALL'}) async {
    final b = await _api.call('api_staff_inquiryQueue', {'branch': branch});
    final m = b as Map;
    final raw = m['rows'] ?? m['queue'] ?? m['entries'] ?? m['results'];
    return (raw as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(Inquiry.fromApi)
            .toList() ??
        [];
  }

  Future<dynamic> staffInquiryQuickAdd(Map<String, dynamic> form) =>
      _api.call('api_staff_inquiryQuickAdd', form);

  Future<dynamic> staffAttendanceRoster(Map<String, dynamic> payload) =>
      _api.call('api_staff_attendanceRoster', payload);

  Future<dynamic> staffMarkAttendance(Map<String, dynamic> payload) =>
      _api.call('api_staff_markAttendance', payload);

  Future<dynamic> staffFeeDueList({String branch = 'ALL'}) async {
    final b = await _api.call('api_staff_feeDueList', {'branch': branch});
    return b;
  }

  Future<List<TaskCard>> staffTodaysTasks({String branch = 'ALL'}) async {
    final b = await _api.call('api_staff_todaysTasks', {'branch': branch});
    return ((b as Map)['cards'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(TaskCard.fromApi)
            .toList() ??
        [];
  }

  // ------------------------------------------------------- today's classes
  Future<TodaysClassOptions> staffTodaysClasses({
    String branch = 'ALL',
    String date = '',
  }) async {
    final b = await _api.call('api_staff_todaysClasses', {'branch': branch, 'date': date});
    return TodaysClassOptions.fromApi(b as Map<String, dynamic>);
  }

  Future<dynamic> staffResolveTodaysClass(Map<String, dynamic> payload) =>
      _api.call('api_staff_resolveTodaysClass', payload);

  Future<dynamic> staffScheduleSession(Map<String, dynamic> payload) =>
      _api.call('api_staff_scheduleSession', payload);

  Future<dynamic> staffSessionRoster({String branch = 'ALL', required String scheduledSessionId}) =>
      _api.call('api_staff_sessionRoster', {'branch': branch, 'scheduledSessionId': scheduledSessionId});

  // --------------------------------------------------------------- leads
  Future<dynamic> staffInquiryTransition(Map<String, dynamic> payload) =>
      _api.call('api_staff_inquiryTransition', payload);

  // ------------------------------------------------------------ approvals
  Future<ApprovalsData> founderApprovals({String branch = ''}) async {
    final b = await _api.call('api_founder_approvalsList', {'branch': branch});
    return ApprovalsData.fromApi(b as Map<String, dynamic>);
  }

  /// Full payment-draft queue incl. APPROVED rows (the ones needing finalise).
  Future<List<PaymentDraftRow>> founderListPaymentDrafts({String branch = ''}) async {
    final b = await _api.call('api_founder_listPaymentDrafts', {'branch': branch});
    return ((b as Map)['rows'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(PaymentDraftRow.fromApi)
            .toList() ??
        [];
  }

  Future<dynamic> founderPaymentDraftApprove(String draftId) =>
      _api.call('api_founder_paymentDraftApprove', {'draftId': draftId});

  Future<dynamic> founderPaymentDraftReject(String draftId, String comment) =>
      _api.call('api_founder_paymentDraftReject', {'draftId': draftId, 'comment': comment});

  /// REAL MONEY — finalises an APPROVED payment draft on the founder side.
  /// Reserves a receipt number, writes STUDENT_RECEIPTS + MONEY_LEDGER,
  /// advances next_due_date, renders PDF. Founder only. Idempotent.
  Future<dynamic> founderFinalisePaymentDraft(
    String draftId, {
    bool override = false,
    String overrideReason = '',
  }) =>
      _api.call('api_founder_finalisePaymentDraft', {
        'draftId': draftId,
        if (override) 'override': true,
        if (override && overrideReason.isNotEmpty) 'overrideReason': overrideReason,
      });

  /// REAL MONEY (gated) — staff executes a founder-APPROVED draft's receipt.
  /// Server refuses unless STAFF_FINALISE_ENABLED + ops account + verified
  /// authority + APPROVED status. Idempotent; never double-writes.
  Future<dynamic> staffFinalisePaymentDraft(String draftId) =>
      _api.call('api_staff_finalisePaymentDraft', {'draftId': draftId});

  /// Founder-only lifecycle status change. Reason is MANDATORY and audited.
  /// The student row is never deleted — archive is a status change.
  Future<dynamic> founderSetStudentStatus(String studentId, String status, String reason) =>
      _api.call('api_founder_setStudentStatus', {
        'studentId': studentId,
        'status': status,
        'reason': reason,
      });

  /// Founder-only teacher payout preview (server-computed payable). Never compute on client.
  Future<List<PayoutRow>> founderPayoutPreview(String month, {String? entityId}) async {
    final b = await _api.call('api_teacherPayoutPreview', {
      if (month.isNotEmpty) 'month': month,
      if (entityId != null && entityId.isNotEmpty) 'entityId': entityId,
    });
    return ((b as Map)['results'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(PayoutRow.fromApi)
            .toList() ??
        [];
  }

  /// Staff — persisted drafts awaiting (or resolved by) founder approval.
  Future<List<ApprovalRequestRow>> staffMyRequests({String branch = ''}) async {
    final b = await _api.call('api_staff_listMyApprovals', {'branch': branch});
    return ((b as Map)['rows'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ApprovalRequestRow.fromApi)
            .toList() ??
        [];
  }

  /// Founder-only teacher status change (ACTIVE / INACTIVE / HOLD).
  Future<dynamic> founderUpdateTeacherStatus(String teacherId, String newStatus, String reason) =>
      _api.call('api_updateTeacherStatus', {
        'teacherId': teacherId,
        'newStatus': newStatus,
        'reason': reason,
      });

  Future<dynamic> founderMergeStudentDraft(String draftId) =>
      _api.call('api_founder_mergeStudentDraft', {'draftId': draftId});

  // ----------------------------------------------------------- messaging
  Future<CommMessage> staffCommGenerate(Map<String, dynamic> params) async {
    final b = await _api.call('api_staff_commGenerate', params);
    return CommMessage.fromApi(b as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------- misc
  Future<dynamic> raw(String api, [Object? arg]) => _api.call(api, arg);
}

/// Debug helper: pretty-print a server payload for a failure sheet.
String prettyPayload(dynamic v) {
  try {
    return const JsonEncoder.withIndent('  ').convert(v);
  } catch (_) {
    return '$v';
  }
}