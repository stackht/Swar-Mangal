import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';

/// Per-teacher class attendance over a date range (default: this month) —
/// the dashboard's "Teacher attendance" card only ever shows today; this is
/// the same read-only computation (api_teacherAttendanceReport), open to
/// both founder and staff.
class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});
  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  TeacherAttendanceSummary? _summary;
  bool _busy = true;
  String? _error;
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = now;
    _load();
  }

  String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await auth.service!.teacherAttendanceReport({'from': _iso(_from), 'to': _iso(_to)});
      final m = r as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _summary = TeacherAttendanceSummary.fromApi(m);
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

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked == null) return;
    setState(() {
      _from = picked.start;
      _to = picked.end;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshScaffold(
      onRefresh: _load,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Row(children: [
            Expanded(
              child: Text('${_iso(_from)} → ${_iso(_to)}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            OutlinedButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range_outlined, size: 18),
              label: const Text('Range'),
            ),
          ]),
        ),
        Expanded(
          child: _busy && _summary == null
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _summary == null
                  ? ErrorView(_error!, onRetry: _load)
                  : (_summary?.teachers.isEmpty ?? true)
                      ? const EmptyState('No classes scheduled in this range.', icon: Icons.groups_outlined)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s2),
                          itemCount: _summary!.teachers.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (c, i) => _row(_summary!.teachers[i]),
                        ),
        ),
      ]),
    );
  }

  Widget _row(TeacherAttendanceRow t) {
    Widget stat(String label, int value, Color color) => Expanded(
          child: Column(children: [
            Text('$value', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.teacherName.isNotEmpty ? t.teacherName : t.teacherId, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: AppSpace.s2),
        Row(children: [
          stat('Scheduled', t.scheduled, AppColors.focus),
          stat('Held', t.held, AppColors.okFg),
          stat('Cancelled', t.cancelled, AppColors.blockFg),
          stat('Substitute', t.substituted, AppColors.warnFg),
          stat('Unanswered', t.unanswered, AppColors.warnFg),
        ]),
      ]),
    );
  }
}
