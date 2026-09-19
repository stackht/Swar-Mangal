import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/sync_manager.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';
import 'inquiry_profile_screen.dart';

/// Lead pipeline: queue (actionable vs all), quick add, transitions per row
/// (LOG_CONTACT / SCHEDULE_TRIAL / TRIAL_DONE / DROP / REOPEN / CONVERT).
class InquiriesScreen extends StatefulWidget {
  const InquiriesScreen({super.key});
  @override
  State<InquiriesScreen> createState() => _InquiriesScreenState();
}

class _InquiriesScreenState extends State<InquiriesScreen> with SyncAware {
  @override
  Set<String> get syncEntities => const {'inquiries'};

  @override
  Future<void> reloadFromSync() => _load();

  List<Inquiry> _rows = [];
  String? _error;
  bool _busy = true;
  bool _showAdd = false;
  bool _actionableOnly = true;
  bool _acting = false;

  /// null = all instruments, '' = no preference ("random" lead), else exact match.
  String? _instrumentFilter;
  /// ALL | NEW | EXISTING — a market-strategy split: fresh leads vs. former
  /// students being won back (source == kFormerStudentSource).
  String _leadTypeFilter = 'ALL';

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
      final rows = await auth.service!.staffInquiryQueue(branch: auth.branch ?? 'ALL');
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  Future<void> _transition(Inquiry q, String action, Map<String, dynamic> extra) async {
    if (_acting) return;
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    setState(() => _acting = true);
    try {
      final r = await auth.service!.staffInquiryTransition({
        'branch': auth.branch ?? '',
        'inquiryId': q.inquiryId,
        'action': action,
        'today': _today(),
        ...extra,
      });
      final m = r as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(m['ok'] == true ? (m['note'] ?? 'Recorded.') : (m['error'] ?? 'Could not complete.'))));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  List<Inquiry> get _filtered {
    var list = _actionableOnly ? _rows.where((q) => q.actionable).toList() : _rows;
    if (_instrumentFilter != null) {
      list = list.where((q) => q.course.trim() == _instrumentFilter).toList();
    }
    if (_leadTypeFilter == 'NEW') {
      list = list.where((q) => !q.isFormerStudent).toList();
    } else if (_leadTypeFilter == 'EXISTING') {
      list = list.where((q) => q.isFormerStudent).toList();
    }
    return list;
  }

  List<String> get _instrumentOptions {
    final set = <String>{};
    for (final q in _rows) {
      if (q.course.trim().isNotEmpty) set.add(q.course.trim());
    }
    final list = set.toList()..sort();
    return list;
  }

  bool get _filterActive => _leadTypeFilter != 'ALL' || _instrumentFilter != null;

  String get _filterSummary {
    if (!_filterActive) return 'Filter';
    final parts = <String>[];
    if (_leadTypeFilter == 'NEW') parts.add('New');
    if (_leadTypeFilter == 'EXISTING') parts.add('Existing');
    if (_instrumentFilter == '') parts.add('No preference');
    if (_instrumentFilter != null && _instrumentFilter != '') parts.add(_instrumentFilter!);
    return parts.join(' · ');
  }

