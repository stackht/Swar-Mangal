import '../config.dart';

/// Validates a production gateway URL for the Swar Mangal APK.
///
/// Rules:
///  - non-empty, whitespace-trimmed
///  - must be https
///  - must end with the RPC endpoint path (currently `/api/rpc`)
///  - must NOT contain a script.google.com /placeholder deployment
///  - must NOT contain the literal placeholder marker `REPLACE_WITH`
///
/// Returns a validation result rather than throwing, so the login screen can
/// tell the user exactly what to fix.
class ExecUrlValidator {
  ExecUrlValidator._();

  static bool _looksPlaceholder(String url) {
    final lower = url.toLowerCase();
    return lower.contains('replace_with') ||
        lower.contains('script.google.com') ||
        lower.contains('macro/s/') ||
        lower.contains('/exec');
  }

  /// Normalize: trim, reject placeholders/malformed, enforce https + RPC path.
  /// Returns `(ok, url?, error)`.
  static ({bool ok, String? url, String? error}) validate(String raw) {
    final url = raw.trim();
    if (url.isEmpty) return (ok: false, url: null, error: 'Empty URL.');
    if (_looksPlaceholder(url)) {
      return (ok: false, url: null, error: 'This URL is a placeholder, not a real backend.');
    }
    final lower = url.toLowerCase();
    if (!lower.startsWith('https://')) {
      return (ok: false, url: null, error: 'URL must start with https://');
    }
    if (lower.contains(' ')) {
      return (ok: false, url: null, error: 'URL contains spaces — trim it.');
    }
    if (!RegExp(r'https://[a-z0-9.\-]+(/[a-z0-9/_.\-]*)?$').hasMatch(lower)) {
      return (ok: false, url: null, error: 'URL looks malformed.');
    }
    if (!lower.endsWith('/api/rpc')) {
      return (ok: false, url: null, error: 'URL must point at the /api/rpc gateway.');
    }
    return (ok: true, url: url, error: null);
  }

  static bool isValid(String raw) => validate(raw).ok;
}

/// Resolves the effective production URL:
/// 1. a persisted custom URL, IF it passes validation;
/// 2. otherwise the configured production URL (AppConfig).
/// Never silently uses an invalid/placeholder persisted URL.
String resolveEffectiveUrl({String? persistedUrl, required bool staff}) {
  if (persistedUrl != null && persistedUrl.trim().isNotEmpty) {
    final v = ExecUrlValidator.validate(persistedUrl);
    if (v.ok && v.url != null) return v.url!;
  }
  return staff ? AppConfig.staffExecUrl : AppConfig.founderExecUrl;
}