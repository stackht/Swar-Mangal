import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../core/url_config.dart';
import '../../services/email_auth_service.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';

/// Self-service token registration/reset (brief-adjacent addition, not in
/// the original brief): register an email, verify a one-time code emailed to
/// it, then the app logs straight in with the freshly-issued token — no
/// manual copy/paste, and the plaintext token is never shown on screen.
class EmailOtpScreen extends StatefulWidget {
  const EmailOtpScreen({super.key, required this.endpoint, required this.purpose, this.customUrl});

  /// 'founder' | 'staff' — matches the login screen's segmented control.
  final String endpoint;

  /// 'REGISTER' | 'RESET'.
  final String purpose;
  final String? customUrl;

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  static const _service = EmailAuthService();
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  String get _role => widget.endpoint == 'staff' ? 'OPS_USER' : 'FOUNDER_ADMIN';
  String get _title => widget.purpose == 'RESET' ? 'Forgot / reset your token' : 'Set up your token';

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  String? _resolveUrl() {
    final url = resolveEffectiveUrl(persistedUrl: widget.customUrl, staff: widget.endpoint == 'staff');
    final v = RpcUrlValidator.validate(url);
    return v.ok ? v.url : null;
  }

  Future<void> _requestCode() async {
    final auth = context.read<AuthProvider>();
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email address.');
      return;
    }
    if (auth.isDemo) {
      // Demo mode never touches the real network — short-circuit straight
      // into the existing demo login, same as the login screen's buttons.
      setState(() => _codeSent = true);
      return;
    }
    final url = _resolveUrl();
    if (url == null) {
      setState(() => _error = 'Invalid API server URL. Check Settings first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.requestOtp(rpcUrl: url, email: email, role: _role, purpose: widget.purpose);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _codeSent = true;
      });
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

  Future<void> _verifyAndLogIn() async {
    final auth = context.read<AuthProvider>();
    if (auth.isDemo) {
      await auth.demoLogin(founder: widget.endpoint != 'staff');
      if (!mounted) return;
      if (auth.error == null) Navigator.of(context).pop();
      return;
    }
    final email = _email.text.trim();
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter the code that was emailed to you.');
      return;
    }
    final url = _resolveUrl();
    if (url == null) {
      setState(() => _error = 'Invalid API server URL. Check Settings first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await _service.verifyOtp(rpcUrl: url, email: email, role: _role, purpose: widget.purpose, code: code);
      if (token.isEmpty) throw ApiException('The server did not return a token.');
      await auth.login(endpoint: widget.endpoint, token: token, apiUrl: url);
      if (!mounted) return;
      setState(() => _busy = false);
      if (auth.error == null) {
        Navigator.of(context).pop();
      } else {
        setState(() => _error = auth.error);
      }
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
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s4),
        children: [
          Text(
            widget.purpose == 'RESET'
                ? 'We’ll email a one-time code to your registered address, then sign you in with a fresh token.'
                : 'Register your email, verify it with a one-time code, and we’ll sign you in automatically — no token to copy.',
            style: TextStyle(fontSize: 13, color: AppColors.adaptive(context, AppColors.muted)),
          ),
          const SizedBox(height: AppSpace.s4),
          TextField(
            controller: _email,
            enabled: !_codeSent,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined)),
          ),
          if (_codeSent) ...[
            const SizedBox(height: AppSpace.s3),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '6-digit code', prefixIcon: Icon(Icons.pin_outlined)),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpace.s3),
            Text(_error!, style: TextStyle(color: AppColors.adaptive(context, AppColors.blockFg), fontSize: 13)),
          ],
          const SizedBox(height: AppSpace.s4),
          LoadingButton(
            label: _codeSent ? 'Verify & sign in' : 'Send code',
            icon: _codeSent ? Icons.check_circle_outline : Icons.send_outlined,
            busy: _busy,
            onPressed: _codeSent ? _verifyAndLogIn : _requestCode,
          ),
          if (_codeSent) ...[
            const SizedBox(height: AppSpace.s2),
            TextButton(
              onPressed: _busy ? null : () => setState(() => _codeSent = false),
              child: const Text('Use a different email'),
            ),
          ],
        ],
      ),
    );
  }
}
