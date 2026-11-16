import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Frosted glass surface. [blur] is off by default (cheap); enable it for
/// large hero panels only.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.blur = false,
    this.borderColor,
    this.color,
    this.glow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;
  final Color? borderColor;
  final Color? color;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: color != null ? [color!, color!.withValues(alpha: color!.a * 0.6)] : const [Color(0x1AFFFFFF), Color(0x0AFFFFFF)],
        ),
        border: Border.all(color: borderColor ?? AppColors.glassBorder),
        boxShadow: [
          if (glow != null) BoxShadow(color: glow!.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: -4),
          const BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: child,
    );
    if (!blur) return box;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: box),
    );
  }
}
