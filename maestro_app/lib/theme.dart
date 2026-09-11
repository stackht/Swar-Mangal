import 'package:flutter/material.dart';

class Palette {
  // Backgrounds
  static const bg = Color(0xFF0B0E17);
  static const surface = Color(0xFF131829);
  static const card = Color(0xFF1A2035);
  static const cardHi = Color(0xFF212842);
  static const border = Color(0xFF2A3352);

  // Text
  static const text = Color(0xFFF0F2F8);
  static const muted = Color(0xFF8A94B0);

  // Primary — Violet
  static const violet = Color(0xFF8649F5);
  static const violetSoft = Color(0xFF7040CC);
  static const violetGlow = Color(0xAA6940D4);

  // Accents
  static const mint = Color(0xFF34D399);
  static const peach = Color(0xFFFFAE5E);
  static const sky = Color(0xFF60A5FA);
  static const rose = Color(0xFFF472B6);
  static const lime = Color(0xFF84CC16);

  // Music gradient
  static const gradientMusic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFC026D3)],
  );

  static const gradientHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1B4B), Color(0xFF2E1065), Color(0xFF3B0764)],
  );
}

ThemeData buildTheme() {
  const bg = Palette.bg;
  const surface = Palette.surface;
  final base = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: Palette.violet,
      secondary: Palette.mint,
      surface: surface,
      error: Color(0xFFEF4444),
    ),
    useMaterial3: true,
  );
  return base.copyWith(
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Palette.cardHi,
      contentTextStyle: const TextStyle(color: Palette.text, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    textTheme: base.textTheme.copyWith(
      displaySmall: const TextStyle(color: Palette.text, fontWeight: FontWeight.w700, letterSpacing: -0.6, fontSize: 28),
      headlineSmall: const TextStyle(color: Palette.text, fontWeight: FontWeight.w700, letterSpacing: -0.4, fontSize: 22),
      titleLarge: const TextStyle(color: Palette.text, fontWeight: FontWeight.w600, fontSize: 18),
      titleMedium: const TextStyle(color: Palette.text, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: const TextStyle(color: Palette.text, fontSize: 15, letterSpacing: 0.1),
      bodyMedium: const TextStyle(color: Palette.text, fontSize: 14, letterSpacing: 0.1),
      bodySmall: const TextStyle(color: Palette.muted, fontSize: 13),
      labelLarge: const TextStyle(color: Palette.text, fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );
}

// =============== REUSABLE WIDGETS ===============

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Palette.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.border.withValues(alpha: 0.5)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              color: Palette.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.accent = Palette.violet, this.trend});
  final String label;
  final String value;
  final Color accent;
  final String? trend;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(color: Palette.muted, fontSize: 12))),
            if (trend != null)
              Text(trend!, style: TextStyle(color: trend!.startsWith('+') ? Palette.mint : Palette.peach, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Palette.text, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        ],
      ),
    );
  }
}

class IconChip extends StatelessWidget {
  const IconChip({super.key, required this.icon, this.color = Palette.violet, this.size = 20});
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}

class WaveDecor extends StatelessWidget {
  const WaveDecor({super.key, this.bars = 32, this.color, this.height = 28});
  final int bars;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Palette.violet.withValues(alpha: 0.25);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(bars, (i) {
          final h = 8 + (i * 7) % 16;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0.8),
              height: h.toDouble(),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.4 + (i % 4) * 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
}