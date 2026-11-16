import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/utils/seeded_random.dart';
import '../../models/cosmetics.dart';

Color _lighten(Color c, double t) => Color.lerp(c, Colors.white, t)!;
Color _darken(Color c, double t) => Color.lerp(c, const Color(0xFF02040A), t)!;

/// Immediate-mode drawing of one soft-3D ball. Used to bake sprites (see
/// `BallSpriteCache`) and for small previews in the shop.
class BallRenderer {
  BallRenderer._();

  /// Draws a ball centred at [c] with radius [r]. [glyph] ≥ 0 adds an
  /// accessibility symbol.
  static void paint(Canvas canvas, Offset c, double r, Color base, BallSkin skin, {int glyph = -1, int seed = 0, bool shadow = true}) {
    if (shadow) {
      canvas.drawOval(
        Rect.fromCenter(center: c + Offset(0, r * 0.82), width: r * 1.7, height: r * 0.5),
        Paint()
          ..color = const Color(0x66000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.18),
      );
    }
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    switch (skin) {
      case BallSkin.classic:
        _gel(canvas, c, r, base);
      case BallSkin.glass:
        _glass(canvas, c, r, base);
      case BallSkin.crystal:
        _gel(canvas, c, r, base);
        _facets(canvas, c, r);
      case BallSkin.neon:
        _neon(canvas, c, r, base);
      case BallSkin.candy:
        _gel(canvas, c, r, _lighten(base, 0.08));
        _stripes(canvas, c, r);
      case BallSkin.metallic:
        _metal(canvas, c, r, base);
      case BallSkin.galaxy:
        _galaxy(canvas, c, r, base, seed);
      case BallSkin.pearl:
        _pearl(canvas, c, r, base);
      case BallSkin.fire:
        _gel(canvas, c, r, base);
        _fire(canvas, c, r);
      case BallSkin.ice:
        _gel(canvas, c, r, _lighten(base, 0.18));
        _frost(canvas, c, r, seed);
    }
    // Reflected bounce light along the lower rim (gives depth).
    canvas.drawCircle(
      c,
      r * 0.93,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..shader = ui.Gradient.linear(c + Offset(0, r), c, [_lighten(base, 0.45).withValues(alpha: 0.55), Colors.transparent]),
    );
    canvas.restore();

    if (glyph >= 0) _glyph(canvas, c, r * 0.36, glyph, base);
    if (skin != BallSkin.neon) _highlight(canvas, c, r, skin == BallSkin.metallic || skin == BallSkin.glass ? 1.0 : 0.85);
  }

