import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/cosmetics.dart';
import 'ball_renderer.dart';

/// Bakes each (color, skin, size) ball once into a GPU image so the board
/// draws balls as cheap textured quads instead of re-running gradients and
/// blurs every frame.
class BallSpriteCache {
  BallSpriteCache();

  final Map<int, ui.Image> _images = {};
  double _radius = 0;
  double _dpr = 1;
  BallSkin _skin = BallSkin.classic;
  bool _symbols = false;

  /// Padding around the ball for its shadow, as a fraction of radius.
  static const double pad = 0.45;

  void configure({required double radius, required double dpr, required BallSkin skin, required bool symbols}) {
    if ((radius - _radius).abs() < 0.25 && dpr == _dpr && skin == _skin && symbols == _symbols && _images.isNotEmpty) return;
    clear();
    _radius = radius;
    _dpr = dpr;
    _skin = skin;
    _symbols = symbols;
  }

  ui.Image image(int color) => _images.putIfAbsent(color, () => _bake(color));

  ui.Image _bake(int color) {
    final r = _radius * _dpr;
    final size = (r * 2 * (1 + pad)).ceil();
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    BallRenderer.paint(canvas, Offset(size / 2, size / 2), r, BallPalette.of(color), _skin, glyph: _symbols ? color : -1, seed: color);
    final pic = rec.endRecording();
    final img = pic.toImageSync(size, size);
    pic.dispose();
    return img;
  }

  /// Draws ball [color] centred at [c]. [squash] > 0 flattens (landing).
  void draw(Canvas canvas, int color, Offset c, {double scale = 1, double squash = 0, double opacity = 1, Paint? paint}) {
    if (_radius <= 0) return;
    final img = image(color);
    final half = _radius * (1 + pad) * scale;
    final w = half * (1 + squash * 0.5);
    final h = half * (1 - squash * 0.5);
    final dst = Rect.fromLTRB(c.dx - w, c.dy - h + (half - h), c.dx + w, c.dy + h + (half - h));
    final p = paint ?? Paint();
    p
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromRGBO(255, 255, 255, opacity);
    canvas.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), dst, p);
  }

  void clear() {
    for (final i in _images.values) {
      i.dispose();
    }
    _images.clear();
  }

  void dispose() => clear();
}
