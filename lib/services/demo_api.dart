import '../core/api.dart';

String _slice10(dynamic v) {
  final s = v == null ? '' : v.toString();
  return s.length > 10 ? s.substring(0, 10) : s;
}

/// Offline demo backend. Returns realistic canned payloads for every call the
/// screens make, so the whole UI can be smoke-tested on a device with no
/// network and no deployed gateway. Zero writes ever.
class DemoApiClient extends ApiClient {
  DemoApiClient({this.branch = 'ALL'})
      : super(execUrl: 'demo://local', token: 'demo');

  final String branch;

  /// Write endpoints that must carry DEMO provenance (no real write happens).
  static const _writes = <String>{
    'api_addStudent',
    'api_staff_saveStudentDraft',
    'api_addFeePayment',
    'api_staff_prepareReceiptDraft',
    'api_addTeacher',
    'api_addExpenseEntry',
    'api_staff_submitExpenseDraft',
    'api_staff_inquiryQuickAdd',
    'api_staff_inquiryTransition',
    'api_staff_markAttendance',
    'api_staff_scheduleSession',
    'api_staff_resolveTodaysClass',
    'api_founder_setStudentStatus',
    'api_updateTeacherStatus',
    'api_founder_paymentDraftApprove',
    'api_founder_paymentDraftReject',
    'api_founder_finalisePaymentDraft',
    'api_staff_finalisePaymentDraft',
    'api_founder_mergeStudentDraft',
    'api_updateTeacherCompensation',
  };

  @override
  Future<dynamic> call(String api, [Object? arg]) async {
    final a = (arg is Map) ? Map<String, dynamic>.from(arg) : <String, dynamic>{};
    final data = _route(api, a);
    await Future<void>.delayed(const Duration(milliseconds: 350)); // feel real
    if (_writes.contains(api) && data is Map<String, dynamic>) {
      data['demo'] = true;
      data['demoNote'] = 'DEMO — no real backend write. Not persisted.';
    }
    return data;
  }

  dynamic _route(String api, Map<String, dynamic> a) {
    switch (api) {
      case 'api_bootstrap':
        return _bootstrap();
      case 'api_staff_boot':
        return _staffBoot();
      case 'api_searchStudent':
      case 'api_staff_searchStudents':
        return _students(a);
      case 'api_staff_getStudentProfile':
        return _studentProfile(a);
      case 'api_dashboard':
        return _dashboard();
      case 'api_dueReminders':
        return _dueReminders();
      case 'api_searchReceipt':
        return _receipts(a);
      case 'api_listTeachers':
        return _teachers();
      case 'api_cashbookReport':
        return _cashbook();
      case 'api_staff_doToday':
      case 'api_staff_todaysTasks':
        return _todaysTasks();
      case 'api_staff_todaysClasses':
        return _todaysClasses(a);
      case 'api_staff_resolveTodaysClass':
        return _resolveTodaysClass(a);
      case 'api_staff_scheduleSession':
        return {
          'ok': true,
          'scheduledSessionId': 'SCSS-DEMO-${DateTime.now().millisecondsSinceEpoch}',
          'status': 'SCHEDULED',
          'sessionDate': a['sessionDate'] ?? '',
          'sessionCredit': a['sessionCredit'] ?? 1,
          'durationMinutes': a['durationMinutes'] ?? 60,
        };
      case 'api_staff_sessionRoster':
        return _sessionRoster();
      case 'api_staff_inquiryTransition':
        return _inquiryTransition(a);
      case 'api_founder_approvalsList':
        return _approvalsList();
      case 'api_founder_listPaymentDrafts':
        return _paymentDraftQueue();
      case 'api_founder_paymentDraftApprove':
        return {'ok': true, 'changed': true, 'draftId': a['draftId'], 'approved': true, 'note': 'demo approved'};
      case 'api_founder_paymentDraftReject':
        return {'ok': true, 'changed': true, 'draftId': a['draftId'], 'rejected': true, 'note': 'demo rejected'};
      case 'api_founder_mergeStudentDraft':
        return {'ok': true, 'created': true, 'draftId': a['draftId'], 'studentId': 'STU-DEMO-MERGED', 'note': 'demo merged'};
      case 'api_founder_finalisePaymentDraft':
      case 'api_staff_finalisePaymentDraft':
        return {
          'ok': true,
          'changed': true,
          'draftId': a['draftId'],
          'status': 'FINALISED',
          'receiptNo': 'RCP-DEMO-${9100 + (a['draftId']?.length ?? 0)}',
          'pdfUrl': '',
          'idempotent': false,
          'financialWrites': false,
          'finalisedBy': 'demo',
          'note': 'demo finalise — real money path writes receipt + ledger + due-date advance server-side',
        };
      case 'api_founder_setStudentStatus':
        return {
          'ok': true,
          'changed': true,
          'studentId': a['studentId'],
          'before': {'status': 'ACTIVE'},
          'after': {'status': a['status']},
          'reason': a['reason'],
          'auditWritten': true,
          'note': 'demo status changed',
        };
      case 'api_updateTeacherStatus':
        return {
          'ok': true,
          'teacherId': a['teacherId'],
          'oldStatus': 'ACTIVE',
          'newStatus': a['newStatus'],
          'message': 'demo teacher status updated',
        };
      case 'api_staff_studentHub':
        return _staffStudentHub(a);
      case 'api_teacherProfile':
        return _teacherProfile(a);
      case 'api_studentProfile':
        return _studentProfileDetail(a);
      case 'api_updateTeacherCompensation':
        return {
          'ok': true,
          'changed': true,
          'teacherId': a['teacherId'],
          'oldPercentage': '40',
          'newPercentage': '${a['percentage']}',
          'effectiveFrom': a['effectiveFrom'],
          'reason': a['reason'],
          'auditWritten': true,
          'note': 'demo compensation updated',
        };
      case 'api_teacherPayoutPreview':
        return _payoutPreview(a);
      case 'api_staff_listMyApprovals':
        return _staffMyRequests();
      case 'api_staff_commGenerate':
        return _commGenerate();
      case 'api_staff_attendanceRoster':
        return _attendanceRoster(a);
      case 'api_staff_inquiryQueue':
        return _inquiries();
      // write endpoints: demo returns success envelopes only
      case 'api_addStudent':
      case 'api_staff_saveStudentDraft':
        return {
          'ok': true,
          'studentId': 'STU-DEMO-${a['phone'] ?? a['name'] ?? ''}',
          'studentName': a['name'] ?? a['studentName'] ?? '',
          'duplicateWarning': {'hasDuplicates': false},
          'note': 'demo saved',
        };
      case 'api_addFeePayment':
        return {
          'ok': true,
          'receiptNo': 'RCP-${9000 + (a['amount'] ?? 0)}',
          'note': 'demo receipt created',
        };
      case 'api_staff_prepareReceiptDraft':
        return {
          'ok': true,
          'draftId': 'PDRAFT-DEMO-1',
          'routine': {'selfServe': true},
          'receiptNo': 'RCP-DEMO-1',
          'persisted': true,
          'note': 'demo draft — self-serve routine lane',
        };
      case 'api_addTeacher':
        return {'ok': true, 'teacherId': 'T-DEMO', 'note': 'demo teacher added'};
      case 'api_addExpenseEntry':
        return {'ok': true, 'entryId': 'EXP-DEMO', 'note': 'demo expense recorded'};
      case 'api_staff_submitExpenseDraft':
        return {'ok': true, 'draftId': 'EDRAFT-DEMO-1', 'persisted': true, 'note': 'demo expense draft'};
      case 'api_staff_inquiryQuickAdd':
        return {'ok': true, 'inquiryId': 'INQ-DEMO-${a['phone'] ?? ''}', 'idempotent': false, 'note': 'demo inquiry captured'};
      case 'api_staff_markAttendance':
        return {'ok': true, 'action': 'CREATED', 'attendanceId': 'ATT-DEMO', 'state': a['state'], 'workDate': a['workDate']};
      case 'api_staff_feeDueList':
        return {'ok': true, 'counts': {'dueToday': 3, 'dueSoon': 2, 'paymentPending': 1}};
      default:
        return {'ok': false, 'code': 'DEMO_UNKNOWN', 'error': 'No demo fixture for $api'};
    }
  }

