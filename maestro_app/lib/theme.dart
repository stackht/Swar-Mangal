import 'package:flutter/material.dart';

class Palette {
  static const bg = Color(0xFF0F1521);
  static const surface = Color(0xFF151C2B);
  static const card = Color(0xFF1A2231);
  static const cardHi = Color(0xFF202B3F);
  static const border = Color(0xFF26324A);
  static const text = Color(0xFFEAF0F8);
  static const muted = Color(0xFF8B99B4);
  static const lavender = Color(0xFFA894FC);
  static const mint = Color(0xFF52D69B);
  static const peach = Color(0xFFFFAE5E);
  static const sky = Color(0xFF7EB2FF);
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Palette.bg,
    colorScheme: const ColorScheme.dark(
      primary: Palette.lavender,
      secondary: Palette.mint,
      surface: Palette.surface,
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
      displaySmall: const TextStyle(color: Palette.text, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineSmall: const TextStyle(color: Palette.text, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: const TextStyle(color: Palette.text, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(color: Palette.text, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(color: Palette.text, fontSize: 15),
      bodyMedium: const TextStyle(color: Palette.text, fontSize: 14),
      bodySmall: const TextStyle(color: Palette.muted, fontSize: 13),
      labelLarge: const TextStyle(color: Palette.text, fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Palette.border.withValues(alpha: 0.6)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title.toUpperCase(),
                style: const TextStyle(
                    color: Palette.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key, this.color, this.filled = false});
  final String label;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (filled ? Palette.lavender : Palette.muted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? c : c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: filled ? Colors.white : c,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.accent = Palette.lavender});
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(color: Palette.muted, fontSize: 12))),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: Palette.text, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
        ],
      ),
    );
  }
}

class IconChip extends StatelessWidget {
  const IconChip({super.key, required this.icon, this.color = Palette.lavender, this.size = 20});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
}