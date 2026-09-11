import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';

/// Staff attendance: filter-first roster, three markable states.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class AttendanceRosterRow {
  AttendanceRosterRow({
    required this.studentId,
    required this.name,
    required this.instrument,
    required this.teacherName,
    required this.phone,
  });
  factory AttendanceRosterRow.fromApi(Map<String, dynamic> b) =>
      AttendanceRosterRow(
        studentId: _sv(b['studentId']),
        name: _sv(b['name']),
        instrument: _sv(b['instrument']),
        teacherName: _sv(b['teacherName']),
        phone: _sv(b['phone']),
      );
  final String studentId;
  final String name;
  final String instrument;
  final String teacherName;
  final String phone;
}

String _sv(dynamic v) => v == null ? '' : v.toString();

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<AttendanceRosterRow> _roster = [];
  List<String> _instruments = [];
  String? _instrument;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await auth.service!.staffAttendanceRoster({
        'branch': auth.branch ?? '',
        'instrument': _instrument ?? '',
        'date': _today(),
      });
      final m = r as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _roster = (m['students'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AttendanceRosterRow.fromApi)
            .toList();
        _instruments = (m['instruments'] as List? ?? []).map((e) => e.toString()).toList();
        _busy = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _mark(AttendanceRosterRow s, String state) async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    try {
      await auth.service!.staffMarkAttendance({
        'branch': auth.branch ?? '',
        'studentId': s.studentId,
        'state': state,
        'workDate': _today(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${s.name} → $state')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy && _roster.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _roster.isEmpty) return ErrorView(_error!, onRetry: _load);
    return RefreshScaffold(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.s4),
        children: [
          Text('ATTENDANCE · ${_today()}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .5, color: AppColors.muted)),
          const SizedBox(height: AppSpace.s3),
          if (_instruments.isNotEmpty) ...[
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _instrument == null,
                  onSelected: (_) {
                    setState(() => _instrument = null);
                    _load();
                  },
                ),
                for (final inst in _instruments)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpace.s2),
                    child: ChoiceChip(
                      label: Text(inst),
                      selected: _instrument == inst,
                      onSelected: (_) {
                        setState(() => _instrument = inst);
                        _load();
                      },
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: AppSpace.s3),
          ],
          if (_roster.isEmpty)
            EmptyState('No students in ${_instrument ?? 'this branch'} for this instrument.')
          else
            for (final s in _roster)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpace.s3),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s3),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: .08),
                      child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
                    ),
                    const SizedBox(width: AppSpace.s3),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(
                            [s.instrument, s.teacherName, s.phone].where((e) => e.isNotEmpty).join(' · '),
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ]),
                    ),
                    _markButtons(s),
                  ]),
                ),
              ),
        ],
      ),
    );
  }

  Widget _markButtons(AttendanceRosterRow s) {
    return Column(children: [
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.okFg,
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
        ),
        onPressed: () => _mark(s, 'PRESENT'),
        child: const Text('PRESENT', style: TextStyle(fontSize: 11)),
      ),
      const SizedBox(height: 4),
      TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 30),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
          foregroundColor: AppColors.muted,
        ),
        onPressed: () => _mark(s, 'ABSENT'),
        child: const Text('ABSENT', style: TextStyle(fontSize: 11)),
      ),
    ]);
  }
}