  static void _gel(Canvas canvas, Offset c, double r, Color base) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c + Offset(-r * 0.32, -r * 0.38),
          r * 1.45,
          [_lighten(base, 0.38), base, _darken(base, 0.32), _darken(base, 0.62)],
          [0, 0.42, 0.82, 1],
        ),
    );
    // Subtle inner glow from the core.
    canvas.drawCircle(
      c + Offset(0, r * 0.18),
      r * 0.62,
      Paint()
        ..shader = ui.Gradient.radial(c + Offset(0, r * 0.18), r * 0.62, [_lighten(base, 0.2).withValues(alpha: 0.35), Colors.transparent]),
    );
  }

  static void _glass(Canvas canvas, Offset c, double r, Color base) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(c + Offset(0, r * 0.25), r * 1.2,
            [_lighten(base, 0.5).withValues(alpha: 0.95), base.withValues(alpha: 0.78), _darken(base, 0.5).withValues(alpha: 0.9)], [0, 0.6, 1]),
    );
    // Refraction crescent.
    final p = Path()
      ..addOval(Rect.fromCircle(center: c + Offset(0, r * 0.35), radius: r * 0.7))
      ..addOval(Rect.fromCircle(center: c + Offset(0, r * 0.15), radius: r * 0.68))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(p, Paint()..color = _lighten(base, 0.7).withValues(alpha: 0.45));
  }

  static void _neon(Canvas canvas, Offset c, double r, Color base) {
    canvas.drawCircle(c, r, Paint()..shader = ui.Gradient.radial(c, r, [_darken(base, 0.55), _darken(base, 0.82)], [0.2, 1]));
    canvas.drawCircle(
      c,
      r * 0.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.16
        ..color = _lighten(base, 0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
    );
    canvas.drawCircle(
      c,
      r * 0.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..color = _lighten(base, 0.6),
    );
    canvas.drawCircle(c, r * 0.22, Paint()..color = _lighten(base, 0.3).withValues(alpha: 0.7)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12));
  }

  static void _facets(Canvas canvas, Offset c, double r) {
    for (var i = 0; i < 8; i++) {
      final a0 = i * math.pi / 4 + 0.3;
      final a1 = a0 + math.pi / 4;
      final path = Path()
        ..moveTo(c.dx + math.cos(a0) * r * 0.42, c.dy + math.sin(a0) * r * 0.42)
        ..lineTo(c.dx + math.cos(a0) * r * 1.1, c.dy + math.sin(a0) * r * 1.1)
        ..lineTo(c.dx + math.cos(a1) * r * 1.1, c.dy + math.sin(a1) * r * 1.1)
        ..lineTo(c.dx + math.cos(a1) * r * 0.42, c.dy + math.sin(a1) * r * 0.42)
        ..close();
      canvas.drawPath(path, Paint()..color = (i.isEven ? Colors.white : Colors.black).withValues(alpha: i.isEven ? 0.13 : 0.1));
    }
    final core = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.3;
      final o = Offset(c.dx + math.cos(a) * r * 0.42, c.dy + math.sin(a) * r * 0.42);
      i == 0 ? core.moveTo(o.dx, o.dy) : core.lineTo(o.dx, o.dy);
    }
    core.close();
    canvas.drawPath(core, Paint()..color = Colors.white.withValues(alpha: 0.16));
    canvas.drawPath(core, Paint()..style = PaintingStyle.stroke..strokeWidth = r * 0.03..color = Colors.white.withValues(alpha: 0.35));
  }

  static void _stripes(Canvas canvas, Offset c, double r) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.6);
    final p = Paint()..color = Colors.white.withValues(alpha: 0.32);
    for (var x = -r * 1.4; x < r * 1.4; x += r * 0.55) {
      canvas.drawRect(Rect.fromLTWH(x, -r * 1.2, r * 0.2, r * 2.4), p);
    }
    canvas.restore();
  }

  static void _metal(Canvas canvas, Offset c, double r, Color base) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.linear(c - Offset(0, r), c + Offset(0, r), [
          _lighten(base, 0.65),
          _lighten(base, 0.15),
          _darken(base, 0.45),
          _lighten(base, 0.25),
          _darken(base, 0.65),
        ], [0, 0.35, 0.52, 0.7, 1]),
    );
  }

  static void _galaxy(Canvas canvas, Offset c, double r, Color base, int seed) {
    canvas.drawCircle(c, r, Paint()..shader = ui.Gradient.radial(c + Offset(-r * 0.2, -r * 0.2), r * 1.3, [base, _darken(base, 0.55), const Color(0xFF05030F)], [0, 0.6, 1]));
    canvas.drawCircle(c + Offset(r * 0.25, r * 0.2), r * 0.55,
        Paint()..shader = ui.Gradient.radial(c + Offset(r * 0.25, r * 0.2), r * 0.55, [_lighten(base, 0.4).withValues(alpha: 0.5), Colors.transparent]));
    final rng = SeededRandom(seed * 31 + 7);
    final star = Paint()..color = Colors.white;
    for (var i = 0; i < 14; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final d = math.sqrt(rng.nextDouble()) * r * 0.9;
      canvas.drawCircle(c + Offset(math.cos(a) * d, math.sin(a) * d), r * (0.02 + rng.nextDouble() * 0.035), star..color = Colors.white.withValues(alpha: 0.5 + rng.nextDouble() * 0.5));
    }
  }

  static void _pearl(Canvas canvas, Offset c, double r, Color base) {
    final soft = Color.lerp(base, Colors.white, 0.35)!;
    _gel(canvas, c, r, soft);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..blendMode = BlendMode.softLight
        ..shader = ui.Gradient.sweep(
          c,
          const [Color(0xFFFFE3F1), Color(0xFFD9F4FF), Color(0xFFE9FFE6), Color(0xFFFFF6D9), Color(0xFFFFE3F1)],
          const [0, 0.25, 0.5, 0.75, 1],
        ),
    );
  }

  static void _fire(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c + Offset(0, r * 0.55),
      r,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.radial(c + Offset(0, r * 0.7), r, [const Color(0xFFFFE08A).withValues(alpha: 0.55), const Color(0xFFFF6A2B).withValues(alpha: 0.25), Colors.transparent], [0, 0.5, 1]),
    );
    final p = Path()
      ..moveTo(c.dx - r * 0.5, c.dy + r)
      ..quadraticBezierTo(c.dx - r * 0.55, c.dy + r * 0.1, c.dx - r * 0.15, c.dy - r * 0.2)
      ..quadraticBezierTo(c.dx - r * 0.2, c.dy + r * 0.3, c.dx + r * 0.1, c.dy + r * 0.2)
      ..quadraticBezierTo(c.dx + r * 0.35, c.dy - r * 0.3, c.dx + r * 0.55, c.dy + r * 0.1)
      ..quadraticBezierTo(c.dx + r * 0.7, c.dy + r * 0.6, c.dx + r * 0.5, c.dy + r)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFFFFD08A).withValues(alpha: 0.22)..blendMode = BlendMode.screen);
  }

  static void _frost(Canvas canvas, Offset c, double r, int seed) {
    final rng = SeededRandom(seed * 17 + 3);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.035
      ..color = Colors.white.withValues(alpha: 0.42);
    for (var i = 0; i < 4; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      var p = c + Offset(math.cos(a) * r * 0.15, math.sin(a) * r * 0.15);
      final path = Path()..moveTo(p.dx, p.dy);
      for (var k = 0; k < 3; k++) {
        final aa = a + (rng.nextDouble() - 0.5) * 0.9;
        p += Offset(math.cos(aa) * r * 0.3, math.sin(aa) * r * 0.3);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, line);
    }
    canvas.drawCircle(c - Offset(0, r * 0.6), r * 0.7, Paint()..shader = ui.Gradient.radial(c - Offset(0, r * 0.7), r * 0.7, [Colors.white.withValues(alpha: 0.35), Colors.transparent]));
  }

  static void _highlight(Canvas canvas, Offset c, double r, double strength) {
    canvas.save();
    canvas.translate(c.dx - r * 0.33, c.dy - r * 0.42);
    canvas.rotate(-0.55);
    final hl = Rect.fromCenter(center: Offset.zero, width: r * 0.62, height: r * 0.34);
    canvas.drawOval(
      hl,
      Paint()..shader = ui.Gradient.linear(hl.topCenter, hl.bottomCenter, [Colors.white.withValues(alpha: 0.85 * strength), Colors.white.withValues(alpha: 0.0)]),
    );
    canvas.restore();
    canvas.drawCircle(c + Offset(r * 0.42, r * 0.38), r * 0.07, Paint()..color = Colors.white.withValues(alpha: 0.28 * strength));
  }

  /// Ten distinct shape glyphs (one per palette color).
  static void _glyph(Canvas canvas, Offset c, double s, int g, Color base) {
    final dark = base.computeLuminance() > 0.45;
    final paint = Paint()
      ..color = (dark ? const Color(0xFF0A1020) : Colors.white).withValues(alpha: dark ? 0.55 : 0.78)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.32
      ..strokeCap = StrokeCap.round;
    Path poly(int n, double rot, [double rr = 1]) {
      final p = Path();
      for (var i = 0; i < n; i++) {
        final a = rot + i * 2 * math.pi / n;
        final o = c + Offset(math.cos(a) * s * rr, math.sin(a) * s * rr);
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    switch (g % 10) {
      case 0:
        canvas.drawCircle(c, s * 0.62, paint);
      case 1:
        canvas.drawPath(poly(3, -math.pi / 2), paint);
      case 2:
        canvas.drawRect(Rect.fromCenter(center: c, width: s * 1.3, height: s * 1.3), paint);
      case 3:
        canvas.drawPath(poly(4, 0), paint);
      case 4:
        final p = Path();
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + i * math.pi / 5;
          final rr = i.isEven ? s : s * 0.45;
          final o = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
          i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(p..close(), paint);
      case 5:
        canvas.drawLine(c - Offset(s * 0.8, 0), c + Offset(s * 0.8, 0), stroke);
        canvas.drawLine(c - Offset(0, s * 0.8), c + Offset(0, s * 0.8), stroke);
      case 6:
        canvas.drawPath(poly(6, 0), paint);
      case 7:
        canvas.drawCircle(c, s * 0.65, stroke..strokeWidth = s * 0.28);
      case 8:
        final p = Path()
          ..moveTo(c.dx - s * 0.8, c.dy + s * 0.35)
          ..lineTo(c.dx, c.dy - s * 0.45)
          ..lineTo(c.dx + s * 0.8, c.dy + s * 0.35);
        canvas.drawPath(p, stroke);
      case 9:
        canvas.drawLine(c - Offset(s * 0.75, -s * 0.75), c + Offset(s * 0.75, -s * 0.75), stroke);
    }
  }
}
