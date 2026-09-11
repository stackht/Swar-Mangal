import 'package:flutter_test/flutter_test.dart';
import 'package:swar_mangal/models/models.dart';
import 'package:swar_mangal/services/demo_api.dart';

Map<String, dynamic> _map(dynamic v) => v as Map<String, dynamic>;

void main() {
  group('TeacherProfile.fromApi parses demo fixture', () {
    late DemoApiClient d;
    setUp(() => d = DemoApiClient());
    test('profile carries students + academyShare', () async {
      final b = _map(await d.call('api_teacherProfile', {'teacherId': 'T-001'}));
      final p = TeacherProfile.fromApi(b);
      expect(p.teacher.teacherId, isNotEmpty);
      expect(p.hasStudents, true);
      expect(p.sharePercent, isNotEmpty);
    });

    test('profile with zero students shows empty state', () {
      final p = TeacherProfile.fromApi({
        'teacher': {'teacherId': 'T-99', 'teacherName': 'Z', 'status': 'ACTIVE'},
        'students': [],
      });
      expect(p.hasStudents, false);
    });
  });

  group('StudentProfileDetail.fromApi', () {
    test('carries teacherId + teacherName when backend provides both', () {
      final d = StudentProfileDetail.fromApi({
        'student': {'studentId': 'S1', 'studentName': 'A', 'teacherId': 'T-1'},
        'teacher': {'teacherId': 'T-1', 'teacherName': 'Rahul'},
      });
      expect(d.hasTeacherId, true);
      expect(d.hasTeacherName, true);
    });

    test('no teacher when backend omits teacher id + name', () {
      final d = StudentProfileDetail.fromApi({
        'student': {'studentId': 'S2', 'studentName': 'X'},
        'teacher': null,
      });
      expect(d.noTeacherAssigned, true);
      expect(d.hasTeacherId, false);
    });
  });

  group('TeacherCompensationValidator', () {
    test('0% is valid', () {
      final v = TeacherCompensationValidator.validate('0');
      expect(v.ok, true);
      expect(v.value, 0);
    });
    test('100% is valid', () {
      final v = TeacherCompensationValidator.validate('100');
      expect(v.ok, true);
      expect(v.value, 100);
    });
    test('negative rejected', () {
      final v = TeacherCompensationValidator.validate('-5');
      expect(v.ok, false);
      expect(v.error, contains('0'));
    });
    test('>100 rejected', () {
      final v = TeacherCompensationValidator.validate('105');
      expect(v.ok, false);
      expect(v.error, contains('100'));
    });
    test('non-numeric rejected', () {
      final v = TeacherCompensationValidator.validate('abc');
      expect(v.ok, false);
      expect(v.error, isNotNull);
    });
    test('floating point like 40.5 accepted', () {
      final v = TeacherCompensationValidator.validate('40.5');
      expect(v.ok, true);
      expect(v.value, 40.5);
    });
  });

  group('ProfilePolicy', () {
    test('staff cannot edit compensation', () {
      expect(ProfilePolicy.canEditCompensation(staff: true), false);
    });
    test('founder can edit compensation', () {
      expect(ProfilePolicy.canEditCompensation(staff: false), true);
    });
  });

  group('Demo compensation update', () {
    test('is stamped demo + not persisted', () async {
      final r = _map(await DemoApiClient().call('api_updateTeacherCompensation', {
        'teacherId': 'T-001',
        'percentage': 45,
        'effectiveFrom': '2026-10-01',
        'reason': 'performance',
        'clientIntentKey': 'k1',
      }));
      expect(r['ok'], true);
      expect(r['demo'], true);
      expect((r['demoNote'] ?? '').toString(), contains('Not persisted'));
    });
  });

  group('Model parsing — Teacher from list', () {
    test('teacher parses academyShare', () {
      final t = Teacher.fromApi({
        'teacherId': 'T1',
        'teacherName': 'R',
        'status': 'ACTIVE',
        'academyShare': '40',
      });
      expect(t.shareLabel, '40%');
    });
    test('teacher with no share shows empty label', () {
      final t = Teacher.fromApi({'teacherId': 'T1', 'teacherName': 'R'});
      expect(t.shareLabel, isEmpty);
    });
  });

  group('Student search + studentDetail', () {
    late DemoApiClient d;
    setUp(() => d = DemoApiClient());
    test('api_searchStudent results are parseable as Student', () async {
      final b = _map(await d.call('api_searchStudent', {'q': ''}));
      final rows = (b['results'] as List).cast<Map<String, dynamic>>();
      final s = Student.fromApi(rows.first);
      expect(s.studentName, isNotEmpty);
    });
    test('api_studentProfile returns student + teacher', () async {
      final b = _map(await d.call('api_studentProfile', {}));
      final p = StudentProfileDetail.fromApi(b);
      expect(p.student.studentId, isNotEmpty);
      expect(p.hasTeacherName, true);
    });
  });
}