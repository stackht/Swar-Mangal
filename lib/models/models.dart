// Plain data models mirroring the Apps Script `api_*` response shapes.
// All parsing is defensive: unknown/missing fields fall back to '' or 0.

String _s(dynamic v) => v == null ? '' : v.toString();
num _n(dynamic v) {
  if (v is num) return v;
  final s = v == null ? '' : v.toString().replaceAll(RegExp(r'[^\d.\-]'), '');
  final d = double.tryParse(s);
  return d ?? 0;
}

class Operator {
  Operator({required this.email, required this.role, required this.name, this.branches = const []});
  factory Operator.fromApi(Map<String, dynamic> b) {
    // Staff boot: {ok, email, isOpsAccount, branches}
    final bool isOps = b['isOpsAccount'] == true;
    final role = isOps ? 'OPS_USER' : _s(b['role']).ifEmpty('FOUNDER_ADMIN');
    final branches = (b['branches'] as List?)?.map((e) => _s(e)).toList() ?? const <String>[];
    return Operator(
      email: _s(b['email']),
      role: role,
      name: _s(b['name']).ifEmpty(_s(b['email']).split('@').first),
      branches: branches,
    );
  }
  final String email;
  final String role;
  final String name;
  final List<String> branches;
  bool get isFounder => role == 'FOUNDER_ADMIN';
  bool get isStaff => role == 'OPS_USER';
}

extension _StringExt on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class Bootstrap {
  Bootstrap({
    required this.operator,
    required this.accounts,
    required this.paymentModes,
    required this.planTypes,
    required this.classCodes,
    this.branches,
    this.dueReminders,
  });
  factory Bootstrap.fromApi(Map<String, dynamic> b) {
    return Bootstrap(
      operator: Operator.fromApi(b),
      accounts: List<String>.from((b['accounts'] as List?) ?? const []),
      paymentModes:
          List<String>.from((b['paymentModes'] as List?) ?? const []),
      planTypes: List<String>.from((b['planTypes'] as List?) ?? const []),
      classCodes: List<String>.from((b['classCodes'] as List?) ?? const []),
      branches: (b['branches'] as List?)?.map((e) => _s(e)).toList(),
      dueReminders: DueReminders.tryFrom(b['dueReminders']),
    );
  }
  final Operator operator;
  final List<String> accounts;
  final List<String> paymentModes;
  final List<String> planTypes;
  final List<String> classCodes;
  final List<String>? branches;
  final DueReminders? dueReminders;
}

class Student {
  Student({
    required this.studentId,
    required this.studentName,
    required this.phone,
    required this.email,
    required this.instrument,
    required this.teacher,
    required this.classCode,
    required this.className,
    required this.location,
    required this.batch,
    required this.feeCycleType,
    this.feeDueDay = '',
    required this.nextDueDate,
    required this.feeStatus,
    required this.lastReceiptNo,
    this.lastReceiptAmount = '',
    required this.status,
  });
  factory Student.fromApi(Map<String, dynamic> b) => Student(
        studentId: _s(b['studentId'] ?? b['id']),
        studentName: _s(b['studentName'] ?? b['name']),
        phone: _s(b['phone']),
        email: _s(b['email']),
        instrument: _s(b['instrument'] ?? b['course']),
        teacher: _s(b['teacher']),
        classCode: _s(b['classCode']).toUpperCase(),
        className: _s(b['className']),
        location: _s(b['location'] ?? b['branch']),
        batch: _s(b['batch']),
        feeCycleType: _s(b['feeCycleType']),
        feeDueDay: _s(b['feeDueDay']),
        nextDueDate: _s(b['nextDueDate']),
        feeStatus: _s(b['feeStatus']),
        lastReceiptNo: _s(b['lastReceiptNo']),
        lastReceiptAmount: _s(b['lastReceiptAmount']),
        status: _s(b['status']),
      );

  final String studentId;
  final String studentName;
  final String phone;
  final String email;
  final String instrument;
  final String teacher;
  final String classCode;
  final String className;
  final String location;
  final String batch;
  final String feeCycleType;
  final String feeDueDay;
  final String nextDueDate;
  final String feeStatus;
  final String lastReceiptNo;
  final String lastReceiptAmount;
  final String status;