  Map<String, dynamic> _bootstrap() => {
        'ok': true,
        'email': 'sharvil87@gmail.com',
        'role': 'FOUNDER_ADMIN',
        'name': 'Sharvil (Demo)',
        'accounts': ['Kotak UPI', 'HDFC', 'Cash'],
        'paymentModes': ['Cash', 'UPI', 'Bank Transfer', 'Cheque'],
        'planTypes': ['Monthly', '3 Months', '6 Months', 'Yearly'],
        'classCodes': ['GMC', 'KMC'],
        'feeCycleTypes': ['Monthly', '3 Months', '6 Months', 'Yearly'],
        'advanceReminderDays': 3,
        'dueReminders': _dueReminders(),
      };

  Map<String, dynamic> _staffBoot() => {
        'ok': true,
        'app': 'STAFF_APP',
        'actor': 'STAFF_APP',
        'email': 'smmahavirnagar@gmail.com',
        'isOpsAccount': true,
        'branches': ['GOREGAON', 'KANDIVALI'],
        'note': 'Demo staff session.',
      };

  List<Map<String, dynamic>> _studentRows() => [
        {
          'studentId': 'STU-55DCD622',
          'studentName': 'Aarav Mehta',
          'phone': '9820011223',
          'email': 'aarav@example.com',
          'instrument': 'Keyboard',
          'teacher': 'Rahul Joshi',
          'classCode': 'GMC',
          'className': 'Goregaon Music Class',
          'location': 'GOREGAON',
          'batch': 'Morning',
          'feeCycleType': 'Monthly',
          'feeDueDay': '5',
          'nextDueDate': '2026-09-05',
          'feeStatus': 'OVERDUE',
          'lastReceiptNo': 'RCP-2401',
          'lastReceiptAmount': '5000',
          'status': 'ACTIVE',
        },
        {
          'studentId': 'STU-77FA91C0',
          'studentName': 'Diya Shah',
          'phone': '9820022334',
          'email': ' ',
          'instrument': 'Violin',
          'teacher': 'Meera Nair',
          'classCode': 'GMC',
          'className': 'Goregaon Music Class',
          'location': 'GOREGAON',
          'batch': 'Evening',
          'feeCycleType': '3 Months',
          'feeDueDay': '10',
          'nextDueDate': '2026-09-14',
          'feeStatus': 'DUE_SOON',
          'lastReceiptNo': 'RCP-2398',
          'lastReceiptAmount': '12000',
          'status': 'ACTIVE',
        },
        {
          'studentId': 'STU-31B84E07',
          'studentName': 'Ishaan Verma',
          'phone': '9820033445',
          'email': ' ',
          'instrument': 'Guitar',
          'teacher': 'Rahul Joshi',
          'classCode': 'KMC',
          'className': 'Kandivali Music Class',
          'location': 'KANDIVALI',
          'batch': 'Afternoon',
          'feeCycleType': 'Monthly',
          'feeDueDay': '2',
          'nextDueDate': '2026-09-02',
          'feeStatus': 'DUE_TODAY',
          'lastReceiptNo': 'RCP-2380',
          'lastReceiptAmount': '5500',
          'status': 'ACTIVE',
        },
        {
          'studentId': 'STU-A9C3D2F1',
          'studentName': 'Kaia Roy',
          'phone': '9820044556',
          'email': 'kaiaroy@example.com',
          'instrument': 'Tabla',
          'teacher': 'Vikram Singh',
          'classCode': 'GMC',
          'className': 'Goregaon Music Class',
          'location': 'GOREGAON',
          'batch': 'Morning',
          'feeCycleType': 'Monthly',
          'feeDueDay': '15',
          'nextDueDate': '2026-09-15',
          'feeStatus': 'PAID',
          'lastReceiptNo': 'RCP-2375',
          'lastReceiptAmount': '4500',
          'status': 'ACTIVE',
        },
        {
          'studentId': 'STU-5E7FAB12',
          'studentName': 'Veer Kulkarni',
          'phone': '9820055667',
          'email': ' ',
          'instrument': 'Tabla',
          'teacher': 'Vikram Singh',
          'classCode': 'GMC',
          'className': 'Goregaon Music Class',
          'location': 'GOREGAON',
          'batch': 'Evening',
          'feeCycleType': 'Monthly',
          'feeDueDay': '18',
          'nextDueDate': '2026-09-18',
          'feeStatus': 'DUE_SOON',
          'lastReceiptNo': '',
          'lastReceiptAmount': '',
          'status': 'ACTIVE',
        },
      ];

