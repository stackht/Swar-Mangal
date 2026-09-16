// Plain data models mirroring the Railway RPC `api_*` response shapes.
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
    required this.feePlan,
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
        feePlan: _s(b['feePlan']),
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
  final String feePlan;
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
    this.academyShare = '',
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
        academyShare: _s(b['academyShare']),
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
  final String academyShare;

  String get shareLabel => academyShare.isEmpty ? '' : (academyShare.endsWith('%') ? academyShare : '$academyShare%');
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

/// A staff-approved payment draft ("approved, receipt not yet created").
class PendingFinaliseDraft {
  PendingFinaliseDraft({
    required this.draftId,
    required this.amount,
    required this.paymentDate,
    required this.approvalAuthority,
    required this.approvedBy,
    required this.founderDecision,
    required this.label,
    required this.repairRequired,
    required this.status,
    required this.canFinalise,
    required this.blockedReason,
  });
  factory PendingFinaliseDraft.fromApi(Map<String, dynamic> b) =>
      PendingFinaliseDraft(
        draftId: _s(b['draftId']),
        amount: _s(b['amount']),
        paymentDate: _s(b['paymentDate']),
        approvalAuthority: _s(b['approvalAuthority']),
        approvedBy: _s(b['approvedBy']),
        founderDecision: b['founderDecision'] == true,
        label: _s(b['label']),
        repairRequired: b['repairRequired'] == true,
        status: _s(b['status']),
        canFinalise: b['canFinalise'] == true,
        blockedReason: _s(b['blockedReason']),
      );
  final String draftId;
  final String amount;
  final String paymentDate;
  final String approvalAuthority;
  final String approvedBy;
  final bool founderDecision;
  final String label;
  final bool repairRequired;
  final String status;
  final bool canFinalise;
  final String blockedReason;
}

/// Staff Student Hub — one call carrying profile + pending receipts + terms.
/// A founder payment-draft queue row (SUBMITTED → approve/reject;
/// APPROVED → finalise into a real receipt). From api_founder_listPaymentDrafts.
class PaymentDraftRow {
  PaymentDraftRow({
    required this.draftId,
    required this.status,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.paymentMode,
    required this.branch,
    required this.termsStatus,
    required this.projectNextDueDate,
    required this.repairRequired,
    required this.submittedAt,
    this.approvalAuthority = '',
    this.approvedBy = '',
  });
  factory PaymentDraftRow.fromApi(Map<String, dynamic> b) {
    return PaymentDraftRow(
      draftId: _s(b['draftId']),
      status: _s(b['status']),
      studentId: _s(b['studentId']),
      studentName: _s(b['studentName']),
      amount: _s(b['amount']),
      paymentMode: _s(b['paymentMode']),
      branch: _s(b['branch']),
      termsStatus: _s(b['termsStatus']),
      projectNextDueDate: _s(b['projectedNextDueDate']),
      repairRequired: b['repairRequired'] == true,
      submittedAt: _s(b['submittedAt']),
      approvalAuthority: _s(b['approvalAuthority']),
      approvedBy: _s(b['approvedBy']),
    );
  }
  final String draftId;
  final String status;
  final String studentId;
  final String studentName;
  final String amount;
  final String paymentMode;
  final String branch;
  final String termsStatus;
  final String projectNextDueDate;
  final bool repairRequired;
  final String submittedAt;
  final String approvalAuthority;
  final String approvedBy;

  bool get approved => status.toUpperCase() == 'APPROVED';
  bool get waitingTerms => status.toUpperCase() == 'PENDING_TERMS_AND_APPROVAL';

  /// Honest authority label — never invent a founder name for ROUTINE_LANE.
  String get authorityLabel {
    final a = approvalAuthority.toUpperCase();
    if (a == 'ROUTINE_LANE') return 'Routine lane (system rules — no founder)';
    if (a == 'FOUNDER' && approvedBy.isNotEmpty) return 'Approved by $approvedBy';
    if (a == 'FOUNDER') return 'Approved by founder';
    return '—';
  }
}

