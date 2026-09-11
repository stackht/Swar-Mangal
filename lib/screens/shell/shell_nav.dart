import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';

/// Inherited handle letting a body screen switch the shell's current view.
class ShellNavigator extends InheritedWidget {
  const ShellNavigator({super.key, required this.go, required super.child});
  final void Function(String key) go;

  static ShellNavigator of(BuildContext context) {
    final n = context.dependOnInheritedWidgetOfExactType<ShellNavigator>();
    assert(n != null, 'ShellNavigator missing — screens must live inside DrawerShell');
    return n!;
  }

  @override
  bool updateShouldNotify(ShellNavigator oldWidget) => go != oldWidget.go;
}

/// Drawer-driven shell reused by both apps. Each nav item maps to a body
/// widget built lazily on selection.
class DrawerShell extends StatefulWidget {
  const DrawerShell({
    super.key,
    required this.title,
    required this.navItems,
    required this.buildBody,
    this.headerTrailing,
    this.branchChip,
  });

  final String title;
  final List<({String key, String label, IconData icon})> navItems;
  final Widget Function(BuildContext, String key) buildBody;
  final Widget? headerTrailing;
  final Widget? branchChip;

  @override
  State<DrawerShell> createState() => _DrawerShellState();
}

class _DrawerShellState extends State<DrawerShell> {
  String _current = '';

  @override
  void initState() {
    super.initState();
    _current = widget.navItems.first.key;
  }

  void _go(String key) {
    setState(() => _current = key);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final current = widget.navItems.firstWhere(
        (n) => n.key == _current, orElse: () => widget.navItems.first);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Expanded(child: Text(current.label)),
          if (auth.isDemo)
            Container(
              margin: const EdgeInsets.only(right: AppSpace.s2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('DEMO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          if (widget.branchChip != null) ...[
            const SizedBox(width: AppSpace.s2),
            widget.branchChip!,
          ],
        ]),
        actions: [
          if (widget.headerTrailing != null) widget.headerTrailing!,
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      drawer: _drawer(context, auth),
      body: ShellNavigator(
        go: _go,
        child: widget.buildBody(context, _current),
      ),
    );
  }

  Widget _drawer(BuildContext context, AuthProvider auth) {
    return NavigationDrawer(
      backgroundColor: AppColors.primaryDark,
      indicatorColor: Colors.white24,
      onDestinationSelected: (i) { _go(widget.navItems[i].key); },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.s4, AppSpace.s5, AppSpace.s4, AppSpace.s2),
          child: Row(children: [
            const Icon(Icons.music_note, color: Colors.white, size: 28),
            const SizedBox(width: AppSpace.s2),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SwarMangal AcademyOS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                Text(widget.title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.only(top: AppSpace.s3),
          child: Divider(color: Colors.white12, thickness: 1),
        ),
        const SizedBox(height: AppSpace.s2),
        for (final item in widget.navItems)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: 2),
            child: ListTile(
              selected: _current == item.key,
              selectedTileColor: Colors.white24,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              leading: Icon(item.icon, color: Colors.white, size: 20),
              title: Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
              dense: true,
              minTileHeight: 44,
              onTap: () => _go(item.key),
            ),
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Row(children: [
            Expanded(
              child: Text(
                '${auth.operator?.role ?? ''}\n${auth.operator?.email ?? ''}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white70, size: 20),
              onPressed: () => Navigator.pop(context),
              tooltip: 'About',
            ),
          ]),
        ),
      ],
    );
  }
}

/// Top-level choices offered to founder and staff, rendered by each shell.
const founderItems = <({String key, String label, IconData icon})>[
  (key: 'home', label: 'Home', icon: Icons.home_outlined),
  (key: 'approvals', label: 'Approvals', icon: Icons.fact_check_outlined),
  (key: 'students', label: 'Students', icon: Icons.person_search_outlined),
  (key: 'addStudent', label: 'Add Student', icon: Icons.person_add_alt_1_outlined),
  (key: 'addFee', label: 'Add Fee', icon: Icons.payments_outlined),
  (key: 'receipts', label: 'Receipts', icon: Icons.receipt_long_outlined),
  (key: 'teachers', label: 'Teachers', icon: Icons.group_outlined),
  (key: 'expenses', label: 'Expenses & Cashbook', icon: Icons.account_balance_wallet_outlined),
  (key: 'payouts', label: 'Teacher Payouts', icon: Icons.payments_outlined),
  (key: 'about', label: 'About', icon: Icons.info_outline),
];

const staffItems = <({String key, String label, IconData icon})>[
  (key: 'today', label: 'Today', icon: Icons.today_outlined),
  (key: 'todayClasses', label: 'Today\'s Classes', icon: Icons.schedule_outlined),
  (key: 'students', label: 'Students', icon: Icons.people_outline),
  (key: 'addStudent', label: 'Add Student (Draft)', icon: Icons.person_add_alt_1_outlined),
  (key: 'attendance', label: 'Attendance', icon: Icons.fact_check_outlined),
  (key: 'addFee', label: 'Add Fee', icon: Icons.payments_outlined),
  (key: 'receipts', label: 'Receipts', icon: Icons.receipt_long_outlined),
  (key: 'expenses', label: 'Expenses', icon: Icons.account_balance_wallet_outlined),
  (key: 'inquiries', label: 'Inquiries', icon: Icons.chat_outlined),
  (key: 'requests', label: 'My Requests', icon: Icons.outbox_outlined),
  (key: 'about', label: 'About', icon: Icons.info_outline),
];

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, required this.staff});
  final bool staff;
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return ListView(
      padding: const EdgeInsets.all(AppSpace.s4),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpace.s4),
            child: Row(children: [
              Icon(Icons.music_note, size: 36, color: AppColors.primary),
              SizedBox(width: AppSpace.s3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SwarMangal AcademyOS', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text('Music Academy ERP · v1.0.0', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                ]),
              ),
            ]),
          ),
        ),
        const SectionTitle('Session'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Column(children: [
              InfoRow('App', staff ? 'Staff' : 'Founder'),
              InfoRow('Role', auth.operator?.role ?? ''),
              InfoRow('Operator', auth.operator?.email ?? ''),
              InfoRow('Branch', auth.branch ?? '—'),
            ]),
          ),
        ),
        SectionTitle('Backend'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Column(children: [
              InfoRow('Scope', 'Device-token gateway on Apps Script'),
              InfoRow('Money path', 'Server-authoritative · lock · counter · audit'),
            ]),
          ),
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpace.s4),
            child: Text(
              'All business rules (receipt numbering, late fees, terms gates, '
              'idempotency) run on the server. This app never computes money '
              'values on-device.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        ),
      ],
    );
  }
}