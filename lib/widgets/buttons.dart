import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'pressable.dart';

/// Hero call-to-action: gradient, glow, spring press and an idle "breath".
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.gradient = AppColors.primaryGradient,
    this.height = 62,
    this.pulse = false,
    this.subtitle,
    this.textColor = const Color(0xFF061021),
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final IconData? icon;
  final Gradient gradient;
  final double height;
  final bool pulse;
  final Color textColor;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final glowColor = widget.gradient.colors.last;
    return Pressable(
      onTap: widget.onTap,
      semanticLabel: widget.label,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = reduce || !widget.pulse ? 0.0 : Curves.easeInOut.transform(_c.value);
          return Transform.scale(
            scale: 1 + t * 0.015,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(widget.height / 2),
                boxShadow: [
                  BoxShadow(color: glowColor.withValues(alpha: 0.32 + t * 0.18), blurRadius: 26 + t * 10, offset: const Offset(0, 8)),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Stack(children: [
          // Top gloss.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.center, colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)]),
              ),
            ),
          ),
          // Scales the label down on narrow phones / large text instead of
          // overflowing the pill.
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (widget.icon != null) ...[Icon(widget.icon, color: widget.textColor, size: 26), const SizedBox(width: 10)],
                  Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.label, style: AppText.button.copyWith(color: widget.textColor)),
                    if (widget.subtitle != null)
                      Text(widget.subtitle!, style: AppText.small.copyWith(color: widget.textColor.withValues(alpha: 0.7), fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Secondary glass button.
class GlassButton extends StatelessWidget {
  const GlassButton({super.key, required this.label, required this.onTap, this.icon, this.accent = AppColors.cyan, this.height = 56});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color accent;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          color: AppColors.glass,
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, color: accent, size: 22), const SizedBox(width: 8)],
              Text(label, style: AppText.button.copyWith(color: AppColors.textPrimary, fontSize: 15, letterSpacing: 1.4)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Round glass icon button (≥48 px target).
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({super.key, required this.icon, required this.onTap, required this.label, this.size = 48, this.color = AppColors.textPrimary, this.badge});

  final IconData icon;
  final VoidCallback? onTap;
  final String label;
  final double size;
  final Color color;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.glass, border: Border.all(color: AppColors.glassBorder)),
            child: Icon(icon, color: color, size: size * 0.48),
          ),
          if (badge != null)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(10)),
                child: Text(badge!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
        ]),
      ),
    );
  }
}
