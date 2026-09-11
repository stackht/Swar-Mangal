import 'package:flutter/material.dart';

/// Design tokens ported from the shared DesignSystem.html (RC3.12) so the
/// mobile surface keeps the exact visual language of the web apps.
class AppColors {
  AppColors._();

  static const ink = Color(0xFF1A202C);
  static const muted = Color(0xFF5A6572);
  static const line = Color(0xFFE2E8F0);
  static const pageBg = Color(0xFFF4F6F8);
  static const surface = Color(0xFFFFFFFF);

  static const primary = Color(0xFF9B2C2C); // brand maroon
  static const primaryDark = Color(0xFF7F2323);
  static const focus = Color(0xFF2B6CB0);

  static const okFg = Color(0xFF22543D);
  static const okBg = Color(0xFFC6F6D5);
  static const warnFg = Color(0xFF7B341E);
  static const warnBg = Color(0xFFFEEBC8);
  static const blockFg = Color(0xFF742A2A);
  static const blockBg = Color(0xFFFED7D7);
  static const infoFg = Color(0xFF2A4365);
  static const infoBg = Color(0xFFEBF8FF);
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

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.blockFg,
    ),
    scaffoldBackgroundColor: AppColors.pageBg,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.line),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.focus, width: 1.4),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.pageBg,
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(0, AppSpace.s7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}