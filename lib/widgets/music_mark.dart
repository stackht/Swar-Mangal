import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'anim.dart';

/// Subtle music identity — a quiet waveform mark. Used selectively
/// (login, home heroes). Disabled under reduced motion.
class WaveformMark extends StatelessWidget {
  const WaveformMark({
    super.key,
    this.bars = 13,
    this.color,
    this.active = false,
    this.height = 26,
  });
  final int bars;
  final Color? color;
  final bool active;
  final double height;

  static const _pattern = <double>[
    0.45, 0.7, 0.38, 0.85, 0.55, 1.0, 0.62, 0.9, 0.42, 0.78, 0.5, 0.68, 0.4,
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? (dark ? AppColors.dPrimary : AppColors.brass);
    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < bars; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _Bar(
                heightRatio: _pattern[i % _pattern.length],
                color: c.withValues(alpha: active ? 1 : .55),
                active: active,
                maxHeight: height,
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.heightRatio, required this.color, required this.active, required this.maxHeight});
  final double heightRatio;
  final Color color;
  final bool active;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final h = maxHeight * heightRatio;
    if (reduceMotion(context)) {
      return Container(
        width: 3,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    // Gentle idle pulse on the active mark only (never distracting).
    return AnimatedContainer(
      duration: Duration(milliseconds: active ? 520 : 0),
      curve: Curves.easeInOut,
      width: 3,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Quiet editorial section header: uppercase, letter-spaced, small.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppType.eyebrow.copyWith(
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}