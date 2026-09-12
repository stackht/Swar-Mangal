import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/sync_manager.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/anim.dart';
import '../../widgets/atoms.dart';

/// Branch timetable — day selector + per-day class cards, weekly view.
/// Founder edits (add/edit/enable-disable/delete); staff read-only.
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key, required this.staff});
  final bool staff;
  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SyncAware
  @override
  Set<String> get syncEntities => { 'timetable' };

  @override
  Future<void> reloadFromSync() => _load; {
  List<TimetableEntry> _rows = [];
  List<Teacher> _teachers = [];
  String? _error;
  bool _busy = true;
  int _day = DateTime.now().weekday - 1; // ISO: 0=Mon
  bool _weekly = false;

  bool get canEdit => !widget.staff && TimetablePolicy.canEdit(staff: widget.staff);

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
      final results = await Future.wait([
        auth.service!.timetableList(branch: auth.branch ?? 'ALL'),
        if (widget.staff) Future.value(<Teacher>[]) else auth.service!.listTeachers(),
      ]);
      if (!mounted) return;
      setState(() {
        _rows = results[0] as List<TimetableEntry>;
        _teachers = results.length > 1 ? results[1] as List<Teacher> : const <Teacher>[];
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

  List<TimetableEntry> get _dayRows {
    final day = _rows.where((e) => e.dayOfWeek == _day).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return day;
  }

  List<(int, List<TimetableEntry>)> get _weeklyViewData {
    final out = <(int, List<TimetableEntry>)>[];
    for (var d = 0; d < 7; d++) {
      final list = _rows.where((e) => e.dayOfWeek == d).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      out.add((d, list));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) return const SkeletonList(rows: 8);
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Timetable')),
        body: Padding(padding: const EdgeInsets.all(AppSpace.s4), child: ErrorView(_error!, onRetry: _load)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _weekly = !_weekly),
            child: Text(_weekly ? 'Day view' : 'Weekly view',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          if (widget.staff)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text('READ-ONLY',
                    style: AppType.eyebrow.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 9)),
              ),
            ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => _edit(_blankEntry()),
              icon: const Icon(Icons.add),
              label: const Text('Add class'),
            )
          : null,
      body: RefreshScaffold(
        onRefresh: _load,
        child: _weekly ? _weeklyView() : _dayView(),
      ),
    );
  }

  TimetableEntry _blankEntry() => TimetableEntry(
        id: '',
        branch: 'KANDIVALI',
        dayOfWeek: 0,
        startTime: '17:00',
        endTime: '18:00',
        className: '',
      );

  Widget _dayView() {
    return Column(children: [
      // Day selector
      SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: 6),
          children: [
            for (var d = 0; d < timetableDayNames.length; d++)
              Padding(
                padding: const EdgeInsets.only(right: AppSpace.s2),
                child: ChoiceChip(
                  label: Text(timetableDayNames[d], style: const TextStyle(fontSize: 12)),
                  selected: _day == d,
                  onSelected: (_) => setState(() => _day = d),
                ),
              ),
          ],
        ),
      ),
      const Padding(
        padding: EdgeInsets.only(left: AppSpace.s5, right: AppSpace.s5, top: AppSpace.s2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Kandivali', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
      Expanded(
        child: _dayRows.isEmpty
            ? const EmptyState('No classes scheduled this day.')
            : ListView(
                padding: const EdgeInsets.all(AppSpace.s4),
                children: [
                  for (final e in _dayRows) _card(e),
                ],
              ),
      ),
    ]);
  }

  Widget _weeklyView() {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.s4),
      children: [
        for (final (d, list) in _weeklyViewData) ...[
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s3, bottom: AppSpace.s2),
            child: Text(timetableDayNames[d],
                style: AppType.eyebrow.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
          ),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpace.s2),
              child: Text('No classes', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            )
          else
            for (final e in list) _card(e),
        ],
      ],
    );
  }

  Widget _card(TimetableEntry e) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpace.s3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e.timeLabelStart} — ${e.timeLabelEnd}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              Text(e.className, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text(e.teacherName.isNotEmpty ? e.teacherName : 'No teacher assigned',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
          if (e.teacherId.isNotEmpty) TagChip(e.teacherId, color: AppColors.focus),
          if (canEdit)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: AppColors.muted),
              onSelected: (v) {
                if (v == 'edit') _edit(e);
                if (v == 'del') _delete(e);
                if (v == 'toggle') _toggle(e);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'toggle', child: Text(e.enabled ? 'Disable' : 'Enable')),
                const PopupMenuItem(value: 'del', child: Text('Delete')),
              ],
            ),
        ]),
      ),
    );
  }

  Future<void> _edit(TimetableEntry entry) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _TimetableForm(entry: entry, teachers: _teachers),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(TimetableEntry e) async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete class?'),
        content: Text('${e.className} ${e.timeLabelStart}–${e.timeLabelEnd}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await auth.service!.timetableDelete(e.id);
      await _load();
    } on ApiException catch (e2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e2.message)));
    } on ApiUnreachable catch (e2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e2.message)));
    }
  }

  Future<void> _toggle(TimetableEntry e) async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    final nextStatus = e.enabled ? 'DISABLED' : 'ENABLED';
    try {
      await auth.service!.timetableUpdate(e.id, {
        'status': nextStatus,
      });
      await _load();
    } on ApiException catch (e2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e2.message)));
    } on ApiUnreachable catch (e2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e2.message)));
    }
  }
}

