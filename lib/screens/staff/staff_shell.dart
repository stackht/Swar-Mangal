import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../shell/shell_nav.dart';
import 'screens/staff_dashboard.dart';
import '../shared/add_student_screen.dart';
import '../shared/attendance_screen.dart';
import '../shared/expenses_screen.dart';
import '../shared/fee_collection_screen.dart';
import '../shared/inquiries_screen.dart';
import '../shared/receipts_screen.dart';
import '../shared/students_screen.dart';
import '../shared/todays_classes_screen.dart';

/// Staff surface. Branch-gated: every read/write is isolated to the branch
/// picked by the operator at the door (server-enforced, same rule as web).
class StaffShell extends StatelessWidget {
  const StaffShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.branch == null) return const BranchGate();
    return DrawerShell(
      title: 'Staff App',
      navItems: staffItems,
      branchChip: _BranchChip(auth.branch!),
      buildBody: (context, key) {
        switch (key) {
          case 'todayClasses':
            return const TodaysClassesScreen();
          case 'students':
            return const StudentsScreen(staff: true);
          case 'addStudent':
            return const AddStudentScreen(staff: true);
          case 'attendance':
            return const AttendanceScreen();
          case 'addFee':
            return const FeeCollectionScreen(staff: true);
          case 'receipts':
            return const ReceiptsScreen(staff: true);
          case 'expenses':
            return const ExpensesScreen(staff: true);
          case 'inquiries':
            return const InquiriesScreen();
          case 'about':
            return const AboutScreen(staff: true);
          case 'today':
          default:
            return const StaffDashboard();
        }
      },
    );
  }
}

class _BranchChip extends StatelessWidget {
  const _BranchChip(this.branch);
  final String branch;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(branch,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

/// Door every staff session must pass before any data loads — matches the
/// web app's branch gate.
class BranchGate extends StatelessWidget {
  const BranchGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final branches = auth.branches.isEmpty ? const ['GOREGAON', 'KANDIVALI'] : auth.branches;
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => auth.logout(),
            child: const Text('Sign out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Choose your branch',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpace.s2),
                const Text('All data is isolated to this branch. You can switch later from the drawer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: AppSpace.s6),
                for (final b in branches) ...[
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () => auth.setBranch(b),
                    child: Text(b.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                  const SizedBox(height: AppSpace.s3),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}