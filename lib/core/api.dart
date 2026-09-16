import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Classification codes surfaced to the login screen so the user knows what
/// to fix instead of a raw "could not reach server".
const kErrInvalidConfig = 'INVALID_CONFIG';
const kErrNetworkUnreachable = 'NETWORK_UNREACHABLE';
const kErrHttpError = 'HTTP_ERROR';
const kErrWrongBackend = 'WRONG_BACKEND';
const kErrAuthFailed = 'AUTH_FAILED';
const kErrRoleForbidden = 'ROLE_FORBIDDEN';
const kErrBranchForbidden = 'BRANCH_FORBIDDEN';
const kErrBackend = 'BACKEND_ERROR';

/// Thrown for any non-`ok` response from the gateway backend, or transport
/// failure. Keeps a classification [code] for UI hints.
class ApiException implements Exception {
  ApiException(this.message, {this.code, this.payload});

  final String message;
  final String? code;
  final Map<String, dynamic>? payload;

  @override
  String toString() => code == null ? message : '$message [$code]';
}

/// Transport failure (offline, unreachable, timeout, DNS).
class ApiUnreachable implements Exception {
  ApiUnreachable(this.message, {this.code = kErrNetworkUnreachable});
  final String message;
  final String code;
  @override
  String toString() => message;
}

const _timeout = Duration(seconds: 45);

/// One client instance per login session. All `api_*` calls go through here
/// as posts to the Railway gateway `/api/rpc`.
class ApiClient {
  ApiClient({required this.apiUrl, required this.token}) {
    _http = http.Client();
  }

  final String apiUrl;
  final String token;
  late final http.Client _http;

  /// Posts `function=<api>` + `arg=<json>` to the gateway and returns the
  /// server body decoded. Non-{ok:true} responses throw [ApiException].
  Future<dynamic> call(String api, [Object? arg]) async {
    final body = <String, String>{
      'function': api,
      if (token.isNotEmpty) 'token': token,
      if (arg != null) 'arg': jsonEncode(arg),
    };
    final http.Response resp;
    try {
      resp = await _http
          .post(Uri.parse(apiUrl), body: body, headers: const {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          })
          .timeout(_timeout);
    } on TimeoutException {
      throw ApiUnreachable('Server timed out. Check your connection and retry.');
    } catch (e) {
      // Keep the underlying detail (DNS/socket/TLS) so the login screen can
      // tell the user exactly which host/port failed. Safety: the exception
      // text never contains the device token.
      throw ApiUnreachable(
        'Could not reach server. Check your connection and that the gateway '
        'URL is correct.\nDetail: $e',
      );
    }
    if (resp.statusCode != 200) {
      throw ApiException('Server returned HTTP ${resp.statusCode}.',
          code: kErrHttpError);
    }
    dynamic data;
    try {
      data = jsonDecode(resp.body);
    } catch (_) {
      throw ApiException(
          'Server answered in an unexpected format. Wrong backend URL '
          '(${apiUrl.replaceFirst(RegExp(r'https?://'), '')})?',
          code: kErrWrongBackend);
    }
    if (data is! Map<String, dynamic>) {
      throw ApiException('Unexpected server payload.', code: kErrWrongBackend);
    }
    if (data['ok'] == true) return data;
    // Classify the backend refusal.
    final code = (data['code'] ?? data['reason'] ?? '').toString();
    final msg = (data['error'] ?? 'Request failed.').toString();
    throw ApiException(msg, code: _classify(code), payload: data);
  }

  String _classify(String code) {
    final upper = code.toUpperCase();
    if (upper.contains('UNAUTHORIZED') || upper.contains('INVALID_TOKEN') || upper.contains('AUTH_FAILED')) {
      return kErrAuthFailed;
    }
    if (upper.contains('ROLE') || upper.contains('FORBIDDEN') && upper.contains('FOUNDER')) {
      return kErrRoleForbidden;
    }
    if (upper.contains('BRANCH') || upper.contains('BRANCH_FORBIDDEN')) {
      return kErrBranchForbidden;
    }
    if (upper.contains('BAD_BODY') || upper.contains('BAD_SHAPE') || upper.contains('WRONG_BACKEND')) {
      return kErrWrongBackend;
    }
    return kErrBackend;
  }

  void dispose() => _http.close();
}