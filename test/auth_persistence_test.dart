import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swar_mangal/core/api.dart';
import 'package:swar_mangal/core/session_storage.dart';
import 'package:swar_mangal/state/auth_provider.dart';

const prodUrl = 'https://swarmangal-app-production.up.railway.app/api/rpc';

/// Fake ApiClient that returns canned boot payloads or throws a configurable
/// error. No network.
class FakeApiClient extends ApiClient {
  FakeApiClient({this.errorFor, this.bootFor})
      : super(apiUrl: prodUrl, token: 'x');

  final Exception? errorFor;
  final List<String>? bootFor; // ['staff'|'founder']

  @override
  Future<dynamic> call(String api, [Object? arg]) async {
    if (errorFor != null) throw errorFor!;
    final isStaff = api == 'api_staff_boot';
    return jsonDecode(
      jsonEncode({
        'ok': true,
        'email': isStaff ? 'smmahavirnagar@gmail.com' : 'sharvil87@gmail.com',
        'role': isStaff ? 'OPS_USER' : 'FOUNDER_ADMIN',
        'name': isStaff ? 'Latika' : 'Sharvil',
        'isOpsAccount': isStaff,
        'branches': ['GOREGAON', 'KANDIVALI'],
        'accounts': ['Cash', 'UPI'],
        'paymentModes': ['Cash', 'UPI'],
        'planTypes': ['Monthly'],
        'classCodes': ['GMC', 'KMC'],
      }),
    ) as Map<String, dynamic>;
  }
}

class TestAuthProvider extends AuthProvider {
  TestAuthProvider({this.errorFor, this.bootFor});
  final Exception? errorFor;
  final List<String>? bootFor;

  @override
  ApiClient createClient(String execUrl, String token) =>
      FakeApiClient(errorFor: errorFor, bootFor: bootFor);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<String?> storedToken() => SessionStorage.readToken();

  group('restoreSession — founder', () {
    test('restores founder without login screen', () async {
      await SessionStorage.saveToken('founder-tok');
      await SessionStorage.saveEndpoint('founder');
      await SessionStorage.saveApiUrl(prodUrl);
      final provider = TestAuthProvider();

      await provider.restoreSession();

      expect(provider.isLoggedIn, isTrue);
      expect(provider.isFounder, isTrue);
      expect(provider.isStaff, isFalse);
      expect(provider.busy, isFalse);
    });
  });

  group('restoreSession — staff', () {
    test('restores staff after app restart', () async {
      await SessionStorage.saveToken('staff-tok');
      await SessionStorage.saveEndpoint('staff');
      await SessionStorage.saveApiUrl(prodUrl);
      final provider = TestAuthProvider();

      await provider.restoreSession();

      expect(provider.isLoggedIn, isTrue);
      expect(provider.isStaff, isTrue);
    });
  });

  group('restoreSession — no stored token', () {
    test('stays logged out, no error', () async {
      final provider = TestAuthProvider();
      await provider.restoreSession();
      expect(provider.isLoggedIn, isFalse);
      expect(provider.error, isNull);
    });
  });

  group('network failure keeps token', () {
    test('DNS/unreachable error does not delete stored token', () async {
      await SessionStorage.saveToken('keep-tok');
      await SessionStorage.saveEndpoint('staff');
      await SessionStorage.saveApiUrl(prodUrl);
      final provider = TestAuthProvider(errorFor: ApiUnreachable('offline'));

      await provider.restoreSession();

      expect(provider.isLoggedIn, isFalse);
      expect(provider.error, isNotNull);
      expect(await storedToken(), 'keep-tok'); // token survives
    });
  });

  group('auth failure clears token', () {
    test('AUTH_FAILED deletes secure token', () async {
      await SessionStorage.saveToken('bad-tok');
      await SessionStorage.saveEndpoint('staff');
      await SessionStorage.saveApiUrl(prodUrl);
      final provider = TestAuthProvider(
          errorFor: ApiException('Invalid token', code: 'AUTH_FAILED'));

      await provider.restoreSession();

      expect(provider.isLoggedIn, isFalse);
      expect(await storedToken(), isNull);
    });
  });

  group('logout', () {
    test('clears token + endpoint, keeps API URL', () async {
      await SessionStorage.saveToken('tok');
      await SessionStorage.saveEndpoint('founder');
      await SessionStorage.saveApiUrl(prodUrl);
      final provider = TestAuthProvider();
      await provider.restoreSession();
      expect(provider.isLoggedIn, isTrue);

      await provider.logout();

      expect(provider.isLoggedIn, isFalse);
      expect(await storedToken(), isNull);
      expect(await SessionStorage.readEndpoint(), isNull);
      expect(await SessionStorage.readApiUrl(), prodUrl);
    });
  });

  group('demo login is never persisted', () {
    test('demoLogin memory-only', () async {
      final provider = TestAuthProvider();
      await provider.demoLogin(founder: true);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.isDemo, isTrue);
      expect(await storedToken(), isNull);
      expect(await SessionStorage.readEndpoint(), isNull);
    });
  });

  group('restart survives', () {
    test('founder token restored in a fresh provider instance', () async {
      await SessionStorage.saveToken('tok-f');
      await SessionStorage.saveEndpoint('founder');
      await SessionStorage.saveApiUrl(prodUrl);

      final first = TestAuthProvider();
      await first.restoreSession();
      expect(first.isFounder, isTrue);

      // Simulate app restart: brand new provider, same secure storage.
      final second = TestAuthProvider();
      await second.restoreSession();
      expect(second.isFounder, isTrue);
      expect(second.isLoggedIn, isTrue);
    });
  });
}