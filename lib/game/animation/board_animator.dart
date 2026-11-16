import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';
import '../../services/audio/audio_service.dart';
import '../../services/haptics/haptics_service.dart';
import '../board/board_fx.dart';
import '../board/board_layout.dart';
import '../effects/particle_system.dart';
import '../engine/move.dart';
import '../engine/tube_state.dart';

/// One ball travelling between tubes.
class BallFlight {
  BallFlight({required this.color, required this.from, required this.to, required this.start, required this.duration, required this.completes, required this.straight});

  final int color;
  final int from;
  final int to;
  final Offset start;
  final double duration;
  final bool completes;
  final bool straight;
  double t = 0;
  Offset pos = Offset.zero;
}

/// Damped spring value (cheap, allocation-free).
class _Spring {
  double x = 0;
  double v = 0;
  double target = 0;

  bool step(double dt, {double k = 320, double damping = 0.72}) {
    final c = 2 * math.sqrt(k) * damping;
    v += (k * (target - x) - c * v) * dt;
    x += v * dt;
    if ((target - x).abs() < 0.0008 && v.abs() < 0.002) {
      x = target;
      v = 0;
      return false;
    }
    return true;
  }
}

/// Drives every board animation from a single [Ticker] that only runs
/// while something is moving, then repaints the board via notifyListeners.
class BoardAnimator extends ChangeNotifier implements BoardFx {
  BoardAnimator({
    required TickerProvider vsync,
    required this.tubesOf,
    required this.selectedOf,
    required this.audio,
    required this.haptics,
  }) {
    _ticker = vsync.createTicker(_tick);
  }

  final List<TubeState> Function() tubesOf;
  final int? Function() selectedOf;
  final AudioService audio;
  final HapticsService haptics;
  late final Ticker _ticker;

  bool reduceMotion = false;
  final particles = ParticleSystem();

  BoardLayout? _layout;
  List<Rect> _fromRects = const [];
  double _layoutBlend = 1;

  final List<_Spring> _lift = [];
  final List<_Spring> _dip = [];
  final List<_Spring> _appear = [];
  final List<double> _shake = [];
  final List<double> _glow = [];
  final List<double> _squash = [];
  final List<BallFlight> flights = [];

  Move? hintMove;
  double time = 0;
  double _celebration = 0; // 1 → 0 brightness pulse
  double _celebrateWave = -1;
  Duration _last = Duration.zero;
  Completer<void>? _settled;

  BoardLayout? get layout => _layout;
  double get celebration => _celebration;
  double get celebrateWave => _celebrateWave;

  // ------------------------------------------------------------ layout

  void setLayout(BoardLayout l) {
    final old = _layout;
    if (old != null && old.size == l.size && old.tubeRects.length == l.tubeRects.length) {
      if (_rectsEqual(old.tubeRects, l.tubeRects)) return;
    }
    if (old != null && old.size == l.size && old.tubeRects.length != l.tubeRects.length && !reduceMotion) {
      _fromRects = [for (var i = 0; i < l.tubeRects.length; i++) i < old.tubeRects.length ? rectFor(i) : l.tubeRects[i]];
      _layoutBlend = 0;
      _wake();
    } else {
      _layoutBlend = 1;
    }
    _layout = l;
    _ensure(l.tubeRects.length);
  }

