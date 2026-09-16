import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:swar_mangal/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('StartupGate lands on LoginScreen when no stored session', (tester) async {
    await tester.pumpWidget(const AcademyApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Login screen should show 'Welcome' and 'Swar Mangal' text.
    expect(find.textContaining('Welcome'), findsWidgets);
    expect(find.textContaining('Swar Mangal'), findsWidgets);
  });
}