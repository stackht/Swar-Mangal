import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swar_mangal/core/session_storage.dart';
import 'package:swar_mangal/core/url_config.dart';

void main() {
  const token = 'test-founder-token';
  const url = 'https://swarmangal-app-production.up.railway.app/api/rpc';

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('SessionStorage — token in secure store', () {
    test('saveToken/readToken round-trips', () async {
      await SessionStorage.saveToken(token);
      expect(await SessionStorage.readToken(), token);
    });

    test('deleteToken clears', () async {
      await SessionStorage.saveToken(token);
      await SessionStorage.deleteToken();
      expect(await SessionStorage.readToken(), isNull);
    });
  });

  group('SessionStorage — endpoint', () {
    test('saveEndpoint/readEndpoint', () async {
      await SessionStorage.saveEndpoint('staff');
      expect(await SessionStorage.readEndpoint(), 'staff');
    });
    test('deleteEndpoint clears', () async {
      await SessionStorage.saveEndpoint('founder');
      await SessionStorage.deleteEndpoint();
      expect(await SessionStorage.readEndpoint(), isNull);
    });
  });

  group('SessionStorage — API URL in prefs (non-sensitive)', () {
    test('saveApiUrl/readApiUrl', () async {
      await SessionStorage.saveApiUrl(url);
      expect(await SessionStorage.readApiUrl(), url);
    });
  });

  group('Legacy token migration', () {
    test('migrates legacy SharedPreferences api_token to secure store', () async {
      SharedPreferences.setMockInitialValues({'api_token': 'legacy-token'});
      FlutterSecureStorage.setMockInitialValues({});

      final migrated = await SessionStorage.migrateLegacyToken();
      expect(migrated, 'legacy-token');

      // Now in secure store, gone from prefs.
      expect(await SessionStorage.readToken(), 'legacy-token');
      final p = await SharedPreferences.getInstance();
      expect(p.getString('api_token'), isNull);
    });

    test('no-op when no legacy token', () async {
      final migrated = await SessionStorage.migrateLegacyToken();
      expect(migrated, isNull);
      expect(await SessionStorage.readToken(), isNull);
    });
  });

  group('clearSession', () {
    test('removes token + endpoint + legacy prefs', () async {
      SharedPreferences.setMockInitialValues({'api_token': 'old'});
      FlutterSecureStorage.setMockInitialValues({});
      await SessionStorage.saveToken(token);
      await SessionStorage.saveEndpoint('founder');
      await SessionStorage.saveApiUrl(url);

      await SessionStorage.clearSession();

      expect(await SessionStorage.readToken(), isNull);
      expect(await SessionStorage.readEndpoint(), isNull);
      final p = await SharedPreferences.getInstance();
      expect(p.getString('api_token'), isNull);
      // API URL deliberately kept — logout keeps URL.
      expect(await SessionStorage.readApiUrl(), url);
    });
  });

  group('RpcUrlValidator', () {
    test('rejects placeholder', () {
      final r = RpcUrlValidator.validate('https://script.google.com/macros/s/REPLACE_WITH/exec');
      expect(r.ok, isFalse);
    });
    test('rejects /exec', () {
      expect(RpcUrlValidator.validate('https://x.com/macros/s/abc/exec').ok, isFalse);
    });
    test('rejects non-https', () {
      expect(RpcUrlValidator.validate('http://x.com/api/rpc').ok, isFalse);
    });
    test('accepts production /api/rpc', () {
      expect(RpcUrlValidator.validate(url).ok, isTrue);
    });
    test('rejects URL not ending /api/rpc', () {
      expect(RpcUrlValidator.validate('https://x.com/other').ok, isFalse);
    });
  });
}