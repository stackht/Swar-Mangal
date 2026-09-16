import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
/// SWAR MANGAL — premium design system
///
/// Deep-navy sidebar, soft off-white canvas, white elevated cards, and a
/// restrained lavender/violet accent. 70% neutral ~ 20% navy ~ 8% accent ~ 2%
/// semantic colors. Premium means hierarchy and restraint, not more effects.
/// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
class AppColors {
  AppColors._();

  // Light canvas — soft off-white.
  static const background = Color(0xFFF7F8FC);
  static const pageBg = background; // alias for existing callers
  static const surface = Color(0xFFFFFFFF); // cards
  static const surfaceAlt = Color(0xFFF2F3FA); // grouping / tinted headers
  static const line = Color(0xFFE7E9F0); // hairline borders
  static const border = line; // alias

  // Ink — primary text.
  static const ink = Color(0xFF151A2D);
  static const textPrimary = ink; // alias
  static const muted = Color(0xFF667085);
  static const textSecondary = muted; // alias

  // Brand accents — restrained lavender/violet.
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF7C70FF);
  static const secondaryAccent = Color(0xFF8B7CFF);
  static const lavenderSoft = Color(0xFFEEECFF);
  static const focus = Color(0xFF6C63FF);

  // Deep navy — sidebar / dark surfaces.
  static const navy = Color(0xFF111827);
  static const primaryDark = Color(0xFF172033);

  // Semantic (light).
  static const mint = Color(0xFFDDF7EF);
  static const vsuccess = Color(0xFF16A37A);
  static const success = vsuccess;
  static const gold = Color(0xFFE7B86A);
  static const warnFg = Color(0xFFD99A24);
  static const blockFg = Color(0xFFD95C5C);
  static const error = blockFg;
  static const okFg = vsuccess;

  // Semantic backgrounds (soft).
  static const okBg = Color(0xFFDDF7EF);
  static const warnBg = Color(0xFFFBF2E0);
  static const blockBg = Color(0xFFFDECEC);
  static const infoBg = Color(0xFFEEECFF);
  static const infoFg = Color(0xFF6C63FF);

  // Dark variant — deep navy canvas ("studio at night").
  static const dPageBg = Color(0xFF0F1420);
  static const dSurface = Color(0xFF172033);
  static const dSurfaceAlt = Color(0xFF1F2A40);
  static const dLine = Color(0xFF2A3550);
  static const dInk = Color(0xFFF1F3FA);
  static const dMuted = Color(0xFFAEB7CC);

  // Dark semantics.
  static const dPrimary = Color(0xFF8B7CFF);
  static const dFocus = Color(0xFFA99EFF);
  static const dOkFg = Color(0xFF5CD6AE);
  static const dOkBg = Color(0xFF12352A);
  static const dWarnFg = Color(0xFFF0C078);
  static const dWarnBg = Color(0xFF332B1A);
  static const dBlockFg = Color(0xFFF0807E);
  static const dBlockBg = Color(0xFF3A2323);
  static const dInfoFg = Color(0xFFB3A8FF);
  static const dInfoBg = Color(0xFF222138);
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

/// Central radius system. Small=8 · input/button=12 · card=16 · hero=20.
class AppRadius {
  AppRadius._();
  static const small = 8.0;
  static const s = 12.0; // buttons, inputs (alias)
  static const button = s;
  static const input = s;
  static const card = 16.0;
  static const m = card; // alias
  static const large = 20.0;
  static const l = large; // alias
  static const pill = 999.0;
}

/// Central shadow system — soft, low, never heavy black.
class AppShadows {
  AppShadows._();

  static const subtle = BoxShadow(
    color: Color(0x0D151A2D),
    blurRadius: 6,
    offset: Offset(0, 1),
  );

  static const card = BoxShadow(
    color: Color(0x0F151A2D),
    blurRadius: 14,
    offset: Offset(0, 3),
  );

  static const dialog = BoxShadow(
    color: Color(0x24151A2D),
    blurRadius: 32,
    offset: Offset(0, 12),
  );

  static const hover = BoxShadow(
    color: Color(0x1A151A2D),
    blurRadius: 20,
    offset: Offset(0, 6),
  );
}

/// Central gradients — accent usage only.
class AppGradients {
  AppGradients._();

  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF7C70FF)],
  );

  static const primaryStrong = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5F57E8), Color(0xFF8378FF)],
  );

  /// Flowing atmosphere blobs for the app background.
  static const blobLavender = RadialGradient(
    radius: 0.9,
    colors: [Color(0x666C63FF), Color(0x006C63FF)],
  );
  static const blobMint = RadialGradient(
    radius: 0.9,
    colors: [Color(0x335CD6AE), Color(0x005CD6AE)],
  );
}

class AppType {
  AppType._();
  static const eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.6,
  );
  static const display = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.15);
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2);
  static const h2 = TextStyle(fontSize: 19, fontWeight: FontWeight.w600, height: 1.25);
  static const title = TextStyle(fontSize: 17, fontWeight: FontWeight.w700);
  static const cardTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 14, height: 1.45);
  static const small = TextStyle(fontSize: 12);
  static const caption = TextStyle(fontSize: 11);
  static const numbers = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );
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
    final bg = dark ? AppColors.dPageBg : AppColors.background;
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
        iconTheme: IconThemeData(color: muted),
        shape: Border(bottom: BorderSide(color: line)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shadowColor: AppShadows.subtle.color,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
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
        prefixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.blockFg),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.blockFg, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        labelStyle: TextStyle(color: ink),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, AppSpace.s7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .1),
          elevation: 0,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surface,
        elevation: 0,
        contentTextStyle: TextStyle(color: ink, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          side: BorderSide(color: line),
        ),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: line),
        ),
        shadowColor: AppShadows.dialog.color,
        elevation: 0,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(),
      textTheme: TextTheme(
        bodyMedium: AppType.body.copyWith(color: ink),
        bodySmall: AppType.small.copyWith(color: muted),
        labelLarge: const TextStyle(fontWeight: FontWeight.w700),
        headlineMedium: AppType.h1.copyWith(color: ink),
        titleMedium: AppType.title.copyWith(color: ink),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(muted.withValues(alpha: .5)),
        radius: const Radius.circular(4),
        thickness: const WidgetStatePropertyAll(5),
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