/// A single founder teacher-payout preview row (server-computed payable).
/// Never compute payouts on the device — display only.
/// One payment actually made to a teacher (api_recordTeacherPayout /
/// api_teacherPayoutHistory).
class PayoutPayment {
  PayoutPayment({
    required this.payoutId,
    required this.teacherId,
    required this.teacherName,
    required this.month,
    required this.amount,
    required this.paidOn,
    required this.paymentMode,
    required this.reference,
  });
  factory PayoutPayment.fromApi(Map<String, dynamic> b) {
    num n(dynamic v) {
      final s = v == null ? '' : v.toString().replaceAll(RegExp(r'[^\d.\-]'), '');
      return double.tryParse(s) ?? 0;
    }
    return PayoutPayment(
      payoutId: _s(b['payoutId']),
      teacherId: _s(b['teacherId']),
      teacherName: _s(b['teacherName']),
      month: _s(b['month']),
      amount: n(b['amount']),
      paidOn: _s(b['paidOn']),
      paymentMode: _s(b['paymentMode']),
      reference: _s(b['reference']),
    );
  }
  final String payoutId;
  final String teacherId;
  final String teacherName;
  final String month;
  final num amount;
  final String paidOn;
  final String paymentMode;
  final String reference;
}

class PayoutRow {
  PayoutRow({
    required this.teacherId,
    required this.teacherName,
    required this.month,
    required this.entityId,
    required this.receiptCount,
    required this.totalCollection,
    required this.totalTeacherShare,
    required this.payable,
    required this.alreadyPaid,
    required this.balance,
    required this.status,
    required this.preCutover,
    required this.note,
  });
  factory PayoutRow.fromApi(Map<String, dynamic> b) {
    num n(dynamic v) {
      final s = v == null ? '' : v.toString().replaceAll(RegExp(r'[^\d.\-]'), '');
      return double.tryParse(s) ?? 0;
    }
    return PayoutRow(
      teacherId: _s(b['teacherId']),
      teacherName: _s(b['teacherName']),
      month: _s(b['month']),
      entityId: _s(b['entityId']),
      receiptCount: (b['receiptCount'] as num?)?.toInt() ?? 0,
      totalCollection: n(b['totalCollection']),
      totalTeacherShare: n(b['totalTeacherShare']),
      payable: n(b['payable']),
      alreadyPaid: n(b['alreadyPaid'] ?? b['paid']),
      balance: n(b['balance']),
      status: _s(b['status']),
      preCutover: b['preCutover'] == true,
      note: _s(b['note']),
    );
  }
  final String teacherId;
  final String teacherName;
  final String month;
  final String entityId;
  final int receiptCount;
  final num totalCollection;
  final num totalTeacherShare;
  final num payable;
  final num alreadyPaid;
  final num balance;
  final String status;
  final bool preCutover;
  final String note;
}

/// Staff "My Requests" — persisted drafts awaiting (or resolved by) founder.
class ApprovalRequestRow {
  ApprovalRequestRow({
    required this.type,
    required this.id,
    required this.status,
    required this.student,
    required this.category,
    required this.amount,
    required this.when,
    required this.backdated,
  });
  factory ApprovalRequestRow.fromApi(Map<String, dynamic> b) => ApprovalRequestRow(
        type: _s(b['type']),
        id: _s(b['id']),
        status: _s(b['status']),
        student: _s(b['student']),
        category: _s(b['category']),
        amount: _s(b['amount']),
        when: _s(b['when']),
        backdated: b['backdated'] == true,
      );
  final String type;
  final String id;
  final String status;
  final String student;
  final String category;
  final String amount;
  final String when;
  final bool backdated;

  bool get waiting => status.toUpperCase() == 'SUBMITTED' ||
      status.toUpperCase() == 'PENDING_TERMS_AND_APPROVAL' ||
      status.toUpperCase() == 'BACKDATED_APPROVAL_REQUIRED';
}

