import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
/// SWAR MANGAL — brand identity (v2)
/// Apple Music × spatial design × premium Indian classical academy.
///
/// Palette story (design north star):
///   Ivory    — warm light canvas, never sterile white
///   Charcoal — near-black warm canvas for night ("studio at night"), never
///              purple- or blue-black
///   Saffron  — primary brand accent (actions, active states, practice)
///   Indigo   — secondary (learning, navigation, analytics)
///   Emerald  — progress / success
///   Coral    — attention / warnings (sparingly)
///   Red      — destructive only
///
/// Neutral bias: ~80% neutral surfaces, ~12% secondary, ~8% accent.
/// Color communicates meaning — not decoration.
/// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
class AppColors {
  AppColors._();

  // Light canvas — warm ivory.
  static const pageBg = Color(0xFFF5F1E8); // warm ivory canvas
  static const surface = Color(0xFFFFFDF8); // soft ivory surface
  static const surfaceAlt = Color(0xFFECE6D9); // grouping surface
  static const line = Color(0xFFE5DFD2); // warm hairline

  // Ink — warm charcoal typography.
  static const ink = Color(0xFF22242A);
  static const muted = Color(0xFF6E6A61);

  // Brand accents.
  static const primary = Color(0xFFE8890C); // saffron — primary actions
  static const primaryLight = Color(0xFFF3A712);
  static const primaryDark = Color(0xFFC26E09); // deep amber for rails/app bars
  static const focus = Color(0xFF3A4BC8); // deep indigo — knowledge/nav

  // Semantic (light).
  static const okFg = Color(0xFF166A4C);
  static const okBg = Color(0xFFDCF2E6);
  static const warnFg = Color(0xFF9A5B13);
  static const warnBg = Color(0xFFFBEFD9);
  static const blockFg = Color(0xFFB42318);
  static const blockBg = Color(0xFFFDE9E6);
  static const infoFg = Color(0xFF2D3FA3);
  static const infoBg = Color(0xFFE9EDFC);

  // Dark canvas — warm near-black charcoal ("studio at night").
  static const dPageBg = Color(0xFF110F0C);
  static const dSurface = Color(0xFF191612);
  static const dSurfaceAlt = Color(0xFF221E18);
  static const dLine = Color(0xFF2E2922);
  static const dInk = Color(0xFFF4EFE6);
  static const dMuted = Color(0xFFA39A8C);

  // Dark semantics — deliberately desaturated, never neon.
  static const dPrimary = Color(0xFFF2A93B);
  static const dFocus = Color(0xFF8D9CF0);
  static const dOkFg = Color(0xFF9FD9BB);
  static const dOkBg = Color(0xFF1B3227);
  static const dWarnFg = Color(0xFFE8B468);
  static const dWarnBg = Color(0xFF332819);
  static const dBlockFg = Color(0xFFF0938C);
  static const dBlockBg = Color(0xFF341F1D);
  static const dInfoFg = Color(0xFF9DABF5);
  static const dInfoBg = Color(0xFF1E2338);
}

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

/// Radius scale — consistent but varied, breaking the flat identical-rectangle
/// monotony. Buttons/inputs share the small step; cards a medium step; hero
/// compositions a large step; pills/avatars are fully round.
class AppRadius {
  AppRadius._();
  static const s = 12.0; // buttons, inputs
  static const m = 20.0; // cards
  static const l = 28.0; // hero sections
  static const pill = 999.0;
}

/// Typography scale — editorial tone: confident displays, quiet metadata.
class AppType {
  AppType._();
  static const eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.6,
  );
  static const display = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.15);
  static const title = TextStyle(fontSize: 17, fontWeight: FontWeight.w700);
  static const body = TextStyle(fontSize: 14, height: 1.45);
  static const small = TextStyle(fontSize: 12);
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
    final chipBg = dark ? AppColors.dSurfaceAlt : AppColors.surfaceAlt;
    final primary = dark ? AppColors.dPrimary : AppColors.primary;
    final blockFg = dark ? AppColors.dBlockFg : AppColors.blockFg;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: primary,
      secondary: dark ? AppColors.dFocus : AppColors.focus,
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
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: AppType.title.copyWith(color: ink),
        iconTheme: IconThemeData(color: ink),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: BorderSide(color: line),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s3 + 4, vertical: 13),
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted.withValues(alpha: .7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: BorderSide(
            color: dark ? AppColors.dPrimary : AppColors.primary,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: const BorderSide(color: AppColors.blockFg),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        labelStyle: TextStyle(color: ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: dark ? const Color(0xFF261A08) : Colors.white,
          minimumSize: const Size(0, AppSpace.s7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? AppColors.dSurfaceAlt : AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
      ),
      dividerTheme: DividerThemeData(color: line),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      textTheme: TextTheme(
        bodyMedium: AppType.body.copyWith(color: ink),
        bodySmall: AppType.small.copyWith(color: muted),
        labelLarge: const TextStyle(fontWeight: FontWeight.w800),
        headlineMedium: AppType.display.copyWith(color: ink),
        titleMedium: AppType.title.copyWith(color: ink),
      ),
    );
  }
}

/// Theme-mode controller — persisted, restored on boot.
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