  Map<String, dynamic> _students(Map<String, dynamic> a) {
    final q = ((a['q'] ?? '') as String).toLowerCase().trim();
    var all = _studentRows();
    final cc = ((a['classCode'] ?? 'ALL') as String).toUpperCase();
    if (cc != 'ALL') {
      all = all.where((s) => (s['classCode'] as String) == cc).toList();
    }
    if (q.isNotEmpty) {
      all = all
          .where((s) => [
                s['studentName'],
                s['phone'],
                s['studentId'],
                s['instrument'],
              ].join(' ').toLowerCase().contains(q))
          .toList();
    }
    return {'ok': true, 'results': all, 'rows': all, 'count': all.length};
  }

  Map<String, dynamic> _studentProfile(Map<String, dynamic> a) {
    final id = (a['studentId'] ?? '').toString();
    final s = _studentRows().firstWhere(
        (r) => r['studentId'] == id,
        orElse: () => _studentRows().first);
    return {
      'ok': true,
      'profile': {...s, 'parentName': 'Parent of ${s['studentName']}'},
    };
  }

  Map<String, dynamic> _dashboard() => {
        'ok': true,
        'todayCollection': 27500,
        'monthCollection': 184500,
        'todayCount': 5,
        'monthCount': 41,
        'cashToday': 9500,
        'onlineToday': 18000,
        'scope': 'ALL',
        'consolidated': true,
        'metrics': {
          'dueTodayCount': 3,
          'overdueCount': 2,
          'termsPendingCount': 4,
        },
        'recent': _receiptRows().take(6).toList(),
      };

  Map<String, dynamic> _dueReminders() => {
        'ok': true,
        'branch': 'ALL',
        'advanceDays': 3,
        'dueToday': _studentRows()
            .where((s) => s['feeStatus'] == 'DUE_TODAY')
            .map(_reminder)
            .toList(),
        'overdue': _studentRows()
            .where((s) => s['feeStatus'] == 'OVERDUE')
            .map(_reminder)
            .toList(),
        'dueSoon': _studentRows()
            .where((s) => s['feeStatus'] == 'DUE_SOON')
            .map(_reminder)
            .toList(),
        'gmcActive': 8,
        'kmcActive': 5,
      };

  Map<String, dynamic> _reminder(Map<String, dynamic> s) => {
        'studentName': s['studentName'],
        'phone': s['phone'],
        'classCode': s['classCode'],
        'instrument': s['instrument'],
        'nextDueDate': s['nextDueDate'],
        'feeStatus': s['feeStatus'],
        'lastReceiptNo': s['lastReceiptNo'],
      };

