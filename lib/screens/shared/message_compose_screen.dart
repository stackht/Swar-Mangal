import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';

/// Message compose — generate a copy-ready message for a student (fee / renewal /
/// terms / teacher reminder). COPY_ONLY on the server; this screen never sends.
class MessageComposeScreen extends StatefulWidget {
  const MessageComposeScreen({
    super.key,
    required this.staff,
    required this.studentId,
    required this.studentName,
    this.parentName = '',
    this.instrument = '',
    this.branch = '',
  });
  final bool staff;
  final String studentId;
  final String studentName;
  final String parentName;
  final String instrument;
  final String branch;
  @override
  State<MessageComposeScreen> createState() => _MessageComposeScreenState();
}

class _MessageComposeScreenState extends State<MessageComposeScreen> {
  String _type = 'FEE_REMINDER';
  CommMessage? _msg;
  bool _busy = false;
  String? _error;
  bool _copied = false;

  static const _types = [
    'FEE_REMINDER',
    'DUE_SOON',
    'DUE_TODAY',
    'OVERDUE_ACCRUING',
    'RENEWAL',
    'TERMS',
    'TEACHER_FEE_DUE',
    'ABSENT_TODAY',
  ];

  Future<void> _generate() async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _msg = null;
      _copied = false;
    });
    try {
      final m = await auth.service!.staffCommGenerate({
        'type': _type,
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'parentName': widget.parentName,
        'instrument': widget.instrument,
        'branch': widget.branch,
      });
      if (!mounted) return;
      setState(() {
        _msg = m;
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

  Future<void> _copy() async {
    final text = '${_msg?.subject ?? ''}\n\n${_msg?.body ?? ''}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Message copied to clipboard.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose message'),
        actions: [
          if (_msg != null)
            IconButton(
              tooltip: _copied ? 'Copied' : 'Copy text',
              icon: Icon(_copied ? Icons.check_circle_outline : Icons.copy),
              onPressed: _copy,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s4),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('FOR: ${widget.studentName}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpace.s3),
                const Text('Message type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
                const SizedBox(height: AppSpace.s2),
                Wrap(
                  spacing: AppSpace.s2,
                  runSpacing: AppSpace.s2,
                  children: _types.map((t) {
                    final sel = _type == t;
                    return ChoiceChip(
                      label: Text(t.replaceAll('_', ' '), style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      onSelected: (_) => setState(() {
                        _type = t;
                        _msg = null;
                      }),
                    );
                  }).toList(),
                ),
              ]),
            ),
          ),
          const SizedBox(height: AppSpace.s3),
          LoadingButton(
            label: 'Generate message',
            icon: Icons.auto_fix_high,
            busy: _busy,
            onPressed: _generate,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s3),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s3),
                  child: ErrorView(_error!, compact: true),
                ),
              ),
            ),
          if (_msg != null) ...[
            const SizedBox(height: AppSpace.s4),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('TO: ', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                    Expanded(
                      child: Text(_msg!.recipientName.isNotEmpty ? _msg!.recipientName : '(unknown)',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ]),
                  const SizedBox(height: AppSpace.s2),
                  Text(_msg!.subject,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const SizedBox(height: AppSpace.s2),
                  SelectableText(_msg!.body,
                      style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.ink)),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s2),
              child: Card(
                color: AppColors.infoBg,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s3),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.infoFg),
                    const SizedBox(width: AppSpace.s2),
                    Expanded(
                      child: Text(
                        '${_msg!.copyOnly ? 'COPY_ONLY — provider send is disabled.' : ''}'
                        '${_msg!.typeCorrected ? ' Resolved to ${_msg!.typeResolved} (requested ${_msg!.typeRequested}).' : ''}'
                        '${_msg!.warnings.isNotEmpty ? ' Note: ${_msg!.warnings.join('; ')}' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.infoFg),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s4),
            LoadingButton(
              label: _copied ? 'Copied ✓' : 'Copy message',
              icon: _copied ? Icons.check_circle_outline : Icons.copy,
              busy: false,
              onPressed: _copy,
            ),
          ],
        ],
      ),
    );
  }
}