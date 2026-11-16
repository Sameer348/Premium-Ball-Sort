import 'package:flutter/material.dart';

import '../../models/cosmetics.dart';
import '../../services/audio/audio_service.dart';
import '../../services/haptics/haptics_service.dart';
import '../../features/gameplay/game_controller.dart';
import '../animation/board_animator.dart';
import '../ball/ball_sprite_cache.dart';
import '../tube/tube_renderer.dart';
import 'board_layout.dart';
import 'board_painter.dart';

/// The interactive puzzle board: one CustomPaint + one gesture detector.
/// Layout is recomputed only when the size or tube count changes.
class BoardWidget extends StatefulWidget {
  const BoardWidget({
    super.key,
    required this.controller,
    required this.audio,
    required this.haptics,
    required this.ballSkin,
    required this.tubeSkin,
    required this.tubeTint,
    required this.accent,
    required this.reduceMotion,
    required this.colorSymbols,
    required this.lowGraphics,
  });

  final GameController controller;
  final AudioService audio;
  final HapticsService haptics;
  final BallSkin ballSkin;
  final TubeSkin tubeSkin;
  final Color tubeTint;
  final Color accent;
  final bool reduceMotion;
  final bool colorSymbols;
  final bool lowGraphics;

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> with SingleTickerProviderStateMixin {
  late final BoardAnimator _animator;
  final _balls = BallSpriteCache();
  final _tubes = TubeRenderer();
  BoardLayout? _layout;
  Size _lastSize = Size.zero;
  int _lastCount = -1;
  int _lastCapacity = -1;
  int? _activePointer;

  @override
  void initState() {
    super.initState();
    _animator = BoardAnimator(
      vsync: this,
      tubesOf: () => widget.controller.tubes,
      selectedOf: () => widget.controller.selected,
      audio: widget.audio,
      haptics: widget.haptics,
    );
    _applyOptions();
    widget.controller.fx = _animator;
    widget.controller.addListener(_onController);
  }

  void _applyOptions() {
    _animator.reduceMotion = widget.reduceMotion;
    _animator.particles.density = widget.lowGraphics ? 0.4 : 1;
  }

  @override
  void didUpdateWidget(covariant BoardWidget old) {
    super.didUpdateWidget(old);
    _applyOptions();
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
      widget.controller.fx = _animator;
    }
  }

  void _onController() {
    if (widget.controller.tubes.length != _lastCount) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    _animator.dispose();
    _balls.dispose();
    _tubes.dispose();
    super.dispose();
  }

  void _ensureLayout(Size size, double dpr) {
    final n = widget.controller.tubes.length;
    final cap = widget.controller.engine.capacity;
    if (size != _lastSize || n != _lastCount || cap != _lastCapacity || _layout == null) {
      final shortest = MediaQuery.sizeOf(context).shortestSide;
      _layout = BoardLayout.compute(size, n, cap, maxBall: shortest > 600 ? 86 : 62);
      _lastSize = size;
      _lastCount = n;
      _lastCapacity = cap;
      _animator.setLayout(_layout!);
    }
    final l = _layout!;
    _balls.configure(radius: l.radius, dpr: dpr, skin: widget.ballSkin, symbols: widget.colorSymbols);
    _tubes.configure(size: Size(l.tubeWidth, l.tubeHeight), dpr: dpr, skin: widget.tubeSkin, tint: widget.tubeTint);
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      _ensureLayout(size, dpr);
      // Raw pointer-down (no gesture-arena delay) for instant response;
      // only the first finger counts so multi-touch can't double-move.
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          if (_activePointer != null) return;
          _activePointer = e.pointer;
          final i = _layout?.hitTest(e.localPosition);
          if (i != null) widget.controller.tap(i);
        },
        onPointerUp: (e) {
          if (e.pointer == _activePointer) _activePointer = null;
        },
        onPointerCancel: (e) {
          if (e.pointer == _activePointer) _activePointer = null;
        },
        child: RepaintBoundary(
          child: CustomPaint(
            size: size,
            painter: BoardPainter(
              animator: _animator,
              balls: _balls,
              tubeRenderer: _tubes,
              tubes: () => widget.controller.tubes,
              selected: () => widget.controller.selected,
              accent: widget.accent,
            ),
          ),
        ),
      );
    });
  }
}