  List<Map<String, dynamic>> _receiptRows() => [
        {
          'receiptNo': 'RCP-2401',
          'date': '2026-09-05',
          'student': 'Aarav Mehta',
          'studentName': 'Aarav Mehta',
          'amount': 5000,
          'mode': 'UPI',
          'paymentMode': 'Online',
          'status': 'FINALISED',
          'entityId': 'ENT-GOREGAON',
          'pdfUrl': '',
          'excluded': false,
          'feePeriodFrom': '2026-09-05',
          'feePeriodTo': '2026-10-04',
          'txnId': 'UPI-88900123',
        },
        {
          'receiptNo': 'RCP-2400',
          'date': '2026-09-04',
          'student': 'Diya Shah',
          'studentName': 'Diya Shah',
          'amount': 12000,
          'mode': 'Kotak UPI',
          'paymentMode': 'Online',
          'status': 'FINALISED',
          'entityId': 'ENT-GOREGAON',
          'pdfUrl': '',
          'excluded': false,
          'feePeriodFrom': '2026-09-04',
          'feePeriodTo': '2026-12-03',
          'txnId': 'UPI-7799',
        },
        {
          'receiptNo': 'RCP-2398',
          'date': '2026-09-03',
          'student': 'Ishaan Verma',
          'studentName': 'Ishaan Verma',
          'amount': 5500,
          'mode': 'Cash',
          'paymentMode': 'Cash',
          'status': 'APPROVED',
          'entityId': 'ENT-KANDIVALI',
          'pdfUrl': '',
          'excluded': false,
          'feePeriodFrom': '',
          'feePeriodTo': '',
          'txnId': '',
        },
        {
          'receiptNo': 'RCP-2395',
          'date': '2026-09-01',
          'student': 'Kaia Roy',
          'studentName': 'Kaia Roy',
          'amount': 4500,
          'mode': 'UPI',
          'paymentMode': 'Online',
          'status': 'FINALISED',
          'entityId': 'ENT-GOREGAON',
          'pdfUrl': '',
          'excluded': false,
          'feePeriodFrom': '2026-09-01',
          'feePeriodTo': '2026-10-01',
          'txnId': 'UPI-112233',
        },
        {
          'receiptNo': 'RCP-2371',
          'date': '2026-08-28',
          'student': 'Rohit Pawar',
          'studentName': 'Rohit Pawar',
          'amount': 8800,
          'mode': 'Cheque',
          'paymentMode': 'Cheque',
          'status': 'VOID',
          'entityId': 'ENT-KANDIVALI',
          'pdfUrl': '',
          'excluded': true,
          'feePeriodFrom': '',
          'feePeriodTo': '',
          'txnId': '',
        },
      ];

  Map<String, dynamic> _receipts(Map<String, dynamic> a) {
    final q = ((a['q'] ?? a['studentName'] ?? a['receiptNo'] ?? '') as String)
        .toLowerCase()
        .trim();
    var rows = _receiptRows();
    if (q.isNotEmpty) {
      rows = rows
          .where((r) =>
              ('${r['receiptNo']} ${r['student']} ${r['txnId']}').toLowerCase().contains(q))
          .toList();
    }
    return {'ok': true, 'results': rows, 'total': rows.length};
  }

  Map<String, dynamic> _teachers() => {
        'ok': true,
        'teachers': [
          {
            'teacherId': 'T-001',
            'teacherName': 'Rahul Joshi',
            'academyShare': '40',

            'primaryRole': 'Guitar / Keyboard',
            'payoutStreams': 'ACADEMY|SCHOOL',
            'payoutModel': 'SHARE',
            'branchClassCode': 'GMC',
            'status': 'ACTIVE',
            'phone': '9833011223',
            'email': 'rahul.j@example.com',
          },
          {
            'teacherId': 'T-002',
            'teacherName': 'Meera Nair',
            'academyShare': '45',

            'primaryRole': 'Violin',
            'payoutStreams': 'ACADEMY',
            'payoutModel': 'SHARE',
            'branchClassCode': 'GMC',
            'status': 'ACTIVE',
            'phone': '9833022334',
            'email': 'meera.n@example.com',
          },
          {
            'teacherId': 'T-003',
            'teacherName': 'Vikram Singh',
            'academyShare': '50',

            'primaryRole': 'Tabla',
            'payoutStreams': 'ACADEMY',
            'payoutModel': 'SHARE',
            'branchClassCode': 'KMC',
            'status': 'ACTIVE',
            'phone': '9833033445',
            'email': 'vikram.s@example.com',
          },
          {
            'teacherId': 'T-004',
            'teacherName': 'Anita Deshpande',
            'primaryRole': 'Vocal Training',
            'payoutStreams': 'SCHOOL',
            'payoutModel': 'RETAINER',
            'branchClassCode': 'KMC',
            'status': 'INACTIVE',
            'phone': '9833044556',
            'email': '',
          },
        ],
      };

  Map<String, dynamic> _cashbook() => {
        'ok': true,
        'entries': [
          {
            'entryId': 'EXP-101',
            'date': '2026-09-05',
            'category': 'Rent',
            'description': 'Classroom rent — Goregaon',
            'amount': 15000,
            'type': 'EXPENSE',
            'mode': 'UPI',
            'approvalStatus': 'APPROVED',
            'status': 'ACTIVE',
          },
          {
            'entryId': 'EXP-102',
            'date': '2026-09-04',
            'category': 'Maintenance',
            'description': 'Instrument strings & repair',
            'amount': 2400,
            'type': 'EXPENSE',
            'mode': 'Cash',
            'approvalStatus': 'APPROVED',
            'status': 'ACTIVE',
          },
          {
            'entryId': 'EXP-103',
            'date': '2026-09-02',
            'category': 'School invoice',
            'description': 'MHWS school billed — September',
            'amount': 85000,
            'type': 'INFLOW',
            'mode': 'Bank Transfer',
            'approvalStatus': 'APPROVED',
            'status': 'ACTIVE',
          },
        ],
      };

