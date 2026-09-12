import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/founder/founder_shell.dart';
import 'screens/staff/staff_shell.dart';
import 'state/auth_provider.dart';
import 'state/sync_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final mode = await ThemeController.restore();
  runApp(AcademyApp(initialTheme: mode));
}

class AcademyApp extends StatelessWidget {
  const AcademyApp({super.key, this.initialTheme = ThemeMode.light});
  final ThemeMode initialTheme;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeController(initialTheme)),
        ChangeNotifierProvider(create: (_) => SyncManager()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Swar Mangal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.mode,
          home: const SyncBinder(child: Gate()),
        ),
      ),
    );
  }
}

/// Owns SyncManager lifecycle: starts once, attaches the API service on
/// login, detaches on logout, and syncs whenever the branch changes.
class SyncBinder extends StatefulWidget {
  const SyncBinder({super.key, required this.child});
  final Widget child;
  @override
  State<SyncBinder> createState() => _SyncBinderState();
}

class _SyncBinderState extends State<SyncBinder> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sync = context.watch<SyncManager>();
    if (!_started) {
      _started = true;
      sync.start(context, onBranchChange: sync.setBranch);
    }
    if (auth.isLoggedIn) {
      sync.attach(auth.service);
      if (auth.branch != null) sync.setBranch(auth.branch!);
    } else {
      sync.attach(null);
    }
    return SyncScope(manager: sync, child: widget.child);
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