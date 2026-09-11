import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/founder/founder_shell.dart';
import 'screens/staff/staff_shell.dart';
import 'state/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AcademyApp());
}

class AcademyApp extends StatelessWidget {
  const AcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'SwarMangal AcademyOS',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const Gate(),
      ),
    );
  }
}

/// Routes between the login screen and the two app surfaces based on which
/// role the backend reported at login.
class Gate extends StatelessWidget {
  const Gate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const LoginScreen();
    if (auth.isFounder) return const FounderShell();
    return const StaffShell();
  }
}