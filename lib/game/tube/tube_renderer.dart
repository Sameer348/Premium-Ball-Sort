import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/cosmetics.dart';

/// Visual parameters of a tube skin.
class TubeStyle {
  const TubeStyle({
    required this.fill,
    required this.fillEdge,
    required this.border,
    required this.borderFaint,
    this.rim,
    this.glow,
    this.borderShader,
    this.facets = false,
    this.frosted = false,
  });

  final Color fill;
  final Color fillEdge;
  final Color border;
  final Color borderFaint;
  final Color? rim;

  /// Permanent soft glow (neon skins).
  final Color? glow;
  final List<Color>? borderShader;
  final bool facets;
  final bool frosted;

  static TubeStyle of(TubeSkin s, Color tint) => switch (s) {
        TubeSkin.classicGlass => TubeStyle(fill: tint.withValues(alpha: 0.03), fillEdge: tint.withValues(alpha: 0.11), border: tint.withValues(alpha: 0.42), borderFaint: tint.withValues(alpha: 0.12)),
        TubeSkin.crystal => TubeStyle(fill: const Color(0xFFBFE9FF).withValues(alpha: 0.05), fillEdge: const Color(0xFFE6F7FF).withValues(alpha: 0.16), border: const Color(0xFFE6F7FF).withValues(alpha: 0.6), borderFaint: const Color(0xFFBFE9FF).withValues(alpha: 0.18), facets: true),
        TubeSkin.neonGlass => TubeStyle(fill: AppColors.cyan.withValues(alpha: 0.03), fillEdge: AppColors.cyan.withValues(alpha: 0.1), border: AppColors.cyan.withValues(alpha: 0.85), borderFaint: AppColors.blue.withValues(alpha: 0.3), glow: AppColors.cyan.withValues(alpha: 0.35)),
        TubeSkin.gold => TubeStyle(fill: AppColors.gold.withValues(alpha: 0.03), fillEdge: AppColors.gold.withValues(alpha: 0.1), border: AppColors.gold, borderFaint: AppColors.amber.withValues(alpha: 0.3), rim: AppColors.gold, borderShader: const [Color(0xFFFFF1C1), AppColors.gold, Color(0xFFB8862B), AppColors.amber]),
        TubeSkin.aurora => TubeStyle(fill: AppColors.success.withValues(alpha: 0.03), fillEdge: AppColors.violet.withValues(alpha: 0.1), border: AppColors.success, borderFaint: AppColors.violet.withValues(alpha: 0.3), borderShader: const [AppColors.success, AppColors.cyan, AppColors.violet, AppColors.purple], glow: AppColors.violet.withValues(alpha: 0.18)),
        TubeSkin.darkGlass => TubeStyle(fill: const Color(0xFF000000).withValues(alpha: 0.32), fillEdge: tint.withValues(alpha: 0.06), border: tint.withValues(alpha: 0.28), borderFaint: tint.withValues(alpha: 0.08)),
        TubeSkin.frosted => TubeStyle(fill: tint.withValues(alpha: 0.1), fillEdge: tint.withValues(alpha: 0.2), border: tint.withValues(alpha: 0.5), borderFaint: tint.withValues(alpha: 0.2), frosted: true),
      };
}

/// Renders glass tubes as two baked layers: a *back* (shadow, body,
/// inner wall) drawn under the balls, and a *front* (reflections, rim)
/// drawn over them for a believable glass sandwich.
class TubeRenderer {
  TubeRenderer();

  ui.Image? _back;
  ui.Image? _front;
  Size _size = Size.zero;
  double _dpr = 1;
  TubeSkin? _skin;
  Color? _tint;

  /// Extra space baked around the tube for shadow and glow.
  static const double margin = 14;

  static Path shape(Rect r) {
    final top = r.width * 0.2;
    return Path()
      ..addRRect(RRect.fromRectAndCorners(
        r,
        topLeft: Radius.circular(top),
        topRight: Radius.circular(top),
        bottomLeft: Radius.circular(r.width / 2),
        bottomRight: Radius.circular(r.width / 2),
      ));
  }

  void configure({required Size size, required double dpr, required TubeSkin skin, required Color tint}) {
    if (size == _size && dpr == _dpr && skin == _skin && tint == _tint && _back != null) return;
    dispose();
    _size = size;
    _dpr = dpr;
    _skin = skin;
    _tint = tint;
    final style = TubeStyle.of(skin, tint);
    _back = _bake((c, r) => _paintBack(c, r, style));
    _front = _bake((c, r) => _paintFront(c, r, style));
  }

