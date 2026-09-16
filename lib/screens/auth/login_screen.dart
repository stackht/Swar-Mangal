import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../core/session_storage.dart';
import '../../core/theme.dart';
import '../../core/url_config.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atmosphere.dart';
import '../../widgets/atoms.dart';
import '../../widgets/music_mark.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _token = TextEditingController();
  bool _obscureToken = true;
  String _endpoint = 'founder';
  String? _customUrl;

  @override
  void initState() {
    super.initState();
    // Load only NON-sensitive settings (API URL + endpoint). The token is
    // never loaded into the visible field — session restoration is silent.
    AuthProvider.loadSettings().then((s) {
      if (!mounted) return;
      setState(() {
        _customUrl = s.url;
        if (s.endpoint == 'staff' || s.endpoint == 'founder') _endpoint = s.endpoint!;
      });
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
    // Persisted custom URL only if it passes validation; otherwise fall back
    // to the configured production gateway. Never silently use a placeholder.
    final url = resolveEffectiveUrl(persistedUrl: _customUrl, staff: _endpoint == 'staff');
    final v = RpcUrlValidator.validate(url);
    if (!v.ok) {
      _toast(v.error ?? 'Invalid API URL.');
      return;
    }
    final provider = context.read<AuthProvider>();
    await provider.login(
          endpoint: _endpoint,
          token: _token.text.trim(),
          apiUrl: v.url!,
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Atmosphere(
        child: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpace.s6),
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(Icons.music_note, size: 34, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpace.s4),
              Center(
                child: WaveformMark(active: true, height: 24, color: scheme.primary),
              ),
              const SizedBox(height: AppSpace.s3),
              Text('Welcome',
                  textAlign: TextAlign.center,
                  style: AppType.eyebrow.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: AppSpace.s2),
              Text('Swar Mangal',
                  textAlign: TextAlign.center,
                  style: AppType.display.copyWith(
                    fontSize: 30,
                    color: scheme.onSurface,
                  )),
              const SizedBox(height: AppSpace.s2),
              Text('Goregaon  ·  Kandivali',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
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
                        obscureText: _obscureToken,
                        decoration: InputDecoration(
                          labelText: 'Device token',
                          hintText: 'Issued by the founder',
                          prefixIcon: const Icon(Icons.key),
                          suffixIcon: IconButton(
                            tooltip: _obscureToken ? 'Show token' : 'Hide token',
                            icon: Icon(
                              _obscureToken
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(() => _obscureToken = !_obscureToken),
                          ),
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
        ),  // SingleChildScrollView
        ),  // SafeArea
      ),  // Atmosphere
    );  // Scaffold
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
            await SessionStorage.saveApiUrl(url);
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
    _c = TextEditingController(text: widget.initial ?? AppConfig.founderApiUrl);
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
              labelText: 'Gateway URL /api/rpc',
              hintText: 'https://swarmangal-app-production.up.railway.app/api/rpc',
            ),
          ),
          const SizedBox(height: AppSpace.s3),
          const Text(
            'Point the app at the Swar Mangal Railway gateway, then enter the '
            'device token that gateway issues.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpace.s4),
          LoadingButton(label: 'Save', icon: Icons.save, onPressed: () => widget.onSave(_c.text.trim())),
        ],
      );
}