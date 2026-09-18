import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Page background. A quiet ivory (or midnight) field — no motion, no blobs.
/// Kept as a widget (rather than inlined) so screens don't need to change and
/// so a future accent treatment has one place to land.
class Atmosphere extends StatelessWidget {
  const Atmosphere({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? AppColors.dPageBg : AppColors.background;
    return ColoredBox(color: base, child: child);
  }
}
