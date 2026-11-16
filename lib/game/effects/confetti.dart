import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Lightweight confetti: positions are a pure function of time, so there is
/// no per-frame allocation or simulation state.
class ConfettiLayer extends StatefulWidget {
  const ConfettiLayer({super.key, this.count = 90, this.duration = const Duration(milliseconds: 3200)});
  final int count;
  final Duration duration;

  @override
  State<ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<ConfettiLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)..forward();
  late final List<_Piece> _pieces = List.generate(widget.count, (i) => _Piece(math.Random(i * 97 + 11)));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(child: CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_c, _pieces))),
      );
}

class _Piece {
  _Piece(math.Random r)
      : x = r.nextDouble(),
        vx = (r.nextDouble() - 0.5) * 0.5,
        vy = 0.55 + r.nextDouble() * 0.75,
        delay = r.nextDouble() * 0.25,
        spin = (r.nextDouble() - 0.5) * 18,
        w = 6 + r.nextDouble() * 6,
        h = 3 + r.nextDouble() * 4,
        color = BallPalette.of(r.nextInt(10)),
        round = r.nextBool();

  final double x, vx, vy, delay, spin, w, h;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.a, this.pieces) : super(repaint: a);
  final Animation<double> a;
  final List<_Piece> pieces;
  final Paint _p = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final t0 = a.value * 3.2;
    for (final p in pieces) {
      final t = t0 - p.delay;
      if (t <= 0) continue;
      final y = -0.08 * size.height + (p.vy * t + 0.5 * 0.18 * t * t) * size.height * 0.55;
      if (y > size.height + 20) continue;
      final x = (p.x + p.vx * t * 0.35 + math.sin(t * 3 + p.spin) * 0.02) * size.width;
      final fade = (1 - a.value).clamp(0.0, 1.0) * 1.4;
      _p.color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.spin * 0.3);
      final sx = math.cos(t * p.spin * 0.5).abs() * 0.8 + 0.2;
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.h * 0.7, _p);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.w * sx, height: p.h), const Radius.circular(1.5)), _p);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => false;
}
