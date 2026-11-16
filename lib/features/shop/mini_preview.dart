import 'package:flutter/material.dart';

import '../../core/theme/game_themes.dart';
import '../../game/ball/ball_sprite_cache.dart';
import '../../game/tube/tube_renderer.dart';
import '../../models/cosmetics.dart';

/// Live miniature of tubes + balls using the real renderers, so shop
/// previews look exactly like the board.
class MiniPreview extends StatefulWidget {
  const MiniPreview({super.key, required this.ballSkin, required this.tubeSkin, required this.theme, this.showBackground = false});

  final BallSkin ballSkin;
  final TubeSkin tubeSkin;
  final GameThemeSpec theme;
  final bool showBackground;

  @override
  State<MiniPreview> createState() => _MiniPreviewState();
}

class _MiniPreviewState extends State<MiniPreview> {
  final _balls = BallSpriteCache();
  final _tubes = TubeRenderer();

  @override
  void dispose() {
    _balls.dispose();
    _tubes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(builder: (context, c) {
      final ball = (c.maxHeight / 4.2).clamp(8.0, 40.0).floorToDouble();
      final tw = ball * 1.22;
      final th = ball * (3 * 1.02 + 0.53);
      _balls.configure(radius: ball / 2, dpr: dpr, skin: widget.ballSkin, symbols: false);
      _tubes.configure(size: Size(tw, th), dpr: dpr, skin: widget.tubeSkin, tint: widget.theme.tubeTint);
      return RepaintBoundary(
        child: CustomPaint(
          size: Size(c.maxWidth, c.maxHeight),
          painter: _MiniPainter(_balls, _tubes, ball, tw, th, widget.theme, widget.showBackground, widget.ballSkin, widget.tubeSkin),
        ),
      );
    });
  }
}

class _MiniPainter extends CustomPainter {
  _MiniPainter(this.balls, this.tubes, this.ball, this.tw, this.th, this.theme, this.bg, this.bs, this.ts);
  final BallSpriteCache balls;
  final TubeRenderer tubes;
  final double ball, tw, th;
  final GameThemeSpec theme;
  final bool bg;
  final BallSkin bs;
  final TubeSkin ts;

  static const _content = [
    [0, 1, 1],
    [3, 3, 3],
    [4, 0, 6],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (bg) {
      final r = Offset.zero & size;
      canvas.drawRect(r, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [theme.top, theme.bottom]).createShader(r));
      canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), size.width * 0.6,
          Paint()..shader = RadialGradient(colors: [theme.glowA.withValues(alpha: 0.35), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(size.width * 0.2, size.height * 0.2), radius: size.width * 0.6)));
      canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.9), size.width * 0.6,
          Paint()..shader = RadialGradient(colors: [theme.glowB.withValues(alpha: 0.25), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(size.width * 0.9, size.height * 0.9), radius: size.width * 0.6)));
    }
    const n = 3;
    final gap = ball * 0.5;
    final total = n * tw + (n - 1) * gap;
    final x0 = (size.width - total) / 2;
    final top = (size.height - th) / 2;
    for (var i = 0; i < n; i++) {
      final r = Rect.fromLTWH(x0 + i * (tw + gap), top, tw, th);
      tubes.drawBack(canvas, r);
      final col = _content[i];
      for (var k = 0; k < col.length; k++) {
        balls.draw(canvas, col[k], Offset(r.center.dx, r.bottom - ball * 0.11 - ball / 2 - k * ball * 1.02));
      }
      tubes.drawFront(canvas, r);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPainter old) => old.bs != bs || old.ts != ts || old.theme != theme || old.ball != ball;
}