  List<Map<String, dynamic>> _taskCards() => [
        {
          'key': 'FEES_DUE_TODAY',
          'title': 'Fees Due Today',
          'label': 'Fees Due Today',
          'priority': 'HIGH',
          'count': 3,
          'state': 'ATTENTION',
          'targetView': 'students',
          'emptyText': 'No fees due today',
          'actionable': true,
          'bucket': 'DUE_TODAY',
        },
        {
          'key': 'FEES_DUE_SOON',
          'title': 'Fees Upcoming',
          'label': 'Fees Upcoming',
          'priority': 'MEDIUM',
          'count': 2,
          'state': 'OPEN',
          'targetView': 'students',
          'emptyText': 'Nothing upcoming',
          'actionable': true,
          'bucket': 'DUE_SOON',
        },
        {
          'key': 'PAYMENT_PENDING',
          'title': 'Payment Pending',
          'label': 'Payment Pending',
          'priority': 'HIGH',
          'count': 1,
          'state': 'ATTENTION',
          'targetView': 'students',
          'emptyText': 'No pending payments',
          'actionable': true,
        },
        {
          'key': 'CAP_REVIEW',
          'title': 'Cap Review',
          'label': 'Cap Review — status check',
          'priority': 'HIGH',
          'count': 1,
          'state': 'OPEN',
          'targetView': 'students',
          'emptyText': 'No cap review',
          'actionable': true,
        },
        {
          'key': 'TERMS_PENDING',
          'title': 'Terms Pending',
          'label': 'Terms Pending',
          'priority': 'MEDIUM',
          'count': 4,
          'state': 'OPEN',
          'targetView': 'students',
          'emptyText': 'All terms accepted',
          'actionable': true,
        },
        {
          'key': 'INQUIRIES_FOLLOW_UP',
          'title': 'Inquiries to follow up',
          'label': 'Inquiries to follow up',
          'priority': 'MEDIUM',
          'count': 2,
          'state': 'OPEN',
          'targetView': 'inquiries',
          'emptyText': 'No inquiries',
          'actionable': true,
        },
        {
          'key': 'FINANCIAL_EXCEPTIONS_PENDING',
          'title': 'Financial Exceptions',
          'label': 'Financial Exceptions Pending',
          'priority': 'HIGH',
          'count': 0,
          'state': 'CLEAR',
          'targetView': 'approvals',
          'emptyText': 'None',
          'actionable': false,
        },
        {
          'key': 'MY_REQUESTS',
          'title': 'My Requests',
          'label': 'My Requests',
          'priority': 'MEDIUM',
          'count': 0,
          'state': 'CLEAR',
          'targetView': 'myRequests',
          'emptyText': 'Nothing waiting',
          'actionable': false,
        },
      ];

  Map<String, dynamic> _todaysClasses(Map<String, dynamic> a) {
    final date = _slice10(a['date'] ?? '2026-09-11');
    return {
      'ok': true,
      'date': date,
      'count': 3,
      'unanswered': 2,
      'outcomes': ['HELD', 'TEACHER_CANCELLED', 'ACADEMY_CANCELLED', 'SUBSTITUTE_DELIVERED', 'RESCHEDULED'],
      'rows': [
        {
          'eventId': 'E-2026-09-11-A',
          'classDate': date,
          'startTime': '18:00',
          'teacherId': 'T-003',
          'branch': 'KANDIVALI',
          'course': 'Tabla',
          'outcome': '',
          'deliveredBy': '',
          'payeeTeacherId': '',
          'entryDate': '',
          'recordedBy': '',
          'evidenceClass': '',
          'evidenceReason': '',
          'notRequired': false,
          'closureId': '',
          'closureReason': '',
          'customKind': '',
          'customReason': '',
          'resolved': false,
          'answerable': true,
        },
        {
          'eventId': 'E-2026-09-11-B',
          'classDate': date,
          'startTime': '17:00',
          'teacherId': 'T-001',
          'branch': 'GOREGAON',
          'course': 'Keyboard',
          'outcome': '',
          'deliveredBy': '',
          'payeeTeacherId': '',
          'entryDate': '',
          'recordedBy': '',
          'evidenceClass': '',
          'evidenceReason': '',
          'notRequired': false,
          'closureId': '',
          'closureReason': '',
          'customKind': '',
          'customReason': '',
          'resolved': false,
          'answerable': true,
        },
        {
          'eventId': 'E-2026-09-11-C',
          'classDate': date,
          'startTime': '16:00',
          'teacherId': 'T-002',
          'branch': 'GOREGAON',
          'course': 'Violin',
          'outcome': 'HELD',
          'deliveredBy': 'T-002',
          'payeeTeacherId': 'T-002',
          'entryDate': '2026-09-11',
          'recordedBy': 'ops@demo',
          'evidenceClass': 'VERIFIED',
          'evidenceReason': 'marked in the room',
          'notRequired': false,
          'closureId': '',
          'closureReason': '',
          'customKind': '',
          'customReason': '',
          'resolved': true,
          'answerable': false,
        },
      ],
      'lateHours': 48,
      'note': 'demo classes',
    };
  }

  Map<String, dynamic> _resolveTodaysClass(Map<String, dynamic> a) => {
        'ok': true,
        'eventId': a['eventId'],
        'outcome': a['outcome'],
        'evidenceClass': a['eventId'] == 'E-2026-09-11-A' ? 'VERIFIED' : 'REMEMBERED',
        'payeeTeacherId': a['deliveredBy'] ?? '',
        'note': 'demo resolve recorded',
      };

  Map<String, dynamic> _sessionRoster() => {
        'ok': true,
        'scheduledSessionId': 'SCSS-DEMO-1',
        'status': 'OPEN',
        'closed': false,
        'unanswered': true,
        'sessionDate': '2026-09-11',
        'sessionCredit': 1,
        'total': 3,
        'present': 0,
        'absent': 0,
        'excused': 0,
        'notMarked': 3,
        'rows': [
          {'studentId': 'STU-55DCD622', 'name': 'Aarav Mehta', 'instrument': 'Keyboard', 'state': 'NOT_MARKED'},
          {'studentId': 'STU-77FA91C0', 'name': 'Diya Shah', 'instrument': 'Violin', 'state': 'NOT_MARKED'},
        ],
        'note': 'demo roster',
      };