  ui.Image _bake(void Function(Canvas, Rect) painter) {
    final w = ((_size.width + margin * 2) * _dpr).ceil();
    final h = ((_size.height + margin * 2) * _dpr).ceil();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec)..scale(_dpr);
    painter(c, Rect.fromLTWH(margin, margin, _size.width, _size.height));
    final pic = rec.endRecording();
    final img = pic.toImageSync(w, h);
    pic.dispose();
    return img;
  }

  void _paintBack(Canvas c, Rect r, TubeStyle s) {
    // Ground shadow.
    c.drawOval(
      Rect.fromCenter(center: r.bottomCenter + const Offset(0, 3), width: r.width * 1.1, height: 10),
      Paint()
        ..color = const Color(0x80000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    final path = shape(r);
    if (s.glow != null) {
      c.drawPath(path, Paint()..color = s.glow!..style = PaintingStyle.stroke..strokeWidth = 6..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    }
    // Body: brighter edges, clearer centre — reads as a cylinder.
    c.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(r.centerLeft, r.centerRight, [s.fillEdge, s.fill, s.fill, s.fillEdge], [0, 0.3, 0.7, 1]),
    );
    if (s.frosted) {
      c.drawPath(path, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.02)]));
    }
    // Inner back wall shading at the bottom.
    c.save();
    c.clipPath(path);
    c.drawOval(
      Rect.fromCenter(center: r.bottomCenter - Offset(0, r.width * 0.3), width: r.width * 0.9, height: r.width * 0.7),
      Paint()
        ..shader = ui.Gradient.radial(r.bottomCenter - Offset(0, r.width * 0.3), r.width * 0.5, [Colors.white.withValues(alpha: 0.05), Colors.transparent]),
    );
    c.restore();
  }

  void _paintFront(Canvas c, Rect r, TubeStyle s) {
    final path = shape(r);
    // Outline.
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    if (s.borderShader != null) {
      border.shader = ui.Gradient.linear(r.topLeft, r.bottomRight, s.borderShader!, [0, 0.35, 0.7, 1]);
    } else {
      border.shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [s.border, s.borderFaint, s.border.withValues(alpha: s.border.a * 0.7)], [0, 0.6, 1]);
    }
    c.drawPath(path, border);

    c.save();
    c.clipPath(path);
    // Long left reflection strip.
    final strip = RRect.fromRectAndRadius(
      Rect.fromLTWH(r.left + r.width * 0.13, r.top + r.width * 0.25, r.width * 0.12, r.height - r.width * 0.75),
      Radius.circular(r.width * 0.06),
    );
    c.drawRRect(strip, Paint()..shader = ui.Gradient.linear(strip.outerRect.topCenter, strip.outerRect.bottomCenter, [Colors.white.withValues(alpha: 0.34), Colors.white.withValues(alpha: 0.04)]));
    // Thin right edge glint.
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(r.right - r.width * 0.16, r.top + r.width * 0.4, r.width * 0.045, r.height * 0.45), Radius.circular(r.width * 0.03)),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    // Bottom caustic.
    c.drawArc(
      Rect.fromLTWH(r.left + r.width * 0.15, r.bottom - r.width * 0.8, r.width * 0.7, r.width * 0.7),
      0.5,
      2.1,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.18),
    );
    if (s.facets) {
      final f = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1;
      for (var y = r.top + r.width * 0.6; y < r.bottom - r.width * 0.4; y += r.width * 0.9) {
        c.drawLine(Offset(r.left, y), Offset(r.right, y + r.width * 0.5), f);
      }
    }
    c.restore();

    // Rim / lip.
    final lip = RRect.fromRectAndRadius(Rect.fromLTWH(r.left - 2.5, r.top - 1.5, r.width + 5, 6), const Radius.circular(3));
    c.drawRRect(lip, Paint()..color = (s.rim ?? s.border).withValues(alpha: s.rim != null ? 0.85 : 0.35));
    c.drawRRect(lip.deflate(1.5), Paint()..color = Colors.white.withValues(alpha: 0.18));
  }

  /// Draws a baked layer for the tube body at [r] (logical coords).
  void drawBack(Canvas canvas, Rect r, {Paint? paint}) => _draw(canvas, _back, r, paint);
  void drawFront(Canvas canvas, Rect r, {Paint? paint}) => _draw(canvas, _front, r, paint);

  void _draw(Canvas canvas, ui.Image? img, Rect r, Paint? paint) {
    if (img == null) return;
    final dst = Rect.fromLTWH(r.left - margin, r.top - margin, r.width + margin * 2, r.height + margin * 2);
    canvas.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), dst, paint ?? (Paint()..filterQuality = FilterQuality.medium));
  }

  void dispose() {
    _back?.dispose();
    _front?.dispose();
    _back = null;
    _front = null;
  }
}
