import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';

/// Tiny building blocks shared across every screen.

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s4, bottom: AppSpace.s3),
      child: Text(text.toUpperCase(),
          style: AppType.eyebrow.copyWith(color: scheme.onSurfaceVariant)),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile(
      {super.key, required this.label, required this.value, this.icon, this.accent = AppColors.primary});
  final String label;
  final String value;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      shadowColor: AppShadows.card.color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: accent),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(label.toUpperCase(),
                    style: AppType.eyebrow.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            ]),
            const SizedBox(height: AppSpace.s2),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: accent)),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.money = false});
  final String label;
  final String value;
  final bool money;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: money ? FontWeight.w700 : FontWeight.w500,
                    color: scheme.onSurface)),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.text, {super.key});
  final String text;

  static ({String label, Color fg, Color bg}) paint(String s) {
    final st = s.toUpperCase().trim();
    if (st.isEmpty) {
      return (label: 'UNSET', fg: AppColors.muted, bg: AppColors.pageBg);
    }
    if (st.contains('OVERDUE')) {
      return (label: st, fg: AppColors.blockFg, bg: AppColors.blockBg);
    }
    if (st.contains('DUE_TODAY')) {
      return (label: 'DUE TODAY', fg: AppColors.warnFg, bg: AppColors.warnBg);
    }
    if (st.contains('DUE_SOON')) {
      return (label: 'DUE SOON', fg: AppColors.warnFg, bg: AppColors.warnBg);
    }
    if (st.contains('ACTIVE') || st.contains('PAID') || st.contains('APPROVED') ||
        st.contains('FINALISED') || st.contains('ACCEPTED') || st.contains('SETTLED')) {
      return (label: st, fg: AppColors.okFg, bg: AppColors.okBg);
    }
    if (st.contains('PENDING') || st.contains('REQUESTED') || st.contains('DRAFT') ||
        st.contains('SUBMITTED') || st.contains('ENTERED')) {
      return (label: st, fg: AppColors.infoFg, bg: AppColors.infoBg);
    }
    if (st.contains('VOID') || st.contains('REVERSED') || st.contains('CANCELLED') ||
        st.contains('FAILED') || st.contains('LEFT') || st.contains('BLOCK') || st.contains('DENIED')) {
      return (label: st, fg: AppColors.blockFg, bg: AppColors.blockBg);
    }
    return (label: st, fg: AppColors.muted, bg: AppColors.pageBg);
  }

  @override
  Widget build(BuildContext context) {
    final p = paint(text);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? _darkFg(p.fg) : p.fg;
    final bg = dark ? _darkBg(p.bg) : p.bg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(p.label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .3,
              color: fg)),
    );
  }

  static Color _darkFg(Color light) {
    if (light == AppColors.okFg) return AppColors.dOkFg;
    if (light == AppColors.warnFg) return AppColors.dWarnFg;
    if (light == AppColors.blockFg) return AppColors.dBlockFg;
    if (light == AppColors.infoFg) return AppColors.dInfoFg;
    if (light == AppColors.muted) return AppColors.dMuted;
    return light;
  }

  static Color _darkBg(Color light) {
    if (light == AppColors.okBg) return AppColors.dOkBg;
    if (light == AppColors.warnBg) return AppColors.dWarnBg;
    if (light == AppColors.blockBg) return AppColors.dBlockBg;
    if (light == AppColors.infoBg) return AppColors.dInfoBg;
    if (light == AppColors.pageBg) return AppColors.dPageBg;
    return light;
  }
}

class AmountText extends StatelessWidget {
  const AmountText(this.amount, {super.key, this.bold = true});
  final num amount;
  final bool bold;
  @override
  Widget build(BuildContext context) => Text(inr(amount),
      style: TextStyle(
          fontSize: 16,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: AppColors.primary));
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key, this.icon = Icons.inbox_outlined, this.action});
  final String message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lavenderSoft.withValues(alpha: .7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpace.s4),
          Text(message,
              textAlign: TextAlign.center,
              style: AppType.body.copyWith(color: scheme.onSurfaceVariant)),
          if (action != null) ...[const SizedBox(height: AppSpace.s4), action!],
        ]),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView(this.message, {super.key, this.onRetry, this.compact = false});
  final String message;
  final VoidCallback? onRetry;
  final bool compact;
  @override
  Widget build(BuildContext context) => compact
      ? _row()
      : Center(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(AppSpace.s5), child: _row())));
  Widget _row() => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline, color: AppColors.blockFg, size: 22),
        const SizedBox(width: AppSpace.s2),
        Expanded(child: Text(message, style: const TextStyle(color: AppColors.blockFg))),
        if (onRetry != null)
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
      ]);
}

class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.secondary = false,
    this.destructive = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool secondary;
  final bool destructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final isPrimary = !secondary && !destructive;
    final bg = destructive
        ? AppColors.blockFg
        : secondary
            ? scheme.surface
            : AppColors.primary;
    final fg = secondary
        ? scheme.onSurface.withValues(alpha: .85)
        : Colors.white;
    final border = secondary ? BorderSide(color: AppColors.line) : BorderSide.none;
    return LayoutBuilder(builder: (context, c) {
      final btn = OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: border,
          minimumSize: const Size(0, AppSpace.s7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          disabledBackgroundColor: bg.withValues(alpha: .5),
          elevation: 0,
        ),
        onPressed: (busy || onPressed == null) ? null : onPressed,
        child: busy
            ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: AppSpace.s2)],
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
      );
      if (!isPrimary) return SizedBox(width: double.infinity, child: btn);
      // Primary: subtle accent gradient fill.
      final grad = dark ? AppGradients.primaryStrong : AppGradients.primary;
      return SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: grad,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: btn,
        ),
      );
    });
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.trailingIcon,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final IconData? trailingIcon;
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: trailingIcon != null && controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(trailingIcon!, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  })
              : null,
          isDense: true,
        ),
      );
}

class TagChip extends StatelessWidget {
  const TagChip(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppRadius.s, vertical: 5),
        decoration: BoxDecoration(
          color: (color ?? AppColors.focus),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      );
}

/// Pull-to-refresh wrapper used on every data screen.
class RefreshScaffold extends StatelessWidget {
  const RefreshScaffold({super.key, required this.onRefresh, required this.child});
  final Future<void> Function() onRefresh;
  final Widget child;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primary,
        child: child,
      );
}