  Map<String, dynamic> _inquiryTransition(Map<String, dynamic> a) => {
        'ok': true,
        'inquiryId': a['inquiryId'],
        'action': a['action'],
        'after': {'status': a['action'] == 'LOG_CONTACT' ? 'CONTACTED' : a['action'] == 'SCHEDULE_TRIAL' ? 'TRIAL_SCHEDULED' : a['action']},
        'readBack': {'ok': true},
        'auditWritten': true,
        'note': 'demo inquiry moved',
      };

  Map<String, dynamic> _paymentDraftQueue() => {
        'ok': true,
        'count': 3,
        'waitingOnTermsCount': 1,
        'rows': [
          {
            'draftId': 'PDRAFT-DEMO-101',
            'status': 'SUBMITTED',
            'termsStatus': 'TERMS PENDING',
            'studentId': 'STU-55DCD622',
            'studentName': 'Aarav Mehta',
            'phoneMasked': '••••••1123',
            'branch': 'GOREGAON',
            'teacherName': 'Rahul Joshi',
            'instrument': 'Keyboard',
            'amount': '5000',
            'months': 1,
            'currentDueDate': '2026-09-05',
            'projectedNextDueDate': '2026-10-05',
            'paymentDate': '2026-09-11',
            'paymentMode': 'UPI',
            'completeness': {'complete': true, 'missing': []},
            'repairRequired': false,
            'submittedAt': '2026-09-11 10:00:00',
          },
          {
            'draftId': 'PDRAFT-DEMO-FIN-1',
            'status': 'APPROVED',
            'termsStatus': 'TERMS ACCEPTED',
            'studentId': 'STU-77FA91C0',
            'studentName': 'Diya Shah',
            'phoneMasked': '••••••2334',
            'branch': 'GOREGAON',
            'teacherName': 'Meera Nair',
            'instrument': 'Violin',
            'amount': '12000',
            'months': 3,
            'currentDueDate': '2026-09-14',
            'projectedNextDueDate': '2026-12-14',
            'paymentDate': '2026-09-10',
            'paymentMode': 'Kotak UPI',
            'completeness': {'complete': true, 'missing': []},
            'repairRequired': false,
            'approvalAuthority': 'FOUNDER',
            'approvedBy': 'sharvil@demo',
            'submittedAt': '2026-09-10 18:00:00',
          },
          {
            'draftId': 'PDRAFT-DEMO-103',
            'status': 'FINALISE_FAILED_REPAIR_REQUIRED',
            'termsStatus': 'TERMS ACCEPTED',
            'studentId': 'STU-31B84E07',
            'studentName': 'Ishaan Verma',
            'phoneMasked': '••••••3445',
            'branch': 'KANDIVALI',
            'teacherName': 'Vikram Singh',
            'instrument': 'Tabla',
            'amount': '5500',
            'months': 1,
            'currentDueDate': '2026-09-02',
            'projectedNextDueDate': '2026-10-02',
            'paymentDate': '2026-09-09',
            'paymentMode': 'Cash',
            'completeness': {'complete': false, 'missing': ['Monthly Fee']},
            'repairRequired': true,
            'submittedAt': '2026-09-09 09:30:00',
          },
        ],
        'note': 'demo payment draft queue',
      };

  Map<String, dynamic> _approvalsList() => {
        'ok': true,
        'build': 'RC2.57',
        'branch': 'CONSOLIDATED',
        'count': 3,
        'counts': {'total': 3, 'WAITING_ON_TERMS': 1, 'PAYMENT_DRAFT': 2, 'STUDENT_DRAFT': 1, 'SCHOOL_MASTER': 0, 'WAIVER': 1, 'UNKNOWN_STATUS': 0},
        'empty': false,
        'items': _approvalItems(),
        'groups': [
          {'type': 'PAYMENT_DRAFT', 'label': 'Payment drafts', 'items': _approvalItems().where((i) => i['type'] == 'PAYMENT_DRAFT').toList()},
          {'type': 'STUDENT_DRAFT', 'label': 'Student drafts', 'items': _approvalItems().where((i) => i['type'] == 'STUDENT_DRAFT').toList()},
          {'type': 'WAIVER', 'label': 'Late-fee waivers', 'items': _approvalItems().where((i) => i['type'] == 'WAIVER').toList()},
        ],
        'note': 'demo approvals',
      };

