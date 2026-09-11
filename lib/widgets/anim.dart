import 'package:flutter/material.dart';

/// Motion primitives for the app shell + lists.
/// EVERY animation here is disabled when the OS prefers reduced motion
/// (MediaQuery.disableAnimationsOf) — the prompt's accessibility rule.

bool reduceMotion(BuildContext context) => MediaQuery.disableAnimationsOf(context);

/// Fade + subtle rise on entry, optionally stagger-delayed for lists.
class FadeIn extends StatefulWidget {
  const FadeIn({super.key, required this.child, this.delay = Duration.zero, this.offset = 12});
  final Widget child;
  final Duration delay;
  final double offset;
  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _op;
  late final Animation<double> _dy;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _op = curved;
    _dy = Tween<double>(begin: widget.offset, end: 0).animate(curved);
    if (widget.delay > Duration.zero) {
      // schedule: reset to 0 then forward after delay
      _c.stop();
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _op.value,
        child: Transform.translate(offset: Offset(0, _dy.value), child: child),
      ),
    );
  }
}

/// Cross-view transition for the shell body — subtle, fast.
class ViewSwitch extends StatelessWidget {
  const ViewSwitch({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: reduceMotion(context)
            ? child
            : SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.012),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
      ),
      child: KeyedSubtree(key: ValueKey<String?>(_viewKey(child)), child: child),
    );
  }

  String? _viewKey(Widget child) {
    // Encode a stable key from the subtree's first key if present.
    final key = child.key;
    return key?.toString();
  }
}

/// Subtle press-scale for tappable cards. No-op under reduced motion.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.985});
  final Widget child;
  final double scale;
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (!reduceMotion(context)) setState(() => _pressed = true);
      },
      onTapCancel: () {
        if (_pressed) setState(() => _pressed = false);
      },
      onTapUp: (_) {
        if (_pressed) setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: reduceMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Shimmering placeholder that matches card geometry (no layout shift).
class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({super.key, this.height = 14, this.width, this.radius = 6});
  final double height;
  final double? width;
  final double radius;
  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      lowerBound: 0.35,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: _c.value == 0
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      child: reduceMotion(context)
          ? null
          : AnimatedBuilder(
              animation: _c,
              builder: (_, _) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.radius),
                  gradient: LinearGradient(
                    colors: [
                      scheme.surfaceContainerHighest,
                      scheme.surfaceContainerHigh,
                      scheme.surfaceContainerHighest,
                    ],
                    stops: [0, _c.value, 1],
                  ),
                ),
              ),
            ),
    );
  }
}

/// Vertical skeleton layout used while list/dashboards load.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 6, this.header = true});
  final int rows;
  final bool header;
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (header) ...[
          const SkeletonBlock(height: 22, width: 160),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                SkeletonBlock(height: 15, width: double.infinity),
                SizedBox(height: 8),
                SkeletonBlock(height: 12, width: 140),
              ]),
            ),
          ),
      ],
    );
  }
}