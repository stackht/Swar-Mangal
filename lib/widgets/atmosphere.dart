import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Subtle continuously-flowing gradient atmosphere behind the app content.
///
/// Soft lavender / mint / blue-violet blobs drift very slowly via a single
/// AnimationController driving four Transform.translate positions. The
/// repaint boundary isolates the blobs so the content tree is not re-laid out
/// per frame. Respects reduced motion: static blobs when disabled.
class Atmosphere extends StatefulWidget {
  const Atmosphere({super.key, this.child});
  final Widget? child;

  @override
  State<Atmosphere> createState() => _AtmosphereState();
}

class _AtmosphereState extends State<Atmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;
  bool _started = false;

  bool get _inTest => Platform.environment.containsKey('FLUTTER_TEST');
  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 34));
    _t = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    // Don't access MediaQuery here; defer repeat to didChangeDependencies.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || _inTest || _reduceMotion) {
      if (_started && _reduceMotion && _c.isAnimating) _c.stop();
      return;
    }
    _started = true;
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? AppColors.dPageBg : AppColors.background;
    return ColoredBox(
      color: base,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _t,
              builder: (context, _) {
                final p = _t.value * 2 * 3.14159;
                final d1 = Offset(0.18 * _sin(p), 0.10 * _cos(p * 0.7));
                final d2 = Offset(0.16 * _cos(p * 0.9), 0.12 * _sin(p * 1.3));
                final d3 = Offset(0.12 * _sin(p * 0.5), 0.14 * _cos(p * 0.6));
return Stack(
                  fit: StackFit.expand,
                  children: [
                    _blob(
                      d1.dx - 0.35,
                      d1.dy - 0.35,
                      420,
                      AppGradients.blobLavender,
                    ),
                    _blob(
                      -0.75 + d2.dx * 0.7,
                      0.75 + d2.dy * 0.7,
                      380,
                      AppGradients.blobMint,
                    ),
                    if (!dark) ...[
                      _blob(
                        0.85 + d3.dx * 0.6,
                        -0.4 + d3.dy * 0.6,
                        300,
                        AppGradients.blobLavender,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }

  double _sin(double x) {
    final idx = (x.abs() * 512 / 6.283185307179586).floor() % 512;
    return _sinTable[idx];
  }

  double _cos(double x) => _sin(x + 1.5707963267948966);

  // Precomputed sin table to avoid dart:math per frame.
  static final List<double> _sinTable = _buildSinTable();

  static List<double> _buildSinTable() {
    final n = 512;
    return List<double>.generate(n, (i) {
      final x = i / (n * 1.0) * 6.283185307179586;
      var term = x, val = x, sign = -1.0;
      for (var k = 3; k < 20; k += 2) {
        term *= x * x / ((k - 1) * k);
        val += sign * term;
        sign = -sign;
      }
      return val;
    });
  }

  Widget _blob(double dx, double dy, double size, Gradient gradient) {
    return Align(
      alignment: Alignment(dx.clamp(-1, 1), dy.clamp(-1, 1)),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
      ),
    );
  }
}