import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/game_themes.dart';

/// Theme backdrop: deep gradient, two slow ambient light blobs, a vignette
/// and a few softly drifting orbs. Isolated in a RepaintBoundary and very
/// cheap; static when motion is reduced.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key, required this.theme, this.orbs = true, this.child, this.reduceMotion = false});

  final GameThemeSpec theme;
  final bool orbs;
  final bool reduceMotion;
  final Widget? child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 40));

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedBackground old) {
    super.didUpdateWidget(old);
    if (widget.reduceMotion && _c.isAnimating) _c.stop();
    if (!widget.reduceMotion && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      RepaintBoundary(
        child: CustomPaint(painter: _BgPainter(widget.theme, _c, widget.orbs)),
      ),
      if (widget.child != null) widget.child!,
    ]);
  }
}

class _BgPainter extends CustomPainter {
  _BgPainter(this.t, this.anim, this.orbs) : super(repaint: anim);
  final GameThemeSpec t;
  final Animation<double> anim;
  final bool orbs;

  static final _orbs = List.generate(9, (i) {
    final r = math.Random(i * 13 + 5);
    return (r.nextDouble(), r.nextDouble(), 6 + r.nextDouble() * 16, r.nextInt(10), r.nextDouble() * math.pi * 2);
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [t.top, t.bottom]).createShader(rect));
    final a = anim.value * math.pi * 2;
    void blob(Offset c, double r, Color col, double alpha) {
      canvas.drawCircle(c, r, Paint()..shader = RadialGradient(colors: [col.withValues(alpha: alpha), col.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)));
    }

    blob(Offset(size.width * (0.2 + 0.08 * math.sin(a)), size.height * (0.18 + 0.04 * math.cos(a))), size.width * 0.75, t.glowA, 0.16);
    blob(Offset(size.width * (0.85 + 0.06 * math.cos(a * 2)), size.height * (0.78 + 0.05 * math.sin(a))), size.width * 0.8, t.glowB, 0.11);

    if (orbs) {
      for (final o in _orbs) {
        final x = (o.$1 + 0.03 * math.sin(a + o.$5)) * size.width;
        final y = ((o.$2 - anim.value * 0.25 + 1) % 1.0) * size.height;
        final c = Offset(x, y);
        final col = BallPalette.of(o.$4);
        canvas.drawCircle(c, o.$3, Paint()..shader = RadialGradient(center: const Alignment(-0.3, -0.3), colors: [col.withValues(alpha: 0.16), col.withValues(alpha: 0.02)]).createShader(Rect.fromCircle(center: c, radius: o.$3)));
      }
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(radius: 1.0, colors: [Colors.transparent, Colors.black.withValues(alpha: t.vignette)], stops: const [0.55, 1]).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) => old.t != t || old.orbs != orbs;
}
