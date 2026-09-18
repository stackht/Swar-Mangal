import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';

/// Founder-only: who may self-register a token (email allow-list), and every
/// device token issued so far, revocable on the spot. OTP only proves someone
/// controls an inbox — this list is the actual authorization step.
class StaffAccessScreen extends StatefulWidget {
  const StaffAccessScreen({super.key});
  @override
  State<StaffAccessScreen> createState() => _StaffAccessScreenState();
}

class _StaffAccessScreenState extends State<StaffAccessScreen> {
  List<Map<String, dynamic>> _authorized = [];
  List<Map<String, dynamic>> _tokens = [];
  bool _busy = true;
  String? _error;
  final Set<String> _acting = {};

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
        auth.service!.raw('api_founder_listAuthorizedEmails', const {}),
        auth.service!.raw('api_founder_listStaffTokens', const {}),
      ]);
      if (!mounted) return;
      setState(() {
        _authorized = ((results[0] as Map<String, dynamic>)['rows'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _tokens = ((results[1] as Map<String, dynamic>)['rows'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
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

  Future<void> _addEmail() async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    final emailCtrl = TextEditingController();
    final branchesCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add staff access'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email address')),
          const SizedBox(height: AppSpace.s2),
          TextField(
            controller: branchesCtrl,
            decoration: const InputDecoration(labelText: 'Branches (optional, e.g. GOREGAON)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok != true || emailCtrl.text.trim().isEmpty) return;
    try {
      await auth.service!.raw('api_founder_addAuthorizedEmail', {
        'email': emailCtrl.text.trim(),
        'branches': branchesCtrl.text.trim(),
      });
      if (!mounted) return;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _removeEmail(String email) async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null || _acting.contains(email)) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove access'),
        content: Text('$email will no longer be able to register or reset a token, and any active token of theirs is revoked immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _acting.add(email));
    try {
      await auth.service!.raw('api_founder_removeAuthorizedEmail', {'email': email});
      if (!mounted) return;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _acting.remove(email));
    }
  }

  Future<void> _revokeDevice(String id) async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null || _acting.contains(id)) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke this device'),
        content: const Text('This device is locked out immediately. The person can self-register a new token if they still have access.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revoke')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _acting.add(id));
    try {
      await auth.service!.raw('api_founder_revokeDeviceToken', {'id': id});
      if (!mounted) return;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _acting.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage staff access')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.adaptive(context, AppColors.primary),
        foregroundColor: Colors.white,
        onPressed: _addEmail,
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Add access'),
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(_error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpace.s4),
                    children: [
                      const SectionTitle('Authorized to register'),
                      if (_authorized.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
                          child: Text('No staff emails added yet.', style: TextStyle(fontSize: 13, color: AppColors.adaptive(context, AppColors.muted))),
                        )
                      else
                        for (final r in _authorized)
                          Card(
                            margin: const EdgeInsets.only(bottom: AppSpace.s2),
                            child: ListTile(
                              title: Text((r['email'] ?? '').toString()),
                              subtitle: Text((r['branches'] as String? ?? '').isEmpty ? 'Default branches' : r['branches'].toString()),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline, color: AppColors.adaptive(context, AppColors.blockFg)),
                                onPressed: _acting.contains(r['email']) ? null : () => _removeEmail((r['email'] ?? '').toString()),
                              ),
                            ),
                          ),
                      const SizedBox(height: AppSpace.s4),
                      const SectionTitle('Issued device tokens'),
                      if (_tokens.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
                          child: Text('No tokens issued yet.', style: TextStyle(fontSize: 13, color: AppColors.adaptive(context, AppColors.muted))),
                        )
                      else
                        for (final t in _tokens)
                          Card(
                            margin: const EdgeInsets.only(bottom: AppSpace.s2),
                            child: ListTile(
                              title: Row(children: [
                                Flexible(child: Text((t['label'] ?? '').toString())),
                                if (t['stale'] == true && (t['revokedAt'] as String? ?? '').isEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(color: AppColors.adaptive(context, AppColors.warnBg), borderRadius: BorderRadius.circular(6)),
                                    child: Text('UNUSED 90D+', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.adaptive(context, AppColors.warnFg))),
                                  ),
                                ],
                              ]),
                              subtitle: Text(
                                [t['role'], t['email'], t['lastUsedAt'] != null && (t['lastUsedAt'] as String).isNotEmpty ? 'last used ${t['lastUsedAt']}' : 'never used']
                                    .where((e) => e != null && e.toString().isNotEmpty)
                                    .join(' · '),
                              ),
                              trailing: (t['revokedAt'] as String? ?? '').isNotEmpty
                                  ? Text('REVOKED', style: TextStyle(fontSize: 11, color: AppColors.adaptive(context, AppColors.blockFg), fontWeight: FontWeight.w700))
                                  : TextButton(
                                      onPressed: _acting.contains(t['id']) ? null : () => _revokeDevice((t['id'] ?? '').toString()),
                                      child: const Text('Revoke'),
                                    ),
                            ),
                          ),
                    ],
                  ),
                ),
    );
  }
}
