import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:maestro_app/main.dart';
import 'package:maestro_app/models.dart';
import 'package:maestro_app/student_screens.dart';
import 'package:maestro_app/staff_screens.dart';

void main() {
  testWidgets('login renders and role entry opens the shell', (tester) async {
    await tester.pumpWidget(const SwarMangalApp());

    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('EXPLORE AS'), findsOneWidget);

    await tester.tap(find.text('Student'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Aarav'), findsWidgets);
  });

  testWidgets('practice screen renders timer and weekly chart', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: PracticeScreen()));
    expect(find.text('START A SESSION'), findsOneWidget);
    expect(find.textContaining('00:00'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
  });

  testWidgets('schedule groups lessons by day', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ScheduleScreen(lessons: myLessons('s1'))));
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.textContaining('Piano'), findsWidgets);
  });

  testWidgets('teacher home shows today classes and students', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TeacherHome()));
    expect(find.textContaining('classes today'), findsWidgets);
    expect(find.textContaining('Sarah'), findsOneWidget);
  });

  testWidgets('admin home renders academy stats', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AdminHome()));
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Revenue'), findsOneWidget);
  });

  test('data sanity', () {
    expect(myLessons('s1').length, greaterThan(0));
    expect(practiceMinutes(), greaterThan(0));
    expect(skills.length, 7);
  });
}