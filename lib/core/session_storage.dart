import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure token storage abstraction backed by flutter_secure_storage.
/// Tokens never leave this layer — all accesses log nothing.
class SessionStorage {
  SessionStorage._();

  static const FlutterSecureStorage _secure = FlutterSecureStorage();
  static const _kTokenKey = 'sm_api_token';
  static const _kEndpointKey = 'sm_auth_endpoint'; // 'founder' | 'staff'

  // ---------------------------------------------------------------- Token
  static Future<void> saveToken(String token) async {
    await _secure.write(key: _kTokenKey, value: token);
  }

  static Future<String?> readToken() async {
    return _secure.read(key: _kTokenKey);
  }

  static Future<void> deleteToken() async {
    await _secure.delete(key: _kTokenKey);
  }

  // -------------------------------------------------------------- Endpoint
  static Future<void> saveEndpoint(String endpoint) async {
    await _secure.write(key: _kEndpointKey, value: endpoint);
  }

  static Future<String?> readEndpoint() async {
    return _secure.read(key: _kEndpointKey);
  }

  static Future<void> deleteEndpoint() async {
    await _secure.delete(key: _kEndpointKey);
  }

  // -------------------------------------------------------- API URL (Prefs)
  // Non-sensitive; stored in SharedPreferences for simplicity.
  static const _kApiUrlKey = 'exec_url';

  static Future<void> saveApiUrl(String url) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kApiUrlKey, url);
  }

  static Future<String?> readApiUrl() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kApiUrlKey);
  }

  static Future<void> deleteApiUrl() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kApiUrlKey);
  }

  // ---------------------------------------------------- Legacy Migration
  /// One-time migration of `api_token` from SharedPreferences → secure storage.
  /// Returns the migrated token (if any) after migration.
  static Future<String?> migrateLegacyToken() async {
    final p = await SharedPreferences.getInstance();
    final legacy = p.getString('api_token');
    if (legacy == null || legacy.isEmpty) return null;

    // Legacy token exists in prefs, migrate to secure storage.
    try {
      await _secure.write(key: _kTokenKey, value: legacy);
    } catch (_) {
      debugPrint('SessionStorage: legacy token migration failed');
      return null;
    }

    // Remove from prefs once it is safely in secure storage.
    await p.remove('api_token');
    return legacy;
  }

  /// Full logout: clear token + endpoint + legacy prefs key (if somehow still there).
  static Future<void> clearSession() async {
    await _secure.delete(key: _kTokenKey);
    await _secure.delete(key: _kEndpointKey);
    final p = await SharedPreferences.getInstance();
    await p.remove('api_token');
  }
}
