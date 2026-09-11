import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/anim.dart';
import '../../widgets/atoms.dart';
import 'student_profile_screen.dart';
import 'add_student_screen.dart';

/// Student search + directory. `staff` flips the API to the branch-isolated
/// staff search endpoint and adds an inline "quick add" entry.
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key, required this.staff});
  final bool staff;
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _q = TextEditingController();
  List<Student> _rows = [];
  bool _busy = false;
  String? _error;
  String _classFilter = 'ALL';
  List<String> _classCodes = const ['GMC', 'KMC'];

  @override
  void initState() {
    super.initState();
    _classCodes = context.read<AuthProvider>().boot?.classCodes.isNotEmpty == true
        ? context.read<AuthProvider>().boot!.classCodes
        : const ['GMC', 'KMC'];
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = widget.staff
          ? await auth.service!.staffSearchStudents(_q.text,
              branch: auth.branch ?? 'ALL')
          : await auth.service!.searchStudents(_q.text, classCode: _classFilter);
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
    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Column(children: [
            SearchField(
              controller: _q,
              hint: widget.staff ? 'Name, phone or student ID' : 'Search by name, phone, ID, instrument',
              onChanged: (_) {
                if (_q.text.isEmpty) setState(() => _rows = []);
              },
              trailingIcon: Icons.arrow_forward,
            ),
            if (!widget.staff) ...[
              const SizedBox(height: AppSpace.s3),
              Row(children: [
                for (final c in _classCodes)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.s2),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _classFilter == c,
                      onSelected: (_) {
                        setState(() => _classFilter = c);
                        _search();
                      },
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _search,
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Search'),
                ),
              ]),
            ],
          ]),
        ),
        if (_busy)
          const Expanded(child: SkeletonList(rows: 7))
        else if (!widget.staff && _classFilter != 'ALL' && _rows.isEmpty && !_busy && _error == null)
          Expanded(
            child: Center(
              child: TextButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.refresh),
                label: Text('Search $_classFilter'),
              ),
            ),
          )
        else if (_error != null && _rows.isEmpty)
          Expanded(child: ErrorView(_error!, onRetry: _search))
        else
          Expanded(
            child: _rows.isEmpty
                ? EmptyState(
                    _q.text.trim().isEmpty
                        ? 'Search for a student by name or phone.'
                        : 'No students matched.',
                    icon: Icons.person_search_outlined)
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: AppSpace.s6),
                    itemCount: _rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (c, i) => _row(_rows[i]),
                  ),
          ),
      ],
    );
    return RefreshScaffold(
      onRefresh: _search,
      child: _q.text.trim().isEmpty && !_busy
          ? ListView(children: [
              Padding(
                padding: const EdgeInsets.all(AppSpace.s4),
                child: Column(children: [
                  const Text('Enter a search to list students.',
                      style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: AppSpace.s4),
                  FilledButton.icon(
                    onPressed: _search,
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Show all students'),
                  ),
                ]),
              ),
            ])
          : body,
    );
  }

  Widget _row(Student s) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => StudentProfileScreen(student: s, staff: widget.staff),
      )),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
        child: Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: .08),
            child: Text(s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.studentName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text('${s.classCode.isNotEmpty ? s.classCode : '—'} · ${s.instrument.isNotEmpty ? s.instrument : s.studentId} · ${s.phone}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 4),
              Wrap(spacing: AppSpace.s2, children: [
                StatusBadge(s.feeStatus.isEmpty ? 'UNKNOWN' : s.feeStatus),
                if (!s.operational) const StatusBadge('LEFT'),
              ]),
            ]),
          ),
          if (widget.staff)
            IconButton(
              tooltip: 'Edit student',
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.muted),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AddStudentScreen(staff: true, edit: s),
              )),
            ),
          Icon(Icons.chevron_right, color: AppColors.muted),
        ]),
      ),
    );
  }
}