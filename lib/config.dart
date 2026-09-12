class AppConfig {
  AppConfig._();

  /// Default back-end target. Overridden at runtime from the Login screen
  /// (gear icon -> "API server"), persisted in shared_preferences.
  /// The Railway gateway answers the same RPC protocol the Apps Script
  /// backend used — no Google Script dependency remains.
  static const String founderExecUrl =
      'https://swarmangal-app-production.up.railway.app/api/rpc';

  static const String staffExecUrl =
      'https://swarmangal-app-production.up.railway.app/api/rpc';

  static const String appVersion = '1.0.0';
  static const String appBuild = 'RC300'; // standalone — no Google Script
  static const String appName = 'Swar Mangal';
}