  List<Map<String, dynamic>> _approvalItems() => [
        {
          'type': 'PAYMENT_DRAFT',
          'itemId': 'PDRAFT-DEMO-101',
          'entity': 'Aarav Mehta',
          'studentId': 'STU-55DCD622',
          'noStudentLinked': false,
          'paymentMode': 'UPI',
          'feesPeriod': '2026-09-05 → 2026-10-04',
          'amount': '5000',
          'branch': 'GOREGAON',
          'date': '2026-09-10',
          'reason': 'payment approval',
          'flags': {'backdated': false, 'incomplete': false, 'junk': false},
          'termsStatus': 'TERMS PENDING',
          'actions': ['details', 'approve', 'reject'],
        },
        {
          'type': 'PAYMENT_DRAFT',
          'itemId': 'PDRAFT-DEMO-102',
          'entity': 'Ishaan Verma',
          'studentId': 'STU-31B84E07',
          'noStudentLinked': false,
          'paymentMode': 'Cash',
          'feesPeriod': '2026-09-02 → 2026-10-01',
          'amount': '5500',
          'branch': 'KANDIVALI',
          'date': '2026-09-09',
          'reason': 'backdated entry',
          'flags': {'backdated': true, 'incomplete': false, 'junk': false},
          'termsStatus': 'TERMS ACCEPTED',
          'actions': ['details', 'approve', 'reject'],
        },
        {
          'type': 'STUDENT_DRAFT',
          'itemId': 'SD-DEMO-201',
          'entity': 'Rohan Pawar',
          'studentId': 'STU-DEMO-201',
          'noStudentLinked': false,
          'paymentMode': '',
          'feesPeriod': '',
          'amount': '5000',
          'branch': 'KANDIVALI',
          'date': '2026-09-08',
          'reason': 'student edit — merge into master',
          'flags': {'backdated': false, 'incomplete': false, 'junk': false},
          'termsStatus': '',
          'actions': ['details', 'merge', 'reject'],
        },
        {
          'type': 'WAIVER',
          'itemId': 'WVR-DEMO-301',
          'entity': 'Diya Shah',
          'studentId': 'STU-77FA91C0',
          'noStudentLinked': false,
          'paymentMode': '',
          'feesPeriod': '',
          'amount': '500',
          'branch': 'ENT-GOREGAON',
          'date': '2026-09-07',
          'reason': 'late-fee waiver',
          'flags': {'backdated': false, 'incomplete': false, 'junk': false},
          'termsStatus': '',
          'actions': ['details', 'approve', 'reject'],
        },
      ];

  Map<String, dynamic> _commGenerate() => {
        'ok': true,
        'type': 'FEE_REMINDER',
        'subject': 'Fees due — Swar Mangal',
        'body': 'Namaste, reminder that Aarav Mehta\'s fees of ₹5,000 are due on 5 September 2026. '
            'Please pay via the link shared. — Swar Mangal Music Academy',
        'recipientName': 'Parent of Aarav Mehta',
        'recipientType': 'parent',
        'typeRequested': 'FEE_REMINDER',
        'typeResolved': 'FEE_REMINDER',
        'typeCorrected': false,
        'typeNote': '',
        'warnings': [],
        'mode': 'COPY_ONLY',
        'providerSend': 'DISABLED',
        'termsLink': '',
        'termsTokenId': '',
        'termsTokenMinted': false,
        'termsAuditIncomplete': false,
      };

  Map<String, dynamic> _attendanceRoster(Map<String, dynamic> a) {
    final inst = ((a['instrument'] ?? '') as String).trim();
    final all = _studentRows().where((s) => s['status'] == 'ACTIVE').toList();
    final rows = inst.isEmpty ? all : all.where((s) => s['instrument'] == inst).toList();
    return {
      'ok': true,
      'date': a['date'] ?? '2026-09-11',
      'branch': branch,
      'count': rows.length,
      'instruments': ['Keyboard', 'Violin', 'Guitar', 'Tabla'],
      'students': rows
          .map((s) => {
                'studentId': s['studentId'],
                'name': s['studentName'],
                'instrument': s['instrument'],
                'teacherId': 'T-001',
                'teacherName': s['teacher'],
                'phone': s['phone'],
                'expectedToday': true,
              })
          .toList(),
    };
  }

  Map<String, dynamic> _inquiries() => {
        'ok': true,
        'rows': [
          {
            'inquiry_id': 'INQ-501',
            'name': 'Riya Kapoor',
            'phone': '9860011223',
            'instrument': 'Guitar',
            'branch': 'GOREGAON',
            'status': 'NEW',
            'next_contact_date': '2026-09-11',
            'created_at': '2026-09-10',
          },
          {
            'inquiry_id': 'INQ-500',
            'name': 'Aryan Shetty',
            'phone': '9860022334',
            'instrument': 'Keyboard',
            'branch': 'GOREGAON',
            'status': 'FOLLOW_UP',
            'next_contact_date': '2026-09-12',
            'created_at': '2026-09-09',
          },
          {
            'inquiry_id': 'INQ-498',
            'name': 'Sana Iyer',
            'phone': '9860033445',
            'instrument': 'Violin',
            'branch': 'KANDIVALI',
            'status': 'DROPPED',
            'next_contact_date': '',
            'created_at': '2026-09-06',
          },
        ],
      };

  Map<String, dynamic> _staffStudentHub(Map<String, dynamic> a) {
    final sid = _s(a['studentId'] ?? '');
    final all = _studentRows();
    final s = sid.isEmpty ? all.first : (all.where((r) => r['studentId'] == sid).isNotEmpty ? all.firstWhere((r) => r['studentId'] == sid) : all.first);
    return {
      'ok': true,
      'profile': {
        ...s,
        'parentName': 'Parent of ${s['studentName']}',
        'fee': '${s['lastReceiptAmount'] ?? 5000}',
        'dueDate': s['nextDueDate'],
      },
      'fees': {'available': true, 'total': 15400, 'capped': false, 'rows': []},
      'pending': {
        'available': true,
        'rows': [
          {
            'draftId': 'PDRAFT-DEMO-FIN-1',
            'amount': '${s['lastReceiptAmount'] ?? 5000}',
            'paymentDate': '2026-09-10',
            'approvalAuthority': 'FOUNDER',
            'approvedBy': 'sharvil@demo',
            'founderDecision': true,
            'label': 'Approved by sharvil@demo',
            'repairRequired': false,
            'status': 'APPROVED',
            'canFinalise': true,
            'blockedReason': '',
          },
        ],
      },
      'terms': {'found': false, 'link': '', 'status': '', 'label': 'No terms link yet', 'note': ''},
      'note': 'demo hub',
    };
  }

