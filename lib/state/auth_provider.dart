import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config.dart';
import '../core/api.dart';
import '../core/session_storage.dart';
import '../core/url_config.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/demo_api.dart';
import '../services/push_service.dart';

/// App-level session state. One provider drives login/logout for both the
/// founder and staff surfaces; which surface renders is decided by the role
/// the backend reports.
///
/// Session tokens are persisted in flutter_secure_storage (Part 2).
/// Legacy SharedPreferences api_token is migrated once on startup (Part 3).
class AuthProvider extends ChangeNotifier {
  AuthProvider();

  ApiClient? _api;
  ApiService? _service;
  Bootstrap? _boot;
  String? _apiUrl;
  String? _branch;
  bool _demo = false;
  bool _busy = false;
  bool _restoring = false;
  String? _error;

  /// Test seam: subclasses inject a fake ApiClient without network.
  @protected
  ApiClient createClient(String apiUrl, String token) => ApiClient(apiUrl: apiUrl, token: token);

  ApiService? get service => _service;
  Bootstrap? get boot => _boot;
  Operator? get operator => _boot?.operator;
  String? get apiUrl => _apiUrl;
  String? get branch => _branch;
  bool get isLoggedIn => _boot != null && _service != null;
  bool get isDemo => _demo;
  bool get isFounder => _boot?.operator.isFounder ?? false;
  bool get isStaff => _boot?.operator.isStaff ?? false;
  bool get busy => _busy;
  bool get restoring => _restoring;
  String? get error => _error;
  List<String> get branches => _boot?.branches ?? _boot?.operator.branches ?? const [];

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  // -------------------------------------------------- session persistence

  /// Persist endpoint identifier ('founder'/'staff') and API URL.
  /// Token is stored via SessionStorage (secure).
  Future<void> saveSession({required String endpoint, required String apiUrl}) async {
    await SessionStorage.saveEndpoint(endpoint);
    await SessionStorage.saveApiUrl(apiUrl);
  }

  /// Read persisted settings from SessionStorage.
  static Future<({String? url, String? token, String? endpoint})> loadSettings() async {
    final url = await SessionStorage.readApiUrl();
    final endpoint = await SessionStorage.readEndpoint();
    return (url: url, token: null, endpoint: endpoint);
  }

  // -------------------------------------------- restoreSession (Part 5)
  Future<void> restoreSession() async {
    if (_restoring || isLoggedIn) return;
    _restoring = true;
    _error = null;
    notifyListeners();

    try {
      // Part 3: migrate any legacy SharedPreferences token → secure storage.
      final legacyToken = await SessionStorage.migrateLegacyToken();
      if (legacyToken != null && legacyToken.isNotEmpty) {
        // migrated; secure storage now holds it
      }

      final url = await SessionStorage.readApiUrl();
      final token = legacyToken ?? await SessionStorage.readToken();
      final endpoint = await SessionStorage.readEndpoint();

      if (token == null || token.isEmpty || endpoint == null || endpoint.isEmpty) {
        _restoring = false;
        notifyListeners();
        return;
      }

      final v = RpcUrlValidator.validate(url ?? '');
      final effectiveUrl = v.ok && v.url != null ? v.url! : (endpoint == 'staff' ? AppConfig.staffApiUrl : AppConfig.founderApiUrl);

      final api = createClient(effectiveUrl, token);
      final bootMap = await api.call(endpoint == 'staff' ? 'api_staff_boot' : 'api_bootstrap') as Map<String, dynamic>;
      final b = Bootstrap.fromApi(bootMap);
      if (b.operator.role.isEmpty) {
        api.dispose();
        _restoring = false;
        notifyListeners();
        return;
      }
      final svc = ApiService(api);

      _api?.dispose();
      _api = api;
      _service = svc;
      _boot = b;
      _apiUrl = effectiveUrl;
      _demo = false;
      _restoring = false;
      notifyListeners();
      // Fire-and-forget: a restored session re-registers this device's push
      // token (it may have rotated since the app last ran).
      unawaited(PushService.instance.start(svc));
    } catch (e) {
      // Part 6: network/temporary errors keep the token.
      // Only AUTH_FAILED/INVALID_TOKEN clears it.
      final code = (e is ApiException ? e.code : '') ?? '';
      final isAuthFail = code == kErrAuthFailed;
      if (isAuthFail) {
        await SessionStorage.deleteToken();
        await SessionStorage.deleteEndpoint();
        _error = 'Invalid token — credentials cleared.';
      } else {
        _error = 'Unable to connect. Please check your network and retry.';
      }
      _restoring = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------ login
  Future<void> login({
    required String endpoint,
    required String token,
    String? apiUrl,
  }) async {
    if (_busy || _restoring) return; // Part 21: serialize
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      if ((apiUrl ?? '').isEmpty) {
        throw ApiException(
          'No API server set. Enter the gateway URL + token.',
          code: 'NO_API_URL',
        );
      }
      final api = createClient(apiUrl!.trim(), token.trim());
      final bootMap = await api.call(
        endpoint == 'staff' ? 'api_staff_boot' : 'api_bootstrap',
      ) as Map<String, dynamic>;

      final b = Bootstrap.fromApi(bootMap);
      if (b.operator.role.isEmpty) {
        throw ApiException('Backend did not identify the operator.', code: 'NO_ROLE');
      }
      final svc = ApiService(api);

      _api?.dispose();
      _api = api;
      _service = svc;
      _boot = b;
      _apiUrl = apiUrl;
      _demo = false;

      // Persist session (Part 2: token in secure storage; endpoint + URL via saveSession).
      await SessionStorage.saveToken(token.trim());
      await saveSession(endpoint: endpoint, apiUrl: apiUrl.trim());

      notifyListeners();
      unawaited(PushService.instance.start(svc));
    } on ApiException catch (e) {
      if (e.code == kErrAuthFailed || e.code == kErrWrongBackend) {
        await SessionStorage.deleteToken();
      }
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'Unable to connect. Please check your network and retry.';
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------ logout (Part 8)
  Future<void> logout() async {
    final wasDemo = _demo;
    _api?.dispose();
    _api = null;
    _service = null;
    _boot = null;
    _apiUrl = null;
    _branch = null;
    _demo = false;
    await SessionStorage.clearSession();
    notifyListeners();
    // Demo never registered a token (start() is only ever called for a real
    // session), so there is nothing to unregister.
    if (!wasDemo) unawaited(PushService.instance.stop());
  }

  // ---------------------------------------------- branch
  void setBranch(String branch) {
    if (_branch == branch) return;
    _branch = branch;
    notifyListeners();
  }

  // -------------------------------------------------------------- demo (Part 9)
  /// Offline demo session — memory only. Never persisted.
  Future<void> demoLogin({required bool founder}) async {
    if (_busy || _restoring) return;
    final api = DemoApiClient();
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final boot = founder
          ? Bootstrap.fromApi(await api.call('api_bootstrap') as Map<String, dynamic>)
          : Bootstrap.fromApi(await api.call('api_staff_boot') as Map<String, dynamic>);
      _api?.dispose();
      _api = api;
      _service = ApiService(api);
      _boot = boot;
      _demo = true;
      _apiUrl = null;
      // Part 9: do NOT persist demo credentials.
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}