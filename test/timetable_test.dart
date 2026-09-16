import 'package:flutter_test/flutter_test.dart';
import 'package:swar_mangal/data/kandivali_timetable_seed.dart';
import 'package:swar_mangal/models/models.dart';
import 'package:swar_mangal/services/demo_api.dart';

void main() {
  setUp(DemoApiClient.resetSharedState);

  group('Seed — exact Kandivali timetable', () {
    test('total entries across the week', () {
      expect(kandivaliTimetableSeed.length, 25);
    });
    test('per-day counts', () {
      int count(int day) => kandivaliTimetableSeed.where((e) => e.dayOfWeek == day).length;
      expect(count(0), 4); // Mon
      expect(count(1), 3); // Tue
      expect(count(2), 4); // Wed
      expect(count(3), 1); // Thu
      expect(count(4), 3); // Fri
      expect(count(5), 6); // Sat
      expect(count(6), 4); // Sun
    });
    test('specific moments exist', () {
      expect(kandivaliTimetableSeed.any((e) => e.dayOfWeek == 0 && e.startTime == '18:00' && e.className == 'Keyboard' && e.teacherName == 'Rahul Sir'), true);
      expect(kandivaliTimetableSeed.any((e) => e.dayOfWeek == 5 && e.startTime == '09:00' && e.className == 'Tabla' && e.teacherName == 'Piyush Sir'), true);
      expect(kandivaliTimetableSeed.any((e) => e.dayOfWeek == 6 && e.startTime == '16:00' && e.className == 'Mandip Tabla'), true);
    });
    test('all entries are Kandivali + enabled', () {
      expect(kandivaliTimetableSeed.every((e) => e.branch == 'KANDIVALI'), true);
      expect(kandivaliTimetableSeed.every((e) => e.enabled), true);
    });
  });

  group('DemoApiClient timetable — seed once + editable', () {
    late DemoApiClient d;
    setUp(() {
      d = DemoApiClient();
    });

    Future<List<TimetableEntry>> list() async {
      final b = await d.call('api_timetableList', {'branch': 'KANDIVALI'});
      return ((b as Map)['entries'] as List)
          .whereType<Map<String, dynamic>>()
          .map(TimetableEntry.fromApi)
          .toList();
    }

    test('first list returns full seed', () async {
      final rows = await list();
      expect(rows.length, 25);
    });

    test('day filtering', () async {
      final rows = await list();
      final monday = rows.where((e) => e.dayOfWeek == 0).toList();
      expect(monday.length, 4);
      expect(monday.every((e) => e.dayLabel == 'MON'), true);
    });

    test('add entry persists for the session', () async {
      await d.call('api_timetableCreate', {
        'branch': 'KANDIVALI', 'dayOfWeek': 3, 'startTime': '20:00', 'endTime': '21:00',
        'className': 'Keyboard (Advance)', 'teacherId': 'T-001', 'teacherName': 'Rahul Joshi',
      });
      final rows = await list();
      expect(rows.any((e) => e.className == 'Keyboard (Advance)'), true);
    });

    test('edit entry persists (seed does NOT overwrite the edit)', () async {
      final first = (await list()).first;
      await d.call('api_timetableUpdate', {'id': first.id, 'startTime': '18:30'});
      final after = await list();
      expect(after.first.startTime, '18:30');
    });

    test('delete entry removes row', () async {
      final first = (await list()).first;
      await d.call('api_timetableDelete', {'id': first.id});
      final after = await list();
      expect(after.any((e) => e.id == first.id), false);
      expect(after.length, 24);
    });

    test('teacher id is preserved', () async {
      await d.call('api_timetableCreate', {
        'branch': 'KANDIVALI', 'dayOfWeek': 1, 'startTime': '19:00', 'endTime': '20:00',
        'className': 'Keyboard', 'teacherId': 'T-002', 'teacherName': 'Meera Nair',
      });
      final rows = await list();
      final inserted = rows.lastWhere((e) => e.className == 'Keyboard' && e.startTime == '19:00');
      expect(inserted.teacherId, 'T-002');
      expect(inserted.teacherName, 'Meera Nair');
    });

    test('branch isolation — list with unrelated branch returns empty', () async {
      final b = await d.call('api_timetableList', {'branch': 'GOREGAON'});
      expect(((b as Map)['entries'] as List), isEmpty);
    });

    test('create/update/delete writes are demo-stamped', () async {
      final r = await d.call('api_timetableCreate', {'branch': 'KANDIVALI', 'dayOfWeek': 0, 'startTime': '08:00', 'endTime': '09:00', 'className': 'X'});
      expect((r as Map)['demo'], true);
    });
  });

  group('TimetableValidator', () {
    test('time format + ordering', () {
      expect(TimetableValidator.time('25:00'), isNotNull);
      expect(TimetableValidator.time('12:00'), isNull);
      expect(TimetableValidator.range('18:00', '17:00').ok, false);
      expect(TimetableValidator.range('17:00', '18:00').ok, true);
    });
    test('class required', () {
      expect(TimetableValidator.className('   '), isNotNull);
    });
  });

  group('TimetablePolicy', () {
    test('staff and founder both edit', () {
      expect(TimetablePolicy.canEdit(staff: false), true);
      expect(TimetablePolicy.canEdit(staff: true), true);
    });
  });
}