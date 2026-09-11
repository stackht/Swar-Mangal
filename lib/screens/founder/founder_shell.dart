import 'package:flutter/material.dart';

import '../shell/shell_nav.dart';
import '../shared/approvals_screen.dart';
import '../shared/dashboard_screen.dart';
import '../shared/add_student_screen.dart';
import '../shared/expenses_screen.dart';
import '../shared/fee_collection_screen.dart';
import '../shared/receipts_screen.dart';
import '../shared/students_screen.dart';
import '../shared/teachers_screen.dart';
import '../shared/payout_preview_screen.dart';

/// Founder surface. Same data centre as the web founder app: receipts are
/// entered directly against STUDENT_RECEIPTS (server-authoritative).
class FounderShell extends StatelessWidget {
  const FounderShell({super.key});

  @override
  Widget build(BuildContext context) {
    return DrawerShell(
      title: 'Founder App',
      navItems: founderItems,
      buildBody: (context, key) {
        switch (key) {
          case 'approvals':
            return const ApprovalsScreen();
          case 'students':
            return const StudentsScreen(staff: false);
          case 'addStudent':
            return const AddStudentScreen(staff: false);
          case 'addFee':
            return const FeeCollectionScreen(staff: false);
          case 'receipts':
            return const ReceiptsScreen(staff: false);
          case 'teachers':
            return const TeachersScreen(staff: false);
          case 'expenses':
            return const ExpensesScreen(staff: false);
          case 'payouts':
            return const PayoutPreviewScreen();
          case 'about':
            return const AboutScreen(staff: false);
          case 'home':
          default:
            return const FounderDashboard();
        }
      },
    );
  }
}