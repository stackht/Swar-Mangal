import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api.dart';

/// Self-service token registration/reset. Plain HTTP POSTs to
/// `/api/auth/otp/*` — not through [ApiClient], since no device token exists
/// yet at this point. Same [ApiException]/[ApiUnreachable] error shapes as
/// the rest of the app for consistent handling on screen.
class EmailAuthService {
  const EmailAuthService();

  static const _timeout = Duration(seconds: 30);

  /// Strips the `/api/rpc` suffix from an already-validated gateway URL to
  /// get the base the OTP routes hang off.
  static String _baseFrom(String rpcUrl) {
    const suffix = '/api/rpc';
    return rpcUrl.endsWith(suffix) ? rpcUrl.substring(0, rpcUrl.length - suffix.length) : rpcUrl;
  }

  Future<Map<String, dynamic>> _post(String rpcUrl, String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${_baseFrom(rpcUrl)}$path');
    http.Response res;
    try {
      res = await http
          .post(uri, headers: const {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(_timeout);
    } catch (_) {
      throw ApiUnreachable('Could not reach the server. Check your connection.');
    }
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('The server sent back something unexpected.', code: kErrHttpError);
    }
    if (decoded['ok'] != true) {
      throw ApiException((decoded['error'] ?? 'Could not complete this step.').toString());
    }
    return decoded;
  }

  /// role: 'FOUNDER_ADMIN' | 'OPS_USER'. purpose: 'REGISTER' | 'RESET'.
  Future<void> requestOtp({
    required String rpcUrl,
    required String email,
    required String role,
    required String purpose,
  }) =>
      _post(rpcUrl, '/api/auth/otp/request', {'email': email, 'role': role, 'purpose': purpose});

  /// Returns the freshly-issued plaintext device token on success.
  Future<String> verifyOtp({
    required String rpcUrl,
    required String email,
    required String role,
    required String purpose,
    required String code,
  }) async {
    final b = await _post(rpcUrl, '/api/auth/otp/verify', {
      'email': email,
      'role': role,
      'purpose': purpose,
      'code': code,
    });
    return (b['token'] ?? '').toString();
  }
}