  Future<void> _openFilterSheet() async {
    var leadType = _leadTypeFilter;
    String? instrument = _instrumentFilter;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Expanded(child: Text('Filter inquiries', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                  TextButton(
                    onPressed: () => setSheetState(() {
                      leadType = 'ALL';
                      instrument = null;
                    }),
                    child: const Text('Clear'),
                  ),
                ]),
                const SizedBox(height: AppSpace.s2),
                Text('Lead type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.adaptive(sheetContext, AppColors.muted))),
                RadioGroup<String>(
                  groupValue: leadType,
                  onChanged: (v) => setSheetState(() => leadType = v!),
                  child: const Column(children: [
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text('All leads'),
                      value: 'ALL',
                    ),
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text('New'),
                      value: 'NEW',
                    ),
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text('Existing (win-back)'),
                      value: 'EXISTING',
                    ),
                  ]),
                ),
                const SizedBox(height: AppSpace.s3),
                Text('Instrument', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.adaptive(sheetContext, AppColors.muted))),
                Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: [
                  ChoiceChip(
                    label: const Text('Any'),
                    selected: instrument == null,
                    onSelected: (_) => setSheetState(() => instrument = null),
                  ),
                  ChoiceChip(
                    label: const Text('No preference'),
                    selected: instrument == '',
                    onSelected: (_) => setSheetState(() => instrument = ''),
                  ),
                  for (final inst in _instrumentOptions)
                    ChoiceChip(
                      label: Text(inst),
                      selected: instrument == inst,
                      onSelected: (_) => setSheetState(() => instrument = inst),
                    ),
                ]),
                const SizedBox(height: AppSpace.s4),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Apply'),
                  ),
                ),
              ]),
            ),
          );
        });
      },
    );
    setState(() {
      _leadTypeFilter = leadType;
      _instrumentFilter = instrument;
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return RefreshScaffold(
      onRefresh: _load,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.s4, AppSpace.s3, AppSpace.s4, 0),
          child: Row(children: [
            Icon(Icons.campaign_outlined, color: AppColors.adaptive(context, AppColors.primary)),
            const SizedBox(width: AppSpace.s2),
            Expanded(
              child: Text('${list.length} ${list.length == 1 ? 'inquiry' : 'inquiries'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            Switch.adaptive(
              value: _actionableOnly,
              onChanged: (v) => setState(() => _actionableOnly = v),
            ),
            const Text('Today', style: TextStyle(fontSize: 12)),
            TextButton.icon(
              onPressed: () => setState(() => _showAdd = !_showAdd),
              icon: Icon(_showAdd ? Icons.close : Icons.add, size: 18),
              label: Text(_showAdd ? 'Close' : 'Quick add'),
            ),
          ]),
        ),
        if (_showAdd) _InquiryForm(onSaved: () {
          setState(() => _showAdd = false);
          _load();
        }),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.s4, AppSpace.s3, AppSpace.s4, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _openFilterSheet,
              icon: Icon(_filterActive ? Icons.filter_alt : Icons.filter_alt_outlined, size: 18),
              label: Text(_filterSummary),
            ),
          ),
        ),
        Expanded(
          child: _busy && list.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null && list.isEmpty
                  ? ErrorView(_error!, onRetry: _load)
                  : list.isEmpty
                      ? const EmptyState('No inquiries.', icon: Icons.campaign_outlined)
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: AppSpace.s6),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (c, i) => _row(list[i]),
                        ),
        ),
      ]),
    );
  }

  Widget _row(Inquiry q) {
    final status = q.status.toUpperCase();
    const canFollowUp = {'OPEN', 'CONTACTED', 'DORMANT'};
    return Card(
      margin: const EdgeInsets.fromLTRB(AppSpace.s4, AppSpace.s3, AppSpace.s4, 0),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => InquiryProfileScreen(inquiryId: q.inquiryId)));
          if (mounted) _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s3),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.adaptive(context, q.actionable ? AppColors.warnBg : AppColors.pageBg),
                child: Text(q.name.isNotEmpty ? q.name[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.adaptive(context, q.actionable ? AppColors.warnFg : AppColors.muted))),
              ),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(q.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                    if (q.isFormerStudent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.adaptive(context, AppColors.warnBg), borderRadius: BorderRadius.circular(6)),
                        child: Text('WIN-BACK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.adaptive(context, AppColors.warnFg))),
                      ),
                    ],
                  ]),
                  Text(
                      [q.course.isEmpty ? 'No instrument preference' : q.course, q.phone, q.branch].where((e) => e.isNotEmpty).join(' · '),
                      style: TextStyle(fontSize: 12, color: AppColors.adaptive(context, AppColors.muted))),
                  if (q.followUpDate.isNotEmpty)
                    Text('Follow up: ${q.followUpDate}', style: TextStyle(fontSize: 11, color: AppColors.adaptive(context, AppColors.focus))),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                StatusBadge(q.status),
                const SizedBox(height: 4),
                _finalStatusChip(q.finalStatus),
              ]),
            ]),
            const SizedBox(height: AppSpace.s2),
            if (status == 'DROPPED' || status == 'DORMANT')
              TextButton.icon(
                onPressed: _acting
                    ? null
                    : () async {
                        final reason = await _ask('Reopen inquiry', 'Reason');
                        if (reason != null) _transition(q, 'REOPEN', {'reason': reason});
                      },
                icon: const Icon(Icons.replay_outlined, size: 16),
                label: const Text('Reopen'),
              ),
            if (q.actionable) ...[
              Wrap(
                spacing: AppSpace.s2,
                runSpacing: AppSpace.s2,
                children: [
                  if (canFollowUp.contains(status))
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.adaptive(context, AppColors.focus)),
                      onPressed: _acting ? null : () => _logContact(q),
                      child: const Text('Log contact', style: TextStyle(fontSize: 11)),
                    ),
                  if (canFollowUp.contains(status))
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.adaptive(context, AppColors.warnFg)),
                      onPressed: _acting ? null : () => _scheduleTrial(q),
                      child: const Text('Schedule trial', style: TextStyle(fontSize: 11)),
                    ),
                  if (status == 'TRIAL_SCHEDULED')
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.adaptive(context, AppColors.okFg)),
                      onPressed: _acting ? null : () => _transition(q, 'TRIAL_DONE', {}),
                      child: const Text('Trial done', style: TextStyle(fontSize: 11)),
                    ),
                  if (canFollowUp.contains(status) || status == 'TRIAL_SCHEDULED')
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.adaptive(context, AppColors.blockFg)),
                      onPressed: _acting ? null : () => _drop(q),
                      child: const Text('Drop', style: TextStyle(fontSize: 11)),
                    ),
                  if (q.status != 'CONVERTED')
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.adaptive(context, AppColors.okFg)),
                      onPressed: _acting ? null : () => _convert(q),
                      child: const Text('Convert', style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _finalStatusChip(String finalStatus) {
    final Color color = AppColors.adaptive(context, switch (finalStatus) {
      'APPROVED' => AppColors.okFg,
      'REJECTED' => AppColors.blockFg,
      _ => AppColors.muted,
    });
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(6)),
      child: Text(finalStatus, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Future<void> _logContact(Inquiry q) async {
    final date = await _pickDate('Next follow-up date');
    if (date == null || !mounted) return;
    final note = await _ask('What was discussed?', 'Short description (optional)');
    _transition(q, 'LOG_CONTACT', {'nextContactDate': date, if ((note ?? '').isNotEmpty) 'note': note});
  }

  Future<void> _scheduleTrial(Inquiry q) async {
    final date = await _pickDate('Trial date');
    if (date == null || !mounted) return;
    final note = await _ask('What was discussed?', 'Short description (optional)');
    _transition(q, 'SCHEDULE_TRIAL', {'trialDate': date, if ((note ?? '').isNotEmpty) 'note': note});
  }

  Future<void> _drop(Inquiry q) async {
    final reason = await _ask('Drop inquiry', 'Why? (required)');
    if (reason != null) _transition(q, 'DROP', {'reason': reason});
  }

  Future<void> _convert(Inquiry q) async {
    // Converting links the inquiry to a student who already exists. Search by
    // the inquiry's phone (or name) and pick the match instead of typing an id.
    final picked = await showDialog<Student>(
      context: context,
      builder: (ctx) => _StudentPicker(initialQuery: q.phone.isNotEmpty ? q.phone : q.name),
    );
    if (picked != null) {
      _transition(q, 'CONVERT', {'studentRef': picked.studentId});
    }
  }

  Future<String?> _ask(String title, String label) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickDate(String label) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d == null) return null;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _InquiryForm extends StatefulWidget {
  const _InquiryForm({required this.onSaved});
  final VoidCallback onSaved;
  @override
  State<_InquiryForm> createState() => _InquiryFormState();
}

class _InquiryFormState extends State<_InquiryForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _instrument = TextEditingController();
  final _notes = TextEditingController();
  bool _busy = false;
  String? _result;
  bool _ok = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _instrument, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty && _phone.text.trim().isEmpty) {
      setState(() {
        _result = 'Enter at least a name or a phone.';
        _ok = false;
      });
      return;
    }
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final r = await auth.service!.staffInquiryQuickAdd({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'instrument': _instrument.text.trim(),
        'branch': auth.branch ?? '',
        'notes': _notes.text.trim(),
      });
      final m = r as Map<String, dynamic>;
      if (!mounted) return;
      final saved = m['ok'] == true;
      setState(() {
        _busy = false;
        _ok = saved;
        _result = saved
            ? 'Inquiry ${m['inquiryId']} captured.'
            : (m['error'] ?? 'Could not save.').toString();
      });
      if (saved) {
        _name.clear();
        _phone.clear();
        _instrument.clear();
        _notes.clear();
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) widget.onSaved();
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _ok = false;
        _result = e.message;
      });
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _ok = false;
        _result = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.s4, AppSpace.s3, AppSpace.s4, AppSpace.s3),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Quick add new lead', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpace.s3),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: AppSpace.s2),
            TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: AppSpace.s2),
            TextFormField(controller: _instrument, decoration: const InputDecoration(labelText: 'Instrument / course')),
            const SizedBox(height: AppSpace.s2),
            TextFormField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
            if (_result != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.s3),
                child: Text(_result!, style: TextStyle(color: AppColors.adaptive(context, _ok ? AppColors.okFg : AppColors.blockFg), fontSize: 13)),
              ),
            const SizedBox(height: AppSpace.s3),
            LoadingButton(label: 'Capture lead', icon: Icons.add, busy: _busy, onPressed: _submit),
          ]),
        ),
      ),
    );
  }
}

