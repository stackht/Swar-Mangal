import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../../widgets/anim.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final current = widget.navItems.firstWhere(
        (n) => n.key == _current, orElse: () => widget.navItems.first);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Expanded(child: Text(current.label)),
          if (auth.isDemo)
            Container(
              margin: const EdgeInsets.only(right: AppSpace.s2),
              padding: const EdgeInsets.symmetric(horizontal: AppRadius.s, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text('DEMO',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF261A08)
                          : Colors.white)),
            ),
          if (widget.branchChip != null) ...[
            const SizedBox(width: AppSpace.s2),
            widget.branchChip!,
          ],
        ]),
        actions: [
          if (widget.headerTrailing != null) widget.headerTrailing!,
          Consumer<ThemeController>(
            builder: (context, theme, _) => IconButton(
              tooltip: theme.isDark ? 'Light mode' : 'Dark mode',
              icon: Icon(theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              onPressed: theme.toggle,
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      drawer: _drawer(context, auth),
      body: ViewSwitch(
        child: ShellNavigator(
          go: _go,
          child: KeyedSubtree(
            key: ValueKey<String>(_current),
            child: widget.buildBody(context, _current),
          ),
        ),
      ),
    );
  }

  Widget _drawer(BuildContext context, AuthProvider auth) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return NavigationDrawer(
      backgroundColor: dark ? AppColors.dSurfaceAlt : AppColors.surface,
      indicatorColor: AppColors.primary,
      onDestinationSelected: (i) { _go(widget.navItems[i].key); },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.s4, AppSpace.s5, AppSpace.s4, AppSpace.s2),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.music_note, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title,
                    style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                Text('AcademyOS', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.s3),
          child: Divider(color: scheme.outlineVariant, thickness: 1),
        ),
        const SizedBox(height: AppSpace.s2),
        for (final item in widget.navItems)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: 2),
            child: ListTile(
              selected: _current == item.key,
              selectedTileColor: scheme.primary.withValues(alpha: dark ? .16 : .12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
              leading: Icon(item.icon, size: 20,
                  color: _current == item.key ? AppColors.primary : scheme.onSurfaceVariant),
              title: Text(item.label,
                  style: TextStyle(
                      color: _current == item.key ? scheme.onSurface : scheme.onSurfaceVariant,
                      fontWeight: _current == item.key ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 14)),
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
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
              ),
            ),
            IconButton(
              icon: Icon(Icons.info_outline, color: scheme.onSurfaceVariant, size: 20),
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