import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/demo_api.dart';

/// App-level session state. One provider drives login/logout for both the
/// founder and staff surfaces; which surface renders is decided by the role
/// the backend reports.
class AuthProvider extends ChangeNotifier {
  AuthProvider();

  ApiClient? _api;
  ApiService? _service;
  Bootstrap? _boot;
  String? _execUrl;
  String? _branch;
  bool _demo = false;
  bool _busy = false;
  String? _error;

  ApiService? get service => _service;
  Bootstrap? get boot => _boot;
  Operator? get operator => _boot?.operator;
  String? get execUrl => _execUrl;
  String? get branch => _branch;
  bool get isLoggedIn => _boot != null && _service != null;
  bool get isDemo => _demo;
  bool get isFounder => _boot?.operator.isFounder ?? false;
  bool get isStaff => _boot?.operator.isStaff ?? false;
  bool get busy => _busy;
  String? get error => _error;
  List<String> get branches => _boot?.branches ?? _boot?.operator.branches ?? const [];

  /// Persist a custom API server so CAAS previews / dev deploys can be used.
  static Future<void> saveSettings({String? execUrl, String? token}) async {
    final p = await SharedPreferences.getInstance();
    if (execUrl != null && execUrl.isNotEmpty) await p.setString('exec_url', execUrl);
    if (token != null) await p.setString('api_token', token);
  }

  static Future<({String? url, String? token})> loadSettings() async {
    final p = await SharedPreferences.getInstance();
    return (url: p.getString('exec_url'), token: p.getString('api_token'));
  }

  Future<void> login({
    required String endpoint, // 'founder' | 'staff'
    required String token,
    String? execUrl,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      if ((execUrl ?? '').isEmpty) {
        throw ApiException(
            'No API server set. Open the gear icon on the Login screen and '
            'enter the deployment URL + token issued by the founder.',
            code: 'NO_EXEC_URL');
      }
      final api = ApiClient(execUrl: execUrl!.trim(), token: token.trim());
      ApiService svc;
      Map<String, dynamic> boot;
      try {
        if (endpoint == 'staff') {
          boot = (await api.call('api_staff_boot')) as Map<String, dynamic>;
        } else {
          boot = (await api.call('api_bootstrap')) as Map<String, dynamic>;
        }
      } on ApiException catch (e) {
        if (e.code == 'BAD_BODY' || e.code == 'HTTP_404') {
          throw ApiException(
            'Backend did not answer as an AcademyOS app. $execUrl looks like '
            'the wrong deployment URL.',
            code: 'WRONG_BACKEND',
          );
        }
        rethrow;
      }
      svc = ApiService(api);
      final b = Bootstrap.fromApi(boot);
      if (b.operator.role.isEmpty) {
        throw ApiException('Backend did not identify the operator.', code: 'NO_ROLE');
      }
      _api?.dispose();
      _api = api;
      _service = svc;
      _boot = b;
      _execUrl = execUrl;
      await saveSettings(execUrl: execUrl, token: token);
      notifyListeners();
    } catch (e) {
      _error = e is ApiException ? e.message : '$e';
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void setBranch(String branch) {
    if (_branch == branch) return;
    _branch = branch;
    notifyListeners();
  }

  /// Offline demo session — same boot + service flow, backed by canned data.
  Future<void> demoLogin({required bool founder}) async {
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
      _execUrl = null;
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _api?.dispose();
    _api = null;
    _service = null;
    _boot = null;
    _execUrl = null;
    _branch = null;
    _demo = false;
    notifyListeners();
  }
}