class StaffHub {
  StaffHub({
    required this.profile,
    required this.pending,
    required this.feesTotal,
    required this.feeStatus,
    required this.dueDate,
    required this.canonicalFee,
  });
  factory StaffHub.fromApi(Map<String, dynamic> b) {
    final p = b['profile'] is Map<String, dynamic>
        ? b['profile'] as Map<String, dynamic>
        : <String, dynamic>{};
    final pending =
        b['pending'] is Map<String, dynamic> ? b['pending'] as Map<String, dynamic> : const <String, dynamic>{};
    final fees = b['fees'] is Map<String, dynamic> ? b['fees'] as Map<String, dynamic> : const <String, dynamic>{};
    return StaffHub(
      profile: Student.fromApi({
        ...p,
        'studentId': _s(p['studentId']),
        'feeStatus': _s(p['feeStatus']),
      }),
      pending: ((pending['rows'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PendingFinaliseDraft.fromApi)
          .toList(),
      feesTotal: _n(fees['total']).toString(),
      feeStatus: _s(p['feeStatus']),
      dueDate: _s(p['dueDate']),
      canonicalFee: _s(p['fee']),
    );
  }
  final Student profile;
  final List<PendingFinaliseDraft> pending;
  final String feesTotal;
  final String feeStatus;
  final String dueDate;
  final String canonicalFee;
}

/// Authoritative teacher profile (+ assigned students) from the profile
/// endpoint contract. Display-only financial fields come from the server.
class TeacherProfile {
  TeacherProfile({
    required this.teacher,
    required this.students,
    required this.receiptCountThisMonth,
  });
  factory TeacherProfile.fromApi(Map<String, dynamic> b) {
    final t = b['teacher'] is Map<String, dynamic>
        ? b['teacher'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return TeacherProfile(
      teacher: Teacher.fromApi({
        ...t,
        'teacherId': _s(t['teacherId']),
        'teacherName': _s(t['teacherName'] ?? t['name']),
        'primaryRole': _s(t['primaryRole'] ?? t['instrument'] ?? t['role']),
        'status': _s(t['status']),
        'academyShare': _s(t['compensationPercent'] ?? t['feeSharePercent'] ?? t['academyShare']),
        'payoutStreams': _s(t['payoutStreams']),
        'payoutModel': _s(t['payoutModel']),
      }),
      students: ((b['students'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Student.fromApi)
          .toList(),
      receiptCountThisMonth: (b['receiptCountThisMonth'] as num?)?.toInt() ?? 0,
    );
  }
  final Teacher teacher;
  final List<Student> students;
  final int receiptCountThisMonth;

  /// Server-provided compensation percentage, if any ('' = unset).
  String get sharePercent => _share(teacher.academyShare);

  static String _share(String v) => v.isEmpty ? '' : (v.endsWith('%') ? v : '$v%');

  bool get hasStudents => students.isNotEmpty;
}

/// Rich, role-appropriate student profile detail.
class StudentProfileDetail {
  StudentProfileDetail({
    required this.student,
    required this.teacher,
    required this.teacherId,
    required this.branch,
  });
  factory StudentProfileDetail.fromApi(Map<String, dynamic> b) {
    final s = b['student'] is Map<String, dynamic>
        ? b['student'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final t = b['teacher'] is Map<String, dynamic>
        ? b['teacher'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return StudentProfileDetail(
      student: Student.fromApi({
        ...s,
        'teacher': _s(s['teacherName'] ?? t['teacherName'] ?? s['teacher']),
      }),
      teacher: t['teacherName'] != null || t['teacherId'] != null
          ? t
          : null,
      teacherId: _s(s['teacherId'] ?? t['teacherId']),
      branch: _s(s['branch'] ?? s['location']),
    );
  }
  final Student student;

  /// Raw teacher map when the backend returned one (kept untyped-avoidable).
  final Map<String, dynamic>? teacher;
  final String teacherId;
  final String branch;

  bool get hasTeacherId => teacherId.isNotEmpty && teacherId != '0' && teacherId != 'null';
  bool get hasTeacherName => student.teacher.isNotEmpty;
  bool get hasAssignedTeacher => hasTeacherId || hasTeacherName;

  /// True when the profile carries no teacher link at all.
  bool get noTeacherAssigned => !hasAssignedTeacher;

  String get teacherName => student.teacher;
}

/// Founder's compensation edit contract validation — percentages bounded 0..100.
class TeacherCompensationValidator {
  TeacherCompensationValidator._();

  static ({bool ok, String? error, num? value}) validate(String raw) {
    final v = num.tryParse(raw.trim());
    if (v == null) return (ok: false, error: 'Enter a whole number between 0 and 100.', value: null);
    if (v < 0 || v > 100) return (ok: false, error: 'Percentage must be between 0 and 100.', value: v);
    return (ok: true, error: null, value: v);
  }
}

/// UI access policy — compensation editing is founder-only. This is a
/// convenience layer: the BACKEND remains the authoritative gate.
class ProfilePolicy {
  ProfilePolicy._();

  static bool canEditCompensation({required bool staff}) => !staff;
}

/// Authorised signatory (owner) of a school invoice.
class InvoiceOwner {
  InvoiceOwner({required this.name, required this.id, required this.signatureUrl, this.title = ''});
  factory InvoiceOwner.fromApi(Map<String, dynamic> b) => InvoiceOwner(
        name: _s(b['name'] ?? b['ownerName']),
        id: _s(b['id'] ?? b['ownerId']),
        signatureUrl: _s(b['signatureUrl'] ?? b['signature']),
        title: _s(b['title']),
      );
  final String name;
  final String id;
  final String signatureUrl;
  final String title;
}

/// Authoritative SCHOOL-LEVEL invoice snapshot. No student dependency: the
/// document bills a CLASS, not a student, at the school level.
class SchoolInvoice {
  SchoolInvoice({
    required this.invoiceId,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.branch,
    required this.className,
    required this.amount,
    required this.tenure,
    required this.owner1,
    required this.owner2,
    this.pdfUrl = '',
    this.demo = false,
  });
  factory SchoolInvoice.fromApi(Map<String, dynamic> b) {
    final o1 = b['owner1'] is Map<String, dynamic>
        ? InvoiceOwner.fromApi(b['owner1'] as Map<String, dynamic>)
        : InvoiceOwner(name: _s(b['owner1Name']), id: '', signatureUrl: _s(b['owner1SignatureUrl']));
    final o2 = b['owner2'] is Map<String, dynamic>
        ? InvoiceOwner.fromApi(b['owner2'] as Map<String, dynamic>)
        : InvoiceOwner(name: _s(b['owner2Name']), id: '', signatureUrl: _s(b['owner2SignatureUrl']));
    return SchoolInvoice(
      invoiceId: _s(b['invoiceId']),
      invoiceNo: _s(b['invoiceNo']),
      invoiceDate: _s(b['invoiceDate']),
      branch: _s(b['branch'] ?? b['classCode']),
      className: _s(b['className']),
      amount: _n(b['amount']),
      tenure: _s(b['tenure']),
      pdfUrl: _s(b['pdfUrl']),
      demo: b['demo'] == true,
      owner1: o1,
      owner2: o2,
    );
  }
  final String invoiceId;
  final String invoiceNo;
  final String invoiceDate;
  final String branch;
  final String className;
  final num amount;
  final String tenure;
  final String pdfUrl;
  final bool demo;
  final InvoiceOwner owner1;
  final InvoiceOwner owner2;
}

/// Invoice list row (school-level history, no student).
class InvoiceSummary {
  InvoiceSummary({
    required this.invoiceNo,
    required this.invoiceDate,
    required this.tenure,
    required this.amount,
    required this.invoiceId,
    required this.className,
  });
  factory InvoiceSummary.fromApi(Map<String, dynamic> b) => InvoiceSummary(
        invoiceNo: _s(b['invoiceNo']),
        invoiceDate: _s(b['invoiceDate']),
        tenure: _s(b['tenure']),
        amount: _n(b['amount']),
        invoiceId: _s(b['invoiceId']),
        className: _s(b['className']),
      );
  final String invoiceNo;
  final String invoiceDate;
  final String tenure;
  final num amount;
  final String invoiceId;
  final String className;
}

/// Invoice input validation — amount numeric > 0, tenure + class required.
class InvoiceValidator {
  InvoiceValidator._();

  static ({bool ok, String? error, num? amount}) amount(String raw) {
    final v = num.tryParse(raw.trim().replaceAll(',', ''));
    if (v == null) return (ok: false, error: 'Enter a valid amount (INR).', amount: null);
    if (v <= 0) return (ok: false, error: 'Amount must be greater than zero.', amount: v);
    return (ok: true, error: null, amount: v);
  }

  static String? tenure(String raw) => raw.trim().isEmpty ? 'Pick a tenure.' : null;

  static String? className(String raw) => raw.trim().isEmpty ? 'Class name is required.' : null;
}

/// Day-of-week for the timetable (0 = Monday … 6 = Sunday, ISO).
const timetableDayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

/// One scheduled class on the branch timetable.
class TimetableEntry {
  const TimetableEntry({
    required this.id,
    required this.branch,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.className,
    this.teacherId = '',
    this.teacherName = '',
    this.status = 'ENABLED',
  });
  factory TimetableEntry.fromApi(Map<String, dynamic> b) => TimetableEntry(
        id: _s(b['id']),
        branch: _s(b['branch']),
        dayOfWeek: (b['dayOfWeek'] as num?)?.toInt() ?? 0,
        startTime: _s(b['startTime']),
        endTime: _s(b['endTime']),
        className: _s(b['className'] ?? b['instrument']),
        teacherId: _s(b['teacherId']),
        teacherName: _s(b['teacherName'] ?? b['teacher']),
        status: _s(b['status']).toUpperCase().isEmpty ? 'ENABLED' : _s(b['status']).toUpperCase(),
      );
  Map<String, dynamic> toWrite() => {
        'id': id,
        'branch': branch,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'className': className,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'status': status,
      };
  final String id;
  final String branch;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String className;
  final String teacherId;
  final String teacherName;
  final String status;

  String get dayLabel => dayOfWeek >= 0 && dayOfWeek < timetableDayNames.length ? timetableDayNames[dayOfWeek] : '?';
  bool get enabled => status == 'ENABLED';

  /// Human time "5:00 PM" from a "17:00" (HH:mm) value.
  String get timeLabelStart => time12(startTime);
  String get timeLabelEnd => time12(endTime);

  static String time12(String t) {
    final p = t.split(':');
    if (p.length < 2) return t;
    final h = int.tryParse(p[0]) ?? 0;
    final m = p[1];
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hh = h % 12 == 0 ? 12 : h % 12;
    return '$hh:$m $suffix';
  }
}

/// Timetable edit validation — time ordering + required fields.
class TimetableValidator {
  TimetableValidator._();

  static String? time(String raw) {
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(raw.trim())) return 'Time must be HH:mm.';
    final p = raw.split(':');
    final h = int.parse(p[0]);
    final m = int.parse(p[1]);
    if (h < 0 || h > 23 || m < 0 || m > 59) return 'Time out of range.';
    return null;
  }

  static ({bool ok, String? error}) range(String start, String end) {
    if (time(start) != null) return (ok: false, error: 'Start: ${time(start)}');
    if (time(end) != null) return (ok: false, error: 'End: ${time(end)}');
    if (start.compareTo(end) >= 0) return (ok: false, error: 'End time must be after start time.');
    return (ok: true, error: null);
  }

  static String? className(String raw) => raw.trim().isEmpty ? 'Class / instrument is required.' : null;
}

/// Timetable edit access policy (UI convenience; backend stays authoritative).
class TimetablePolicy {
  TimetablePolicy._();

  static bool canEdit({required bool staff}) => true;
}

/// Academy fee-plan catalog: 4 plans (display + add/edit picker).
const academyPlans = <({String key, String sessions, String amount, int months})>[
  (key: 'Plan 1', sessions: '1 session/week · 4/month', amount: '2,500', months: 0),
  (key: 'Plan 2', sessions: '2 sessions/week · 8/month', amount: '3,600', months: 0),
  (key: 'Plan 3', sessions: '1 session/week · 4/month for 3 months', amount: '6,500', months: 3),
  (key: 'Plan 4', sessions: '2 sessions/week · 8/month for 3 months', amount: '9,500', months: 3),
];

/// One-line plan description for the profile. Falls back to raw plan text.
String planSummary(String plan) {
  for (final p in academyPlans) {
    if (plan.toUpperCase().contains(p.key.toUpperCase())) {
      return '${p.key} · ${p.sessions} · ₹${p.amount}${p.months > 0 ? ' / ${p.months} mo' : ' / mo'}';
    }
  }
  return plan.trim().isEmpty ? '—' : plan;
}

/// Result of `api_syncChanges`: current server revisions + change markers.
/// The client compares against its known set and reloads ONLY changed
/// entities. Sync is a READ/INVALIDATION operation — it never writes.
class SyncSnapshot {
  SyncSnapshot({required this.revisions, required this.changes, required this.ok});
  factory SyncSnapshot.fromApi(Map<String, dynamic> b) {
    final revs = <String, int>{};
    final raw = b['revisions'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final n = (v as num?)?.toInt();
        if (n != null) revs['$k'] = n;
      });
    }
    return SyncSnapshot(
      ok: b['ok'] == true,
      revisions: revs,
      changes: ((b['changes'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(),
    );
  }
  final bool ok;
  final Map<String, int> revisions;
  final List<Map<String, dynamic>> changes;
}