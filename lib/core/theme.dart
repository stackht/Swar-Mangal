import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Design tokens ported from the shared DesignSystem.html (RC3.12) so the
/// mobile surface keeps the exact visual language of the web apps.
class AppColors {
  AppColors._();

  // light ("warm neutral + navy ink" per the product language)
  static const ink = Color(0xFF1A202C);
  static const muted = Color(0xFF5A6572);
  static const line = Color(0xFFE2E8F0);
  static const pageBg = Color(0xFFF4F6F8);
  static const surface = Color(0xFFFFFFFF);

  static const primary = Color(0xFF9B2C2C); // brand maroon
  static const primaryDark = Color(0xFF7F2323);
  static const focus = Color(0xFF2B6CB0);

  // dark ("deep navy, deliberately designed — not inverted")
  static const dInk = Color(0xFFEDF1F7);
  static const dMuted = Color(0xFF9BA7B6);
  static const dLine = Color(0xFF2A3442);
  static const dPageBg = Color(0xFF0F141D);
  static const dSurface = Color(0xFF161D28);
  static const dSurfaceAlt = Color(0xFF1D2632);

  static const okFg = Color(0xFF22543D);
  static const okBg = Color(0xFFC6F6D5);
  static const dOkFg = Color(0xFF9AE6B4);
  static const dOkBg = Color(0xFF1C3A2B);
  static const warnFg = Color(0xFF7B341E);
  static const warnBg = Color(0xFFFEEBC8);
  static const dWarnFg = Color(0xFFF6C178);
  static const dWarnBg = Color(0xFF3A2A18);
  static const blockFg = Color(0xFF742A2A);
  static const blockBg = Color(0xFFFED7D7);
  static const dBlockFg = Color(0xFFF7A8A8);
  static const dBlockBg = Color(0xFF3B2121);
  static const infoFg = Color(0xFF2A4365);
  static const infoBg = Color(0xFFEBF8FF);
  static const dInfoFg = Color(0xFF90CDF4);
  static const dInfoBg = Color(0xFF132B3B);
}

/// Comfortable touch-first spacing, 4px scale like the web tokens.
class AppSpace {
  AppSpace._();
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 24.0;
  static const s6 = 32.0;
  static const s7 = 48.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final ink = dark ? AppColors.dInk : AppColors.ink;
    final muted = dark ? AppColors.dMuted : AppColors.muted;
    final line = dark ? AppColors.dLine : AppColors.line;
    final bg = dark ? AppColors.dPageBg : AppColors.pageBg;
    final surface = dark ? AppColors.dSurface : AppColors.surface;
    final chipBg = dark ? AppColors.dSurfaceAlt : AppColors.pageBg;
    final blockFg = dark ? AppColors.dBlockFg : AppColors.blockFg;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: dark ? Color(0xFFC65F5F) : AppColors.primary,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      error: blockFg,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.dSurfaceAlt : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: line),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.focus, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          minimumSize: const Size(0, AppSpace.s7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerTheme: DividerThemeData(color: line),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: ink, fontSize: 14, height: 1.45),
        bodySmall: TextStyle(color: muted, fontSize: 12),
        labelLarge: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Theme-mode controller backed by persisted preference.
class ThemeController with ChangeNotifier {
  ThemeController(this._mode);
  ThemeMode _mode;
  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _persist(mode);
  }

  Future<void> toggle() async => setMode(isDark ? ThemeMode.light : ThemeMode.dark);

  Future<void> _persist(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  static Future<ThemeMode> restore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme_mode') == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }
}