  static bool _rectsEqual(List<Rect> a, List<Rect> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _ensure(int n) {
    while (_lift.length < n) {
      _lift.add(_Spring());
      _dip.add(_Spring());
      _appear.add(_Spring()
        ..x = 1
        ..target = 1);
      _shake.add(0);
      _glow.add(0);
      _squash.add(0);
    }
  }

  /// Animated rect of tube [i] (handles layout transitions, select rise,
  /// landing dip and invalid shake).
  Rect rectFor(int i) {
    final l = _layout!;
    var r = l.tubeRects[i];
    if (_layoutBlend < 1 && i < _fromRects.length) {
      r = Rect.lerp(_fromRects[i], r, Curves.easeOutCubic.transform(_layoutBlend))!;
    }
    final dy = -_lift[i].x * l.ball * 0.08 + _dip[i].x * l.ball * 0.06;
    final dx = _shake[i] > 0 ? math.sin((1 - _shake[i]) * math.pi * 7) * l.ball * 0.11 * _shake[i] : 0.0;
    return r.shift(Offset(dx, dy));
  }

  double liftOf(int i) => _lift[i].x;
  double appearOf(int i) => _appear[i].x;
  double shakeOf(int i) => _shake[i];
  double glowOf(int i) => _glow[i];
  double squashOf(int i) => _squash[i];

  Offset slotIn(Rect r, int slot) {
    final l = _layout!;
    return Offset(r.center.dx, r.bottom - l.ball * 0.11 - l.radius - slot * l.ball * 1.02);
  }

  Offset liftedIn(Rect r) => Offset(r.center.dx, r.top - _layout!.ball * 0.58);

  /// Balls currently flying into tube [i] (not yet drawn inside it).
  int inbound(int i) {
    var n = 0;
    for (final f in flights) {
      if (f.to == i) n++;
    }
    return n;
  }

  // -------------------------------------------------------------- fx api

  @override
  void select(int tube) {
    if (_layout == null) return;
    _ensure(tube + 1);
    for (var i = 0; i < _lift.length; i++) {
      _lift[i].target = i == tube ? 1 : 0;
    }
    hintMove = null;
    audio.play(Sfx.pickup, volume: 0.55);
    haptics.select();
    _wake();
  }

  @override
  void deselect(int tube) {
    for (final s in _lift) {
      s.target = 0;
    }
    audio.play(Sfx.select, volume: 0.35);
    _wake();
  }

  @override
  void move(int from, int to, int color, {required bool completes, bool undo = false}) {
    final l = _layout;
    if (l == null) return;
    _ensure(math.max(from, to) + 1);
    // Starting point: where the ball is drawn right now.
    Offset start;
    final pending = flights.lastWhere((f) => f.to == from, orElse: () => _noFlight);
    if (!identical(pending, _noFlight)) {
      start = pending.pos;
      flights.remove(pending);
    } else {
      final r = rectFor(from);
      final slotIdx = tubesOf()[from].length; // already popped in engine
      start = Offset.lerp(slotIn(r, slotIdx), liftedIn(r), _lift[from].x)!;
    }
    for (final s in _lift) {
      s.target = 0;
    }
    _lift[from].x = 0;
    final end = slotIn(rectFor(to), tubesOf()[to].length - 1);
    final dist = (end - start).distance;
    final dur = reduceMotion ? 0.2 : (0.3 + dist * 0.00055).clamp(0.32, 0.58);
    final f = BallFlight(color: color, from: from, to: to, start: start, duration: dur, completes: completes, straight: reduceMotion)..pos = start;
    flights.add(f);
    _dip[from].v -= reduceMotion ? 0 : 1.6;
    hintMove = null;
    audio.play(undo ? Sfx.select : Sfx.move, volume: 0.4);
    _wake();
  }

  static final _noFlight = BallFlight(color: 0, from: -1, to: -1, start: Offset.zero, duration: 1, completes: false, straight: true);

  @override
  void invalid(int tube) {
    if (tube >= _shake.length) return;
    _shake[tube] = 1;
    audio.play(Sfx.invalid, volume: 0.45);
    haptics.invalid();
    _wake();
  }

  @override
  void hint(Move? move) {
    hintMove = move;
    if (move != null) {
      audio.play(Sfx.booster, volume: 0.5);
      for (final s in _lift) {
        s.target = 0;
      }
    }
    _wake();
  }

  @override
  void tubeAdded() {
    final n = tubesOf().length;
    _ensure(n);
    _appear[n - 1]
      ..x = 0
      ..target = 1;
    audio.play(Sfx.booster, volume: 0.6);
    haptics.tubeComplete();
    _wake();
  }

  @override
  void reset() {
    flights.clear();
    particles.clear();
    hintMove = null;
    for (var i = 0; i < _lift.length; i++) {
      _lift[i]
        ..x = 0
        ..v = 0
        ..target = 0;
      _dip[i]
        ..x = 0
        ..v = 0;
      _shake[i] = 0;
      _glow[i] = 0;
      _squash[i] = 0;
    }
    final tubes = tubesOf();
    for (var i = 0; i < tubes.length && i < _glow.length; i++) {
      if (tubes[i].isComplete) _glow[i] = 0.35;
    }
    _celebration = 0;
    _celebrateWave = -1;
    _completeSettled();
    notifyListeners();
  }

  @override
  void celebrate() {
    _celebration = 1;
    _celebrateWave = 0;
    final l = _layout;
    if (l != null) {
      final tubes = tubesOf();
      for (var i = 0; i < tubes.length; i++) {
        if (tubes[i].isEmpty) continue;
        final r = rectFor(i);
        particles.burst(r.topCenter, BallPalette.of(tubes[i].balls.first), count: 14, speed: 220, size: 2.6, life: 0.9, gravity: 320, sparkle: true, spreadUp: 160);
      }
    }
    _wake();
  }

  @override
  Future<void> settled() {
    if (flights.isEmpty) return Future.value();
    return (_settled ??= Completer<void>()).future;
  }

  void _completeSettled() {
    final c = _settled;
    _settled = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  // ----------------------------------------------------------- ticking

  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
    notifyListeners();
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : math.min(1 / 30, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    time += dt;
    var active = false;
    final l = _layout;
    if (l == null) return;

    if (_layoutBlend < 1) {
      _layoutBlend = math.min(1, _layoutBlend + dt / 0.38);
      active = true;
    }
    for (var i = 0; i < _lift.length; i++) {
      if (_lift[i].step(dt, k: 380, damping: 0.62)) active = true;
      if (_dip[i].step(dt, k: 520, damping: 0.42)) active = true;
      if (_appear[i].step(dt, k: 200, damping: 0.7)) active = true;
      if (_shake[i] > 0) {
        _shake[i] = math.max(0, _shake[i] - dt / 0.34);
        active = true;
      }
      if (_squash[i] > 0) {
        _squash[i] = math.max(0, _squash[i] - dt / 0.22);
        active = true;
      }
      if (_glow[i] > 0.35) {
        _glow[i] = math.max(0.35, _glow[i] - dt / 1.1);
        active = true;
      }
    }

    for (var k = flights.length - 1; k >= 0; k--) {
      final f = flights[k];
      f.t = math.min(1, f.t + dt / f.duration);
      f.pos = _flightPos(f);
      active = true;
      if (f.t >= 1) {
        flights.removeAt(k);
        _land(f);
      }
    }
    if (flights.isEmpty) _completeSettled();

    if (_celebration > 0) {
      _celebration = math.max(0, _celebration - dt / 1.4);
      active = true;
    }
    if (_celebrateWave >= 0) {
      _celebrateWave += dt / 0.9;
      if (_celebrateWave > 1.6) _celebrateWave = -1;
      active = true;
    }
    if (particles.isActive) {
      particles.update(dt);
      active = true;
    }
    if (hintMove != null) active = true;

    notifyListeners();
    if (!active) _ticker.stop();
  }

  Offset _flightPos(BallFlight f) {
    final toRect = rectFor(f.to);
    final end = slotIn(toRect, _slotFor(f));
    if (f.straight) return Offset.lerp(f.start, end, Curves.easeInOut.transform(f.t))!;
    final fromRect = rectFor(f.from);
    final a = liftedIn(fromRect);
    final b = liftedIn(toRect);
    final riseNeeded = (f.start - a).distance > 2;
    final p1 = riseNeeded ? 0.18 : 0.0;
    const p2 = 0.74;
    final t = f.t;
    if (t < p1) {
      return Offset.lerp(f.start, a, Curves.easeOutCubic.transform(t / p1))!;
    }
    if (t < p2) {
      final u = Curves.easeInOutSine.transform((t - p1) / (p2 - p1));
      final arc = math.max(_layout!.ball * 0.6, (b - a).distance * 0.22);
      final ctrl = Offset((a.dx + b.dx) / 2, math.min(a.dy, b.dy) - arc);
      final mt = 1 - u;
      return a * (mt * mt) + ctrl * (2 * mt * u) + b * (u * u);
    }
    final u = (t - p2) / (1 - p2);
    return Offset.lerp(b, end, u * u)!;
  }

  /// Slot index the flight lands in = its rank among visible + inbound.
  int _slotFor(BallFlight f) {
    final engineLen = tubesOf()[f.to].length;
    var after = 0;
    var seen = false;
    for (final o in flights) {
      if (o.to != f.to) continue;
      if (identical(o, f)) {
        seen = true;
        continue;
      }
      if (seen) after++;
    }
    return math.max(0, engineLen - 1 - after);
  }

  void _land(BallFlight f) {
    final l = _layout!;
    _squash[f.to] = 1;
    _dip[f.to].v += reduceMotion ? 0 : 2.4;
    final r = rectFor(f.to);
    final at = slotIn(r, math.max(0, tubesOf()[f.to].length - 1 - inbound(f.to))) + Offset(0, l.radius * 0.8);
    particles.burst(at, BallPalette.of(f.color), count: 5, speed: 70, size: 1.6, life: 0.35, gravity: 120);
    audio.drop();
    haptics.move();
    if (f.completes) {
      _glow[f.to] = 1;
      particles.burst(r.topCenter + Offset(0, r.height * 0.2), BallPalette.of(f.color), count: 18, speed: 150, size: 2.6, life: 0.8, gravity: 90, sparkle: true, spreadUp: 60);
      audio.play(Sfx.tubeComplete, volume: 0.7);
      haptics.tubeComplete();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _completeSettled();
    super.dispose();
  }
}
