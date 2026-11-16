import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_colors.dart';
import '../animation/board_animator.dart';
import '../ball/ball_sprite_cache.dart';
import '../engine/tube_state.dart';
import '../tube/tube_renderer.dart';

/// Paints the whole board in one pass: tube backs → balls → tube fronts →
/// glows → flights → particles. Repaints only when the animator ticks.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.animator,
    required this.balls,
    required this.tubeRenderer,
    required this.tubes,
    required this.selected,
    required this.accent,
  }) : super(repaint: animator);

  final BoardAnimator animator;
  final BallSpriteCache balls;
  final TubeRenderer tubeRenderer;
  final List<TubeState> Function() tubes;
  final int? Function() selected;
  final Color accent;

  final Paint _glow = Paint()..style = PaintingStyle.stroke;
  final Paint _layer = Paint()..filterQuality = FilterQuality.medium;
  final Paint _ballPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final l = animator.layout;
    if (l == null) return;
    final ts = tubes();
    final n = math.min(ts.length, l.tubeRects.length);
    final sel = selected();
    final hint = animator.hintMove;
    final pulse = 0.5 + 0.5 * math.sin(animator.time * 5);

    for (var i = 0; i < n; i++) {
      final t = ts[i];
      var r = animator.rectFor(i);
      final appear = animator.appearOf(i).clamp(0.0, 1.0);
      if (appear < 1) {
        canvas.save();
        final pivot = r.bottomCenter;
        canvas.translate(pivot.dx, pivot.dy);
        canvas.scale(0.6 + 0.4 * appear, appear);
        canvas.translate(-pivot.dx, -pivot.dy);
      }
      final lift = animator.liftOf(i);
      final shake = animator.shakeOf(i);
      final glow = animator.glowOf(i);
      final complete = t.isComplete && animator.inbound(i) == 0;

      // ---- glows behind the tube
      if (lift > 0.02) _drawGlow(canvas, r, accent, lift * 0.9, l.ball);
      if (hint != null && (hint.from == i || hint.to == i)) {
        _drawGlow(canvas, r, hint.from == i ? AppColors.cyan : AppColors.success, 0.45 + pulse * 0.55, l.ball);
      }
      if (complete && glow > 0) _drawGlow(canvas, r, AppColors.success, glow, l.ball);
      final wave = animator.celebrateWave;
      if (wave >= 0 && !t.isEmpty) {
        final phase = wave - i / math.max(1, n) * 0.6;
        if (phase > 0 && phase < 1) _drawGlow(canvas, r, BallPalette.of(t.balls.first), math.sin(phase * math.pi), l.ball);
      }
      if (shake > 0) _drawGlow(canvas, r, AppColors.coral, shake * 0.9, l.ball);

      tubeRenderer.drawBack(canvas, r, paint: _layer..color = Color.fromRGBO(255, 255, 255, appear));

      // ---- balls inside
      final visible = t.length - animator.inbound(i);
      final squash = animator.squashOf(i);
      for (var k = 0; k < visible; k++) {
        var c = animator.slotIn(r, k);
        final isTop = k == visible - 1;
        if (isTop && sel == i && visible > 0) {
          c = Offset.lerp(c, animator.liftedIn(r), lift)!;
        } else if (sel == i) {
          c = c.translate(0, -lift * l.ball * 0.035 * (k + 1) / visible);
        }
        final sq = isTop ? math.sin(squash * math.pi) * 0.22 : 0.0;
        balls.draw(canvas, t.balls[k], c, squash: sq, paint: _ballPaint);
      }

      tubeRenderer.drawFront(canvas, r, paint: _layer..color = Color.fromRGBO(255, 255, 255, appear));

      if (complete) _drawCheck(canvas, r, glow, l.ball);
      if (appear < 1) canvas.restore();
      if (hint != null && hint.to == i) _drawChevron(canvas, r, pulse, l.ball);
    }

    // ---- flights on top of everything
    for (final f in animator.flights) {
      balls.draw(canvas, f.color, f.pos, paint: _ballPaint);
    }
    animator.particles.paint(canvas);

    final cel = animator.celebration;
    if (cel > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: 0.07 * math.sin(cel * math.pi)));
    }
  }

  void _drawGlow(Canvas canvas, Rect r, Color c, double strength, double ball) {
    if (strength <= 0) return;
    final path = TubeRenderer.shape(r.inflate(1.5));
    _glow
      ..color = c.withValues(alpha: (0.55 * strength).clamp(0.0, 1.0))
      ..strokeWidth = ball * 0.16
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, ball * 0.18);
    canvas.drawPath(path, _glow);
    _glow
      ..maskFilter = null
      ..strokeWidth = 1.6
      ..color = c.withValues(alpha: (0.8 * strength).clamp(0.0, 1.0));
    canvas.drawPath(path, _glow);
  }

  void _drawCheck(Canvas canvas, Rect r, double glow, double ball) {
    final c = Offset(r.center.dx, r.top - ball * 0.32);
    final s = ball * 0.2;
    canvas.drawCircle(c, s, Paint()..color = AppColors.success.withValues(alpha: 0.9));
    final p = Path()
      ..moveTo(c.dx - s * 0.45, c.dy)
      ..lineTo(c.dx - s * 0.1, c.dy + s * 0.38)
      ..lineTo(c.dx + s * 0.5, c.dy - s * 0.35);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.28
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF062016),
    );
  }

  void _drawChevron(Canvas canvas, Rect r, double pulse, double ball) {
    final y = r.top - ball * 1.05 - pulse * ball * 0.12;
    final s = ball * 0.22;
    final p = Path()
      ..moveTo(r.center.dx - s, y - s * 0.5)
      ..lineTo(r.center.dx, y + s * 0.4)
      ..lineTo(r.center.dx + s, y - s * 0.5);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.38
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.success.withValues(alpha: 0.6 + pulse * 0.4),
    );
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
        final l = animator.layout;
        if (l == null) return const [];
        final ts = tubes();
        final sel = selected();
        return [
          for (var i = 0; i < math.min(ts.length, l.tubeRects.length); i++)
            CustomPainterSemantics(
              rect: l.hitRect(i),
              properties: SemanticsProperties(
                button: true,
                selected: sel == i,
                label: 'Tube ${i + 1}',
                value: ts[i].isEmpty
                    ? 'empty'
                    : '${ts[i].isComplete ? 'complete, ' : ''}${ts[i].balls.reversed.map((b) => BallPalette.names[b % 10]).join(', ')} (top first)',
                textDirection: TextDirection.ltr,
              ),
            ),
        ];
      };

  @override
  bool shouldRebuildSemantics(covariant BoardPainter oldDelegate) => true;

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.animator != animator || old.balls != balls || old.tubeRenderer != tubeRenderer || old.accent != accent;
}