  String _s(dynamic v) => v == null ? '' : v.toString();

  Map<String, dynamic> _teacherProfile(Map<String, dynamic> a) {
    final tid = _s(a['teacherId'] ?? 'T-001');
    final allT = (_teachers()['teachers'] as List).cast<Map<String, dynamic>>();
    Map<String, dynamic> t = allT.first;
    for (final x in allT) {
      if (x['teacherId'] == tid) {
        t = x;
        break;
      }
    }
    final students = _studentRows()
        .where((s) => s['teacher'] == t['teacherName'])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (students.isEmpty) {
      students
        ..add(Map<String, dynamic>.from(_studentRows()[0]))
        ..add(Map<String, dynamic>.from(_studentRows()[1]));
    }
    return {
      'ok': true,
      'teacher': {
        ...t,
        'teacherId': t['teacherId'],
        'teacherName': t['teacherName'],
        'primaryRole': t['primaryRole'],
        'academyShare': t['academyShare'] ?? '40',
        'compensationPercent': t['academyShare'] ?? '40',
        'compensationEffectiveFrom': '2026-07-01',
      },
      'students': students,
      'receiptCountThisMonth': 4,
    };
  }

  Map<String, dynamic> _studentProfileDetail(Map<String, dynamic> a) {
    final sid = _s(a['studentId'] ?? '');
    final rows = _studentRows();
    final s = sid.isEmpty
        ? rows.first
        : rows.where((r) => r['studentId'] == sid).isNotEmpty
            ? rows.firstWhere((r) => r['studentId'] == sid)
            : rows.first;
    return {
      'ok': true,
      'student': {
        ...s,
        'teacherId': 'T-001',
        'teacherName': s['teacher'],
        'branch': s['location'],
      },
      'teacher': {'teacherId': 'T-001', 'teacherName': s['teacher']},
      'receipts': _receiptRows().take(3).toList(),
      'attendance': [],
    };
  }

  Map<String, dynamic> _todaysTasks() =>
      {'ok': true, 'cards': _taskCards(), 'mode': 'COPY_ONLY', 'today': '2026-09-11'};

  Map<String, dynamic> _payoutPreview(Map<String, dynamic> a) => {
        'ok': true,
        'results': [
          {
            'teacherId': 'T-001',
            'teacherName': 'Rahul Joshi',
            'academyShare': '40',

            'month': a['month'] ?? '2026-09',
            'entityId': 'ENT-GOREGAON',
            'receiptCount': 4,
            'totalCollection': 22000,
            'totalTeacherShare': 11000,
            'payable': 11000,
            'alreadyPaid': 5000,
            'balance': 6000,
            'status': 'PARTIAL',
            'preCutover': false,
            'note': '',
          },
          {
            'teacherId': 'T-002',
            'teacherName': 'Meera Nair',
            'academyShare': '45',

            'month': a['month'] ?? '2026-09',
            'entityId': 'ENT-GOREGAON',
            'receiptCount': 3,
            'totalCollection': 15000,
            'totalTeacherShare': 7500,
            'payable': 7500,
            'alreadyPaid': 0,
            'balance': 7500,
            'status': 'UNPAID',
            'preCutover': false,
            'note': '',
          },
          {
            'teacherId': 'T-003',
            'teacherName': 'Vikram Singh',
            'academyShare': '50',

            'month': '2026-08',
            'entityId': 'ENT-KANDIVALI',
            'receiptCount': 5,
            'totalCollection': 32000,
            'totalTeacherShare': 16000,
            'payable': 16000,
            'alreadyPaid': 16000,
            'balance': 0,
            'status': 'PAID',
            'preCutover': true,
            'note': 'Pre-cutover manual settlement — balance forced to zero.',
          },
        ],
        'byEntity': {
          'ENT-GOREGAON': {'payable': 18500, 'paid': 5000, 'balance': 13500},
          'ENT-KANDIVALI': {'payable': 16000, 'paid': 16000, 'balance': 0},
        },
        'note': 'demo payout preview',
      };

  Map<String, dynamic> _staffMyRequests() => {
        'ok': true,
        'branch': 'GOREGAON',
        'count': 3,
        'rows': [
          {
            'type': 'PAYMENT_DRAFT',
            'id': 'PDRAFT-101',
            'status': 'SUBMITTED',
            'student': 'STU-55DCD622',
            'category': '',
            'amount': '5000',
            'when': '2026-09-11 10:00:00',
            'backdated': false,
          },
          {
            'type': 'EXPENSE_DRAFT',
            'id': 'EDRAFT-201',
            'status': 'SUBMITTED',
            'student': '',
            'category': 'Rent',
            'amount': '15000',
            'when': '2026-09-10 14:00:00',
            'backdated': false,
          },
          {
            'type': 'PAYMENT_DRAFT',
            'id': 'PDRAFT-103',
            'status': 'BACKDATED_APPROVAL_REQUIRED',
            'student': 'STU-31B84E07',
            'category': '',
            'amount': '5500',
            'when': '2026-09-09 09:30:00',
            'backdated': true,
          },
        ],
        'canApprove': false,
        'note': 'demo my requests',
      };
}