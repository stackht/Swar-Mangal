import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _token = TextEditingController();
  String _endpoint = 'founder';
  String? _customUrl;

  @override
  void initState() {
    super.initState();
    AuthProvider.loadSettings().then((s) {
      if (!mounted) return;
      setState(() => _customUrl = s.url);
    });
  }

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_token.text.trim().isEmpty) {
      _toast('Enter your device token first.');
      return;
    }
    final url = _customUrl?.trim().isNotEmpty == true
        ? _customUrl!.trim()
        : (_endpoint == 'staff' ? AppConfig.staffExecUrl : AppConfig.founderExecUrl);
    final provider = context.read<AuthProvider>();
    await provider.login(
          endpoint: _endpoint,
          token: _token.text.trim(),
          execUrl: url,
        );
    if (!mounted) return;
    if (provider.error != null) {
      _toast(provider.error!);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpace.s6),
              const Icon(Icons.music_note, size: 56, color: Colors.white),
              const SizedBox(height: AppSpace.s3),
              Text('SwarMangal\nAcademyOS',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.1)),
              const SizedBox(height: AppSpace.s2),
              Text('Goregaon  ·  Kandivali',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 13)),
              const SizedBox(height: AppSpace.s6),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'founder', label: Text('Founder')),
                          ButtonSegment(value: 'staff', label: Text('Staff')),
                        ],
                        selected: {_endpoint},
                        onSelectionChanged: (s) => setState(() => _endpoint = s.first),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      TextField(
                        controller: _token,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Device token',
                          hintText: 'Issued by the founder',
                          prefixIcon: Icon(Icons.key),
                        ),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      if (auth.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.s3),
                          child: Text(auth.error!,
                              style: const TextStyle(color: AppColors.blockFg, fontSize: 13)),
                        ),
                      LoadingButton(
                        label: _endpoint == 'staff' ? 'Open Staff App' : 'Open Founder App',
                        icon: Icons.login,
                        busy: auth.busy,
                        onPressed: _login,
                      ),
                      const SizedBox(height: AppSpace.s3),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryDark,
                              side: const BorderSide(color: AppColors.line),
                              minimumSize: const Size(0, AppSpace.s6),
                            ),
                            onPressed: auth.busy
                                ? null
                                : () => context
                                    .read<AuthProvider>()
                                    .demoLogin(founder: true),
                            child: const Text('Demo · Founder',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: AppSpace.s2),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryDark,
                              side: const BorderSide(color: AppColors.line),
                              minimumSize: const Size(0, AppSpace.s6),
                            ),
                            onPressed: auth.busy
                                ? null
                                : () => context
                                    .read<AuthProvider>()
                                    .demoLogin(founder: false),
                            child: const Text('Demo · Staff',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ]),
                      const SizedBox(height: AppSpace.s3),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: 'API server settings',
                          onPressed: _showServerSheet,
                          icon: const Icon(Icons.settings_outlined, size: 20, color: AppColors.muted),
                        ),
                      ),
                      Align(
                        child: Text(
                            'v${AppConfig.appVersion} · ${AppConfig.appBuild}'
                            '${auth.isDemo ? ' · demo mode' : ''}',
                            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showServerSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: AppSpace.s4, right: AppSpace.s4, top: AppSpace.s4,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.s4,
        ),
        child: _ServerSheet(
          initial: _customUrl,
          onSave: (url) async {
            await AuthProvider.saveSettings(execUrl: url);
            if (!mounted) return;
            setState(() => _customUrl = url);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class _ServerSheet extends StatefulWidget {
  const _ServerSheet({required this.initial, required this.onSave});
  final String? initial;
  final ValueChanged<String> onSave;
  @override
  State<_ServerSheet> createState() => _ServerSheetState();
}

class _ServerSheetState extends State<_ServerSheet> {
  late final TextEditingController _c;
  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial ?? AppConfig.founderExecUrl);
  }
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('API server'),
          TextField(
            controller: _c,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Web app /exec URL',
              hintText: 'https://script.google.com/macros/s/<ID>/exec',
            ),
          ),
          const SizedBox(height: AppSpace.s3),
          const Text(
            'Point the app at a deployed AcademyOS backend, then enter the '
            'device token that backend issues.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpace.s4),
          LoadingButton(label: 'Save', icon: Icons.save, onPressed: () => widget.onSave(_c.text.trim())),
        ],
      );
}