import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../game/ball/ball_renderer.dart';
import '../models/cosmetics.dart';

/// A single rendered ball for UI (logo, shop previews, map nodes).
class BallIcon extends StatelessWidget {
  const BallIcon({super.key, required this.size, this.color = 1, this.skin = BallSkin.classic, this.shadow = true});

  final double size;
  final int color;
  final BallSkin skin;
  final bool shadow;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(size: Size.square(size), painter: _BallIconPainter(color, skin, shadow)),
      );
}

class _BallIconPainter extends CustomPainter {
  _BallIconPainter(this.color, this.skin, this.shadow);
  final int color;
  final BallSkin skin;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 * (shadow ? 0.82 : 1);
    BallRenderer.paint(canvas, Offset(size.width / 2, size.height / 2 - (shadow ? r * 0.08 : 0)), r, BallPalette.of(color), skin, seed: color, shadow: shadow);
  }

  @override
  bool shouldRepaint(covariant _BallIconPainter old) => old.color != color || old.skin != skin;
}
