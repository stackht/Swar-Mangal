import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown for any non-`ok` response from the Apps Script backend,
/// or transport failure. Keeps the [code] from the server for UI hints.
class ApiException implements Exception {
  ApiException(this.message, {this.code, this.payload});

  final String message;
  final String? code;
  final Map<String, dynamic>? payload;

  @override
  String toString() => code == null ? message : '$message [$code]';
}

/// Transport failure (offline, unreachable, timeout).
class ApiUnreachable implements Exception {
  ApiUnreachable(this.message);
  final String message;
  @override
  String toString() => message;
}

const _timeout = Duration(seconds: 45);

/// One client instance per login session. All `api_*` calls go through here
/// as posts to the Railway gateway `/api/rpc`.
class ApiClient {
  ApiClient({required this.execUrl, required this.token}) {
    _http = http.Client();
  }

  final String execUrl;
  final String token;
  late final http.Client _http;

  /// Posts `function=<api>` + `arg=<json>` to the web app and returns the
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
          .post(Uri.parse(execUrl), body: body, headers: const {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          })
          .timeout(_timeout);
    } on TimeoutException {
      throw ApiUnreachable('Server timed out. Check your connection and retry.');
    } catch (e) {
      throw ApiUnreachable('Could not reach server. $e');
    }
    if (resp.statusCode != 200) {
      throw ApiException('Server returned HTTP ${resp.statusCode}.',
          code: 'HTTP_${resp.statusCode}');
    }
    dynamic data;
    try {
      data = jsonDecode(resp.body);
    } catch (_) {
      throw ApiException(
          'Server answered in an unexpected format. Wrong backend URL '
          '(${execUrl.replaceFirst(RegExp(r'https?://'), '')})?',
          code: 'BAD_BODY');
    }
    if (data is! Map<String, dynamic>) {
      throw ApiException('Unexpected server payload.', code: 'BAD_SHAPE');
    }
    if (data['ok'] == true) return data;
    throw ApiException(
        (data['error'] ?? (data['reason'] ?? 'Request failed.')).toString(),
        code: (data['code'] ?? data['reason'] ?? '').toString(),
        payload: data);
  }

  void dispose() => _http.close();
}