class _StudentPicker extends StatefulWidget {
  const _StudentPicker({required this.initialQuery});
  final String initialQuery;
  @override
  State<_StudentPicker> createState() => _StudentPickerState();
}

class _StudentPickerState extends State<_StudentPicker> {
  late final TextEditingController _q = TextEditingController(text: widget.initialQuery);
  List<Student> _rows = const [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().isNotEmpty) _search();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final auth = context.read<AuthProvider>();
    final q = _q.text.trim();
    if (auth.service == null || q.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = auth.isStaff
          ? await auth.service!.staffSearchStudents(q)
          : await auth.service!.searchStudents(q);
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Convert to student'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add the student first, then pick them here.',
              style: TextStyle(fontSize: 12, color: AppColors.adaptive(context, AppColors.muted))),
          const SizedBox(height: AppSpace.s2),
          TextField(
            controller: _q,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'Name or phone',
              suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _busy ? null : _search),
            ),
          ),
          const SizedBox(height: AppSpace.s2),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Text(_error!, style: TextStyle(color: AppColors.adaptive(context, AppColors.blockFg), fontSize: 12)),
          if (!_busy && _error == null && _rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpace.s2),
              child: Text('No matching student.', style: TextStyle(fontSize: 12, color: AppColors.adaptive(context, AppColors.muted))),
            ),
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              for (final st in _rows)
                ListTile(
                  dense: true,
                  title: Text(st.studentName),
                  subtitle: Text([st.studentId, st.instrument, st.location].where((x) => x.isNotEmpty).join(' · ')),
                  onTap: () => Navigator.pop(context, st),
                ),
            ]),
          ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}
