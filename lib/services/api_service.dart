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

  Future<List<Student>> staffStudentHub(String studentId, {String branch = 'ALL'}) async {
    final b = await _api.call('api_staff_getStudentProfile', {
      'studentId': studentId,
      'branch': branch,
    });
    // Staff API returns `profile` not `student`
    final m = b as Map;
    final p = m['profile'];
    if (p is Map<String, dynamic>) return [Student.fromApi(p)];
    return [];
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

  Future<dynamic> founderPaymentDraftApprove(String draftId) =>
      _api.call('api_founder_paymentDraftApprove', {'draftId': draftId});

  Future<dynamic> founderPaymentDraftReject(String draftId, String comment) =>
      _api.call('api_founder_paymentDraftReject', {'draftId': draftId, 'comment': comment});

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