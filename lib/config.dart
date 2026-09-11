class AppConfig {
  AppConfig._();

  /// Default back-end target. Overridden at runtime from the Login screen
  /// (gear icon -> "API server"), persisted in shared_preferences.
  static const String founderExecUrl =
      'https://script.google.com/macros/s/REPLACE_WITH_FOUNDER_SCRIPT_ID/exec';

  static const String staffExecUrl =
      'https://script.google.com/macros/s/REPLACE_WITH_STAFF_SCRIPT_ID/exec';

  static const String appVersion = '1.0.0';
  static const String appBuild = 'RC201'; // 2 apps, 0 external, 1 gateway
  static const String appName = 'Swar Mangal';
}