class _TimetableForm extends StatefulWidget {
  const _TimetableForm({required this.entry, required this.teachers});
  final TimetableEntry? entry;
  final List<Teacher> teachers;
  @override
  State<_TimetableForm> createState() => _TimetableFormState();
}

class _TimetableFormState extends State<_TimetableForm> {
  final _class = TextEditingController();
  final _teacherName = TextEditingController();
  late String _start;
  late String _end;
  late int _day;
  late String _status;
  String? _teacherId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _class.text = e?.className ?? '';
    _teacherName.text = e?.teacherName ?? '';
    _start = e?.startTime ?? '17:00';
    _end = e?.endTime ?? '18:00';
    _day = e?.dayOfWeek ?? 0;
    _status = e?.status ?? 'ENABLED';
    _teacherId = e?.teacherId ?? '';
  }

  @override
  void dispose() {
    _class.dispose();
    _teacherName.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool start}) async {
    final parts = (start ? _start : _end).split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (t == null) return;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    setState(() {
      if (start) {
        _start = '$hh:$mm';
      } else {
        _end = '$hh:$mm';
      }
    });
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    final range = TimetableValidator.range(_start, _end);
    if (!range.ok) {
      setState(() => _error = range.error);
      return;
    }
    final cErr = TimetableValidator.className(_class.text);
    if (cErr != null) {
      setState(() => _error = cErr);
      return;
    }
    final branch = (auth.branch ?? '').toUpperCase();
    final base = {
      'branch': branch,
      'dayOfWeek': _day,
      'startTime': _start,
      'endTime': _end,
      'className': _class.text.trim(),
      'teacherId': _teacherId ?? '',
      'teacherName': _teacherName.text.trim(),
      'status': _status,
    };
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.entry == null) {
        await auth.service!.timetableCreate(base);
      } else {
        await auth.service!.timetableUpdate(widget.entry!.id, base);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entry == null ? 'Add class' : 'Edit class'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextFormField(
            controller: _class,
            decoration: const InputDecoration(labelText: 'Class / instrument *', prefixIcon: Icon(Icons.music_note_outlined)),
          ),
          const SizedBox(height: AppSpace.s3),
          Text('DAY', style: AppType.eyebrow.copyWith(fontSize: 10)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (var d = 0; d < timetableDayNames.length; d++)
                ChoiceChip(
                  label: Text(timetableDayNames[d], style: const TextStyle(fontSize: 11)),
                  selected: _day == d,
                  onSelected: (_) => setState(() => _day = d),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          Row(children: [
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule, color: AppColors.muted),
                title: Text('Start: ${TimetableEntry.time12(_start)}'),
                onTap: () => _pickTime(start: true),
              ),
            ),
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule, color: AppColors.muted),
                title: Text('End: ${TimetableEntry.time12(_end)}'),
                onTap: () => _pickTime(start: false),
              ),
            ),
          ]),
          if (widget.teachers.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s2),
            DropdownButtonFormField<String>(
              value: _teacherId == '' && widget.teachers.isNotEmpty ? null : _teacherId,
              decoration: const InputDecoration(labelText: 'Teacher'),
              hint: const Text('Select teacher…'),
              items: [
                for (final t in widget.teachers)
                  DropdownMenuItem(value: t.teacherId, child: Text(t.teacherName)),
              ],
              onChanged: (v) => setState(() {
                _teacherId = v;
                String nm = '';
                for (final t in widget.teachers) {
                  if (t.teacherId == v) {
                    nm = t.teacherName;
                    break;
                  }
                }
                _teacherName.text = nm;
              }),
            ),
            const SizedBox(height: AppSpace.s3),
          ],
          TextFormField(
            controller: _teacherName,
            decoration: const InputDecoration(labelText: 'Teacher (name)'),
          ),
          const SizedBox(height: AppSpace.s3),
          Row(children: [
            const Text('Enabled', style: TextStyle(fontSize: 13)),
            Switch.adaptive(value: _status == 'ENABLED', onChanged: (v) => setState(() => _status = v ? 'ENABLED' : 'DISABLED')),
          ]),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s2),
              child: Text(_error!, style: const TextStyle(color: AppColors.blockFg, fontSize: 13)),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.entry == null ? 'Add class' : 'Save changes'),
        ),
      ],
    );
  }
}