  bool get operational => status.isEmpty || status.toUpperCase() == 'ACTIVE';
}

class DueReminderItem {
  DueReminderItem({
    required this.studentName,
    required this.phone,
    required this.classCode,
    required this.instrument,
    required this.nextDueDate,
    required this.feeStatus,
    required this.lastReceiptNo,
  });
  factory DueReminderItem.fromApi(Map<String, dynamic> b) => DueReminderItem(
        studentName: _s(b['studentName']),
        phone: _s(b['phone']),
        classCode: _s(b['classCode']),
        instrument: _s(b['instrument']),
        nextDueDate: _s(b['nextDueDate']),
        feeStatus: _s(b['feeStatus']),
        lastReceiptNo: _s(b['lastReceiptNo']),
      );
  final String studentName;
  final String phone;
  final String classCode;
  final String instrument;
  final String nextDueDate;
  final String feeStatus;
  final String lastReceiptNo;
}

class DueReminders {
  DueReminders({
    required this.branch,
    required this.advanceDays,
    required this.dueSoon,
    required this.dueToday,
    required this.overdue,
    required this.gmcActive,
    required this.kmcActive,
  });
  static DueReminders? tryFrom(dynamic b) {
    if (b is! Map<String, dynamic> || b['ok'] != true) return null;
    List<DueReminderItem> items(String k) =>
        ((b[k] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(DueReminderItem.fromApi)
            .toList();
    return DueReminders(
      branch: _s(b['branch']),
      advanceDays: (b['advanceDays'] as num?)?.toInt() ?? 0,
      dueSoon: items('dueSoon'),
      dueToday: items('dueToday'),
      overdue: items('overdue'),
      gmcActive: (b['gmcActive'] as num?)?.toInt() ?? 0,
      kmcActive: (b['kmcActive'] as num?)?.toInt() ?? 0,
    );
  }
  final String branch;
  final int advanceDays;
  final List<DueReminderItem> dueSoon;
  final List<DueReminderItem> dueToday;
  final List<DueReminderItem> overdue;
  final int gmcActive;
  final int kmcActive;

  int get count => dueSoon.length + dueToday.length + overdue.length;
}

class DashboardMetrics {
  DashboardMetrics({
    required this.todayCollection,
    required this.monthCollection,
    required this.todayCount,
    required this.monthCount,
    required this.cashToday,
    required this.onlineToday,
    required this.recent,
    required this.scope,
    required this.consolidated,
    required this.dueTodayCount,
    required this.overdueCount,
    required this.termsPendingCount,
  });
  factory DashboardMetrics.fromApi(Map<String, dynamic> b) {
    final m = (b['metrics'] is Map<String, dynamic>)
        ? b['metrics'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return DashboardMetrics(
      todayCollection: _n(b['todayCollection']),
      monthCollection: _n(b['monthCollection']),
      todayCount: (b['todayCount'] as num?)?.toInt() ?? 0,
      monthCount: (b['monthCount'] as num?)?.toInt() ?? 0,
      cashToday: _n(b['cashToday']),
      onlineToday: _n(b['onlineToday']),
      recent: ((b['recent'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ReceiptRow.fromApi)
          .toList(),
      scope: _s(b['scope']),
      consolidated: b['consolidated'] == true,
      dueTodayCount: (m['dueTodayCount'] as num?)?.toInt() ?? 0,
      overdueCount: (m['overdueCount'] as num?)?.toInt() ?? 0,
      termsPendingCount: (m['termsPendingCount'] as num?)?.toInt() ?? 0,
    );
  }
  final num todayCollection;
  final num monthCollection;
  final int todayCount;
  final int monthCount;
  final num cashToday;
  final num onlineToday;
  final List<ReceiptRow> recent;
  final String scope;
  final bool consolidated;
  final int dueTodayCount;
  final int overdueCount;
  final int termsPendingCount;
}

class ReceiptRow {
  ReceiptRow({
    required this.receiptNo,
    required this.date,
    required this.student,
    required this.amount,
    required this.mode,
    required this.paymentMode,
    required this.status,
    required this.entityId,
    required this.pdfUrl,
    required this.excluded,
    this.feePeriodFrom = '',
    this.feePeriodTo = '',
    this.txnId = '',
  });
  factory ReceiptRow.fromApi(Map<String, dynamic> b) => ReceiptRow(
        receiptNo: _s(b['receiptNo']),
        date: _s(b['date']),
        student: _s(b['student'] ?? b['studentName']),
        amount: _n(b['amount']),
        mode: _s(b['mode']),
        paymentMode: _s(b['paymentMode']),
        status: _s(b['status']),
        entityId: _s(b['entityId']),
        pdfUrl: _s(b['pdfUrl']),
        excluded: b['excluded'] == true,
        feePeriodFrom: _s(b['feePeriodFrom']),
        feePeriodTo: _s(b['feePeriodTo']),
        txnId: _s(b['txnId']),
      );
  final String receiptNo;
  final String date;
  final String student;
  final num amount;
  final String mode;
  final String paymentMode;
  final String status;
  final String entityId;
  final String pdfUrl;
  final bool excluded;
  final String feePeriodFrom;
  final String feePeriodTo;
  final String txnId;
}

class Teacher {
  Teacher({
    required this.teacherId,
    required this.teacherName,
    required this.primaryRole,
    required this.payoutStreams,
    required this.payoutModel,
    required this.branchClassCode,
    required this.status,
    required this.phone,
    required this.email,
  });
  factory Teacher.fromApi(Map<String, dynamic> b) => Teacher(
        teacherId: _s(b['teacherId']),
        teacherName: _s(b['teacherName']),
        primaryRole: _s(b['primaryRole']),
        payoutStreams: _s(b['payoutStreams']),
        payoutModel: _s(b['payoutModel']),
        branchClassCode: _s(b['branchClassCode']),
        status: _s(b['status']),
        phone: _s(b['phone']),
        email: _s(b['email']),
      );
  final String teacherId;
  final String teacherName;
  final String primaryRole;
  final String payoutStreams;
  final String payoutModel;
  final String branchClassCode;
  final String status;
  final String phone;
  final String email;
}

class ExpenseEntry {
  ExpenseEntry({
    required this.entryId,
    required this.date,
    required this.category,
    required this.description,
    required this.amount,
    required this.type,
    required this.mode,
    required this.approvalStatus,
    required this.status,
  });
  factory ExpenseEntry.fromApi(Map<String, dynamic> b) => ExpenseEntry(
        entryId: _s(b['entryId'] ?? b['id'] ?? ''),
        date: _s(b['date']),
        category: _s(b['category']),
        description: _s(b['description'] ?? b['narrative']),
        amount: _n(b['amount']),
        type: _s(b['type'] ?? b['flow']),
        mode: _s(b['mode']),
        approvalStatus: _s(b['approvalStatus']),
        status: _s(b['status']),
      );
  final String entryId;
  final String date;
  final String category;
  final String description;
  final num amount;
  final String type;
  final String mode;
  final String approvalStatus;
  final String status;
}

class Inquiry {
  Inquiry({
    required this.inquiryId,
    required this.name,
    required this.phone,
    required this.course,
    required this.branch,
    required this.status,
    required this.followUpDate,
    required this.createdAt,
  });
  factory Inquiry.fromApi(Map<String, dynamic> b) => Inquiry(
        inquiryId: _s(b['inquiryId'] ?? b['id'] ?? b['inquiry_id']),
        name: _s(b['name'] ?? b['studentName']),
        phone: _s(b['phone']),
        course: _s(b['course'] ?? b['instrument']),
        branch: _s(b['branch']),
        status: _s(b['status']),
        followUpDate: _s(b['followUpDate'] ?? b['followUp'] ?? b['next_contact_date']),
        createdAt: _s(b['createdAt'] ?? b['created_at']),
      );
  final String inquiryId;
  final String name;
  final String phone;
  final String course;
  final String branch;
  final String status;
  final String followUpDate;
  final String createdAt;
  bool get actionable => status.toUpperCase() == 'NEW' || status.toUpperCase() == 'FOLLOW_UP';
}

class TaskCard {
  TaskCard({
    required this.key,
    required this.title,
    required this.priority,
    required this.count,
    required this.state,
    required this.label,
    required this.emptyText,
    required this.targetView,
    required this.actionable,
  });
  factory TaskCard.fromApi(Map<String, dynamic> b) => TaskCard(
        key: _s(b['key']),
        title: _s(b['title'] ?? b['label']),
        priority: _s(b['priority']),
        count: (b['count'] as num?)?.toInt(),
        state: _s(b['state']),
        label: _s(b['label']),
        emptyText: _s(b['emptyText']),
        targetView: _s(b['targetView'] ?? b['destination']),
        actionable: b['actionable'] == true,
      );
  final String key;
  final String title;
  final String priority;
  final int? count;
  final String state;
  final String label;
  final String emptyText;
  final String targetView;
  final bool actionable;

  bool get needsAttention => state == 'ATTENTION' || (count ?? 0) > 0;
}

class TodaysClass {
  TodaysClass({
    required this.eventId,
    required this.classDate,
    required this.startTime,
    required this.teacherId,
    required this.branch,
    required this.course,
    required this.outcome,
    required this.deliveredBy,
    required this.payeeTeacherId,
    required this.entryDate,
    required this.recordedBy,
    required this.evidenceClass,
    required this.evidenceReason,
    required this.notRequired,
    required this.closureReason,
    required this.customKind,
    required this.customReason,
    required this.resolved,
    required this.answerable,
  });
  factory TodaysClass.fromApi(Map<String, dynamic> b) => TodaysClass(
        eventId: _s(b['eventId']),
        classDate: _s(b['classDate']),
        startTime: _s(b['startTime']),
        teacherId: _s(b['teacherId']),
        branch: _s(b['branch']),
        course: _s(b['course']),
        outcome: _s(b['outcome']),
        deliveredBy: _s(b['deliveredBy']),
        payeeTeacherId: _s(b['payeeTeacherId']),
        entryDate: _s(b['entryDate']),
        recordedBy: _s(b['recordedBy']),
        evidenceClass: _s(b['evidenceClass']),
        evidenceReason: _s(b['evidenceReason']),
        notRequired: b['notRequired'] == true,
        closureReason: _s(b['closureReason']),
        customKind: _s(b['customKind']),
        customReason: _s(b['customReason']),
        resolved: b['resolved'] == true,
        answerable: b['answerable'] == true,
      );
  final String eventId;
  final String classDate;
  final String startTime;
  final String teacherId;
  final String branch;
  final String course;
  final String outcome;
  final String deliveredBy;
  final String payeeTeacherId;
  final String entryDate;
  final String recordedBy;
  final String evidenceClass;
  final String evidenceReason;
  final bool notRequired;
  final String closureReason;
  final String customKind;
  final String customReason;
  final bool resolved;
  final bool answerable;

  bool get isHeld => outcome.toUpperCase() == 'HELD';
  bool get isCancelled => ['TEACHER_CANCELLED', 'ACADEMY_CANCELLED'].contains(outcome.toUpperCase());
  bool get isSubstituted => outcome.toUpperCase() == 'SUBSTITUTE_DELIVERED';
}

class TodaysClassOptions {
  TodaysClassOptions({
    required this.date,
    required this.rows,
    required this.count,
    required this.unanswered,
    required this.outcomes,
  });
  factory TodaysClassOptions.fromApi(Map<String, dynamic> b) => TodaysClassOptions(
        date: _s(b['date']),
        rows: ((b['rows'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TodaysClass.fromApi)
            .toList(),
        count: (b['count'] as num?)?.toInt() ?? 0,
        unanswered: (b['unanswered'] as num?)?.toInt() ?? 0,
        outcomes: ((b['outcomes'] as List?) ?? const []).map((e) => _s(e)).toList(),
      );
  final String date;
  final List<TodaysClass> rows;
  final int count;
  final int unanswered;
  final List<String> outcomes;
}

class ApprovalItem {
  ApprovalItem({
    required this.type,
    required this.itemId,
    required this.entity,
    required this.studentId,
    required this.noStudentLinked,
    required this.paymentMode,
    required this.feesPeriod,
    required this.amount,
    required this.branch,
    required this.date,
    required this.reason,
    required this.backdated,
    required this.incomplete,
    required this.junk,
    required this.termsStatus,
    required this.actions,
  });
  factory ApprovalItem.fromApi(Map<String, dynamic> b) {
    final f = b['flags'] is Map<String, dynamic>
        ? b['flags'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return ApprovalItem(
      type: _s(b['type']),
      itemId: _s(b['itemId']),
      entity: _s(b['entity']),
      studentId: _s(b['studentId']),
      noStudentLinked: b['noStudentLinked'] == true,
      paymentMode: _s(b['paymentMode']),
      feesPeriod: _s(b['feesPeriod']),
      amount: _s(b['amount']),
      branch: _s(b['branch']),
      date: _s(b['date']),
      reason: _s(b['reason']),
      backdated: f['backdated'] == true,
      incomplete: f['incomplete'] == true,
      junk: f['junk'] == true,
      termsStatus: _s(b['termsStatus']),
      actions: ((b['actions'] as List?) ?? const []).map((e) => _s(e)).toList(),
    );
  }
  final String type;
  final String itemId;
  final String entity;
  final String studentId;
  final bool noStudentLinked;
  final String paymentMode;
  final String feesPeriod;
  final String amount;
  final String branch;
  final String date;
  final String reason;
  final bool backdated;
  final bool incomplete;
  final bool junk;
  final String termsStatus;
  final List<String> actions;

  bool get isPayment => type == 'PAYMENT_DRAFT';
  bool get isStudent => type == 'STUDENT_DRAFT';
}

class ApprovalGroup {
  ApprovalGroup({required this.type, required this.label, required this.items});
  factory ApprovalGroup.fromApi(Map<String, dynamic> b) => ApprovalGroup(
        type: _s(b['type']),
        label: _s(b['label']),
        items: ((b['items'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ApprovalItem.fromApi)
            .toList(),
      );
  final String type;
  final String label;
  final List<ApprovalItem> items;
}

class ApprovalsData {
  ApprovalsData({required this.count, required this.groups, required this.empty});
  factory ApprovalsData.fromApi(Map<String, dynamic> b) => ApprovalsData(
        count: (b['count'] as num?)?.toInt() ?? 0,
        groups: ((b['groups'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ApprovalGroup.fromApi)
            .toList(),
        empty: b['empty'] == true,
      );
  final int count;
  final List<ApprovalGroup> groups;
  final bool empty;
}

class CommMessage {
  CommMessage({
    required this.type,
    required this.subject,
    required this.body,
    required this.recipientName,
    required this.recipientType,
    required this.typeRequested,
    required this.typeResolved,
    required this.typeCorrected,
    required this.typeNote,
    required this.mode,
    required this.providerSend,
    required this.termsLink,
    required this.warnings,
  });
  factory CommMessage.fromApi(Map<String, dynamic> b) => CommMessage(
        type: _s(b['type']),
        subject: _s(b['subject']),
        body: _s(b['body']),
        recipientName: _s(b['recipientName']),
        recipientType: _s(b['recipientType']),
        typeRequested: _s(b['typeRequested']),
        typeResolved: _s(b['typeResolved']),
        typeCorrected: b['typeCorrected'] == true,
        typeNote: _s(b['typeNote']),
        mode: _s(b['mode']),
        providerSend: _s(b['providerSend']),
        termsLink: _s(b['termsLink']),
        warnings: ((b['warnings'] as List?) ?? const []).map((e) => _s(e)).toList(),
      );
  final String type;
  final String subject;
  final String body;
  final String recipientName;
  final String recipientType;
  final String typeRequested;
  final String typeResolved;
  final bool typeCorrected;
  final String typeNote;
  final String mode;
  final String providerSend;
  final String termsLink;
  final List<String> warnings;

  bool get copyOnly => mode.toUpperCase().contains('COPY_ONLY');
  bool get sendDisabled => providerSend.toUpperCase().contains('DISABLED');
}

/// Machine-readable money formatting shared across the app.
String inr(num amount) {
  final v = amount.toDouble();
  final sign = v < 0 ? '-' : '';
  final av = v.abs();
  final parts = av.toStringAsFixed(0).split('.');
  final last3 = parts[0].length > 3 ? parts[0].substring(parts[0].length - 3) : parts[0];
  final rest = parts[0].length > 3 ? parts[0].substring(0, parts[0].length - 3) : '';
  String grouped = rest.isEmpty ? last3 : '${_group2(rest)},$last3';
  return '$sign₹$grouped';
}

String _group2(String s) {
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 2 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String moneyRounded(num amount) {
  final v = _n(amount);
  